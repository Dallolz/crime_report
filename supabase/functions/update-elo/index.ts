import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

interface MatchParticipant {
  player_id: string
  team: string | null
  result: 'win' | 'loss' | 'draw'
}

interface PlayerSport {
  player_id: string
  sport_id: number
  elo_rating: number
  matches_played: number
  wins: number
  xp: number
  skill_level: string
}

serve(async (req) => {
  try {
    const { match_id } = await req.json()

    if (!match_id) {
      return new Response(JSON.stringify({ error: 'match_id is required' }), {
        status: 400,
        headers: { 'Content-Type': 'application/json' },
      })
    }

    const supabase = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    )

    // Fetch match with participants
    const { data: match, error: matchError } = await supabase
      .from('matches')
      .select(`
        id,
        sport_id,
        status,
        participants:match_participants(player_id, team, result)
      `)
      .eq('id', match_id)
      .single()

    if (matchError || !match) {
      return new Response(JSON.stringify({ error: 'Match not found' }), {
        status: 404,
        headers: { 'Content-Type': 'application/json' },
      })
    }

    if (match.status !== 'completed') {
      return new Response(JSON.stringify({ error: 'Match is not completed' }), {
        status: 400,
        headers: { 'Content-Type': 'application/json' },
      })
    }

    const participants = match.participants as MatchParticipant[]
    if (!participants || participants.length < 2) {
      return new Response(JSON.stringify({ error: 'Not enough participants' }), {
        status: 400,
        headers: { 'Content-Type': 'application/json' },
      })
    }

    // Fetch current ELO and stats for all participants
    const playerIds = participants.map((p) => p.player_id)
    const { data: playerSports, error: psError } = await supabase
      .from('player_sports')
      .select('player_id, sport_id, elo_rating, matches_played, wins, xp, skill_level')
      .eq('sport_id', match.sport_id)
      .in_('player_id', playerIds)

    if (psError) {
      return new Response(JSON.stringify({ error: psError.message }), {
        status: 500,
        headers: { 'Content-Type': 'application/json' },
      })
    }

    // Build a lookup map
    const playerMap = new Map<string, PlayerSport>()
    for (const ps of (playerSports || [])) {
      playerMap.set(ps.player_id, ps as PlayerSport)
    }

    // Ensure all participants have a player_sport entry (default if missing)
    for (const p of participants) {
      if (!playerMap.has(p.player_id)) {
        playerMap.set(p.player_id, {
          player_id: p.player_id,
          sport_id: match.sport_id,
          elo_rating: 1000,
          matches_played: 0,
          wins: 0,
          xp: 0,
          skill_level: 'beginner',
        })
      }
    }

    // Determine if team-based or individual
    const hasTeams = participants.some((p) => p.team !== null)
    const updates: { player_id: string; new_elo: number; new_xp: number; won: boolean }[] = []

    if (hasTeams) {
      // Team-based: compute average ELO per team, then update each player
      const teams = new Map<string, MatchParticipant[]>()
      for (const p of participants) {
        const team = p.team || 'unknown'
        if (!teams.has(team)) teams.set(team, [])
        teams.get(team)!.push(p)
      }

      const teamEntries = Array.from(teams.entries())
      if (teamEntries.length === 2) {
        const [teamAKey, teamAPlayers] = teamEntries[0]
        const [_teamBKey, teamBPlayers] = teamEntries[1]

        const avgEloA = average(teamAPlayers.map((p) => playerMap.get(p.player_id)!.elo_rating))
        const avgEloB = average(teamBPlayers.map((p) => playerMap.get(p.player_id)!.elo_rating))

        for (const p of participants) {
          const ps = playerMap.get(p.player_id)!
          const k = kFactor(ps.matches_played)
          const isTeamA = p.team === teamAKey
          const opponentAvgElo = isTeamA ? avgEloB : avgEloA
          const score = resultToScore(p.result)

          const expected = expectedScore(ps.elo_rating, opponentAvgElo)
          const newElo = Math.round(ps.elo_rating + k * (score - expected))
          const xpGain = computeXp(p.result)

          updates.push({
            player_id: p.player_id,
            new_elo: Math.max(100, newElo),
            new_xp: ps.xp + xpGain,
            won: p.result === 'win',
          })
        }
      }
    } else {
      // Individual: each player compared against the average of opponents
      for (const p of participants) {
        const ps = playerMap.get(p.player_id)!
        const opponents = participants.filter((o) => o.player_id !== p.player_id)
        const avgOpponentElo = average(
          opponents.map((o) => playerMap.get(o.player_id)!.elo_rating)
        )

        const k = kFactor(ps.matches_played)
        const score = resultToScore(p.result)
        const expected = expectedScore(ps.elo_rating, avgOpponentElo)
        const newElo = Math.round(ps.elo_rating + k * (score - expected))
        const xpGain = computeXp(p.result)

        updates.push({
          player_id: p.player_id,
          new_elo: Math.max(100, newElo),
          new_xp: ps.xp + xpGain,
          won: p.result === 'win',
        })
      }
    }

    // Apply updates to the database
    const results = []
    for (const u of updates) {
      const ps = playerMap.get(u.player_id)!
      const newMatchesPlayed = ps.matches_played + 1
      const newWins = u.won ? ps.wins + 1 : ps.wins
      const newSkill = determineSkillLevel(u.new_elo)

      const { error: updateError } = await supabase
        .from('player_sports')
        .upsert({
          player_id: u.player_id,
          sport_id: match.sport_id,
          elo_rating: u.new_elo,
          matches_played: newMatchesPlayed,
          wins: newWins,
          xp: u.new_xp,
          skill_level: newSkill,
        }, { onConflict: 'player_id,sport_id' })

      results.push({
        player_id: u.player_id,
        old_elo: ps.elo_rating,
        new_elo: u.new_elo,
        elo_change: u.new_elo - ps.elo_rating,
        xp_gained: u.new_xp - ps.xp,
        new_skill_level: newSkill,
        error: updateError?.message || null,
      })
    }

    // Mark match as processed
    await supabase
      .from('matches')
      .update({ elo_processed: true })
      .eq('id', match_id)

    return new Response(JSON.stringify({ success: true, updates: results }), {
      headers: { 'Content-Type': 'application/json' },
    })
  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' },
    })
  }
})

// ----- Helper functions -----

function kFactor(matchesPlayed: number): number {
  // K=32 for beginners (<100 matches), K=16 for experienced
  return matchesPlayed < 100 ? 32 : 16
}

function expectedScore(ratingA: number, ratingB: number): number {
  return 1 / (1 + Math.pow(10, (ratingB - ratingA) / 400))
}

function resultToScore(result: string): number {
  switch (result) {
    case 'win':
      return 1.0
    case 'draw':
      return 0.5
    case 'loss':
      return 0.0
    default:
      return 0.5
  }
}

function computeXp(result: string): number {
  switch (result) {
    case 'win':
      return 100
    case 'draw':
      return 50
    case 'loss':
      return 25
    default:
      return 25
  }
}

function determineSkillLevel(elo: number): string {
  if (elo >= 2000) return 'expert'
  if (elo >= 1500) return 'advanced'
  if (elo >= 1200) return 'intermediate'
  return 'beginner'
}

function average(values: number[]): number {
  if (values.length === 0) return 1000
  return values.reduce((sum, v) => sum + v, 0) / values.length
}

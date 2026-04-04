import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

serve(async (req) => {
  try {
    const { sport_id, player_id, latitude, longitude, radius_km = 50 } = await req.json()

    const supabase = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    )

    // Get player's sport info
    const { data: playerSport } = await supabase
      .from('player_sports')
      .select('elo_rating, skill_level, reputation_score')
      .eq('player_id', player_id)
      .eq('sport_id', sport_id)
      .single()

    const playerElo = playerSport?.elo_rating || 1000
    const playerReputation = playerSport?.reputation_score || 5.0

    // Get open matches for sport
    const { data: matches } = await supabase
      .from('matches')
      .select(`
        *,
        sport:sports(*),
        creator:profiles!creator_id(*),
        participants:match_participants(*, player:profiles!player_id(*))
      `)
      .eq('sport_id', sport_id)
      .eq('status', 'open')

    if (!matches || matches.length === 0) {
      return new Response(JSON.stringify({ matches: [], message: 'No matches found' }), {
        headers: { 'Content-Type': 'application/json' },
      })
    }

    // Score each match
    const scoredMatches = matches.map((match: any) => {
      // Distance score (0-1, 1 = close)
      let distanceScore = 0.5 // default if no location
      if (latitude && longitude && match.location) {
        // Simple distance calculation (Haversine approximation)
        const matchCoords = parsePoint(match.location)
        if (matchCoords) {
          const dist = haversine(latitude, longitude, matchCoords.lat, matchCoords.lng)
          distanceScore = dist < 5 ? 1.0 : Math.max(0, 1 - (dist / radius_km))
        }
      }

      // ELO compatibility score (0-1)
      const creatorElo = match.creator?.elo_rating || 1000
      const eloDiff = Math.abs(playerElo - creatorElo)
      const eloScore = eloDiff < 100 ? 1.0 : Math.max(0, 1 - (eloDiff - 100) / 400)

      // Reputation score (0-1)
      const reputationScore = (playerReputation || 5) / 5

      // Fill rate (prefer almost full matches)
      const participants = match.participants?.length || 0
      const maxPlayers = match.max_players || 10
      const fillScore = participants / maxPlayers

      // Weighted score
      const score = (0.4 * distanceScore) + (0.3 * eloScore) + (0.2 * reputationScore) + (0.1 * fillScore)

      return { ...match, _score: score }
    })

    // Sort by score descending
    scoredMatches.sort((a: any, b: any) => b._score - a._score)

    return new Response(JSON.stringify({ matches: scoredMatches.slice(0, 10) }), {
      headers: { 'Content-Type': 'application/json' },
    })
  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 400,
      headers: { 'Content-Type': 'application/json' },
    })
  }
})

function parsePoint(location: string): { lat: number; lng: number } | null {
  // Parse PostGIS POINT format
  const match = location.match(/POINT\(([^ ]+) ([^ ]+)\)/)
  if (match) {
    return { lng: parseFloat(match[1]), lat: parseFloat(match[2]) }
  }
  return null
}

function haversine(lat1: number, lon1: number, lat2: number, lon2: number): number {
  const R = 6371 // km
  const dLat = (lat2 - lat1) * Math.PI / 180
  const dLon = (lon2 - lon1) * Math.PI / 180
  const a = Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) *
    Math.sin(dLon / 2) * Math.sin(dLon / 2)
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a))
  return R * c
}

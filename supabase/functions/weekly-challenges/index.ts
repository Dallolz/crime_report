import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

/**
 * Weekly Challenges Cron Function
 *
 * Designed to run on a weekly schedule (e.g., every Monday at 00:00 UTC).
 * Creates a set of fresh challenges for the coming week, deactivates
 * expired ones, and awards XP to players who completed the previous batch.
 *
 * Cron schedule (in supabase config): 0 0 * * 1
 */

interface ChallengeTemplate {
  title: string
  description: string
  sport_name: string | null
  goal: number
  xp_reward: number
  type: 'matches_played' | 'wins' | 'sport_try' | 'social' | 'streak'
}

const GENERIC_TEMPLATES: ChallengeTemplate[] = [
  {
    title: 'Joueur r\u00e9gulier',
    description: 'Joue 5 matchs cette semaine, peu importe le sport.',
    sport_name: null,
    goal: 5,
    xp_reward: 250,
    type: 'matches_played',
  },
  {
    title: 'Machine \u00e0 victoires',
    description: 'Remporte 3 matchs cette semaine.',
    sport_name: null,
    goal: 3,
    xp_reward: 300,
    type: 'wins',
  },
  {
    title: 'Explorateur sportif',
    description: 'Essaie un sport auquel tu n\'as jamais jou\u00e9.',
    sport_name: null,
    goal: 1,
    xp_reward: 200,
    type: 'sport_try',
  },
  {
    title: 'Esprit d\'\u00e9quipe',
    description: 'Participe \u00e0 3 matchs en \u00e9quipe cette semaine.',
    sport_name: null,
    goal: 3,
    xp_reward: 200,
    type: 'social',
  },
  {
    title: 'S\u00e9rie de feu',
    description: 'Encha\u00eene 3 victoires cons\u00e9cutives.',
    sport_name: null,
    goal: 3,
    xp_reward: 400,
    type: 'streak',
  },
]

const SPORT_TEMPLATES: ((sportName: string) => ChallengeTemplate)[] = [
  (sport) => ({
    title: `Roi du ${sport}`,
    description: `Gagne 3 matchs de ${sport} cette semaine.`,
    sport_name: sport,
    goal: 3,
    xp_reward: 350,
    type: 'wins',
  }),
  (sport) => ({
    title: `Fan de ${sport}`,
    description: `Joue 5 matchs de ${sport} cette semaine.`,
    sport_name: sport,
    goal: 5,
    xp_reward: 250,
    type: 'matches_played',
  }),
  (sport) => ({
    title: `D\u00e9couvre le ${sport}`,
    description: `Participe \u00e0 ton premier match de ${sport}.`,
    sport_name: sport,
    goal: 1,
    xp_reward: 150,
    type: 'sport_try',
  }),
]

serve(async (_req) => {
  try {
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    )

    const now = new Date()
    const startsAt = new Date(now)
    startsAt.setUTCHours(0, 0, 0, 0)

    const endsAt = new Date(startsAt)
    endsAt.setDate(endsAt.getDate() + 7)

    // ---- Step 1: Deactivate expired challenges ----
    const { error: deactivateError } = await supabase
      .from('challenges')
      .update({ is_active: false })
      .lt('ends_at', now.toISOString())
      .eq('is_active', true)

    if (deactivateError) {
      console.error('Failed to deactivate old challenges:', deactivateError.message)
    }

    // ---- Step 2: Award XP for completed challenges that haven't been rewarded yet ----
    const { data: completedUnrewarded, error: fetchError } = await supabase
      .from('user_challenges')
      .select('id, user_id, challenge:challenges(sport_id, xp_reward)')
      .eq('completed', true)
      .eq('rewarded', false)

    if (fetchError) {
      console.error('Failed to fetch completed challenges:', fetchError.message)
    }

    if (completedUnrewarded && completedUnrewarded.length > 0) {
      for (const uc of completedUnrewarded) {
        const challenge = uc.challenge as any
        const xpReward = challenge?.xp_reward || 0
        const sportId = challenge?.sport_id

        if (xpReward > 0) {
          if (sportId) {
            // Add XP to specific sport
            const { data: existing } = await supabase
              .from('player_sports')
              .select('xp')
              .eq('player_id', uc.user_id)
              .eq('sport_id', sportId)
              .single()

            if (existing) {
              await supabase
                .from('player_sports')
                .update({ xp: (existing.xp || 0) + xpReward })
                .eq('player_id', uc.user_id)
                .eq('sport_id', sportId)
            }
          }

          // Add XP to profile-level total
          const { data: profile } = await supabase
            .from('profiles')
            .select('total_xp')
            .eq('id', uc.user_id)
            .single()

          if (profile) {
            await supabase
              .from('profiles')
              .update({ total_xp: (profile.total_xp || 0) + xpReward })
              .eq('id', uc.user_id)
          }
        }

        // Mark as rewarded
        await supabase
          .from('user_challenges')
          .update({ rewarded: true })
          .eq('id', uc.id)
      }
    }

    // ---- Step 3: Fetch available sports for sport-specific challenges ----
    const { data: sports } = await supabase
      .from('sports')
      .select('id, name, display_name')

    const sportNames: string[] = (sports || []).map(
      (s: any) => s.display_name || s.name
    )

    // ---- Step 4: Pick challenges for this week ----
    const challengesToCreate: Omit<ChallengeTemplate, 'type'> & {
      starts_at: string
      ends_at: string
      is_active: boolean
      type: string
      sport_id?: number
    }[] = []

    // Always include 2-3 generic challenges (randomly picked)
    const shuffledGeneric = shuffle([...GENERIC_TEMPLATES])
    const genericCount = randomInt(2, 3)
    for (let i = 0; i < Math.min(genericCount, shuffledGeneric.length); i++) {
      const t = shuffledGeneric[i]
      challengesToCreate.push({
        title: t.title,
        description: t.description,
        sport_name: t.sport_name,
        goal: t.goal,
        xp_reward: t.xp_reward,
        type: t.type,
        starts_at: startsAt.toISOString(),
        ends_at: endsAt.toISOString(),
        is_active: true,
      })
    }

    // Add 1-2 sport-specific challenges if sports exist
    if (sportNames.length > 0 && sports) {
      const sportCount = randomInt(1, Math.min(2, sportNames.length))
      const shuffledSports = shuffle([...sports])
      const shuffledTemplates = shuffle([...SPORT_TEMPLATES])

      for (let i = 0; i < sportCount; i++) {
        const sport = shuffledSports[i] as any
        const templateFn = shuffledTemplates[i % shuffledTemplates.length]
        const t = templateFn(sport.display_name || sport.name)
        challengesToCreate.push({
          title: t.title,
          description: t.description,
          sport_name: t.sport_name,
          goal: t.goal,
          xp_reward: t.xp_reward,
          type: t.type,
          sport_id: sport.id,
          starts_at: startsAt.toISOString(),
          ends_at: endsAt.toISOString(),
          is_active: true,
        })
      }
    }

    // ---- Step 5: Insert new challenges ----
    const { data: created, error: insertError } = await supabase
      .from('challenges')
      .insert(challengesToCreate)
      .select()

    if (insertError) {
      return new Response(
        JSON.stringify({ error: `Failed to create challenges: ${insertError.message}` }),
        { status: 500, headers: { 'Content-Type': 'application/json' } }
      )
    }

    return new Response(
      JSON.stringify({
        success: true,
        deactivated_expired: true,
        rewarded_completed: completedUnrewarded?.length || 0,
        challenges_created: created?.length || 0,
        challenges: created,
      }),
      { headers: { 'Content-Type': 'application/json' } }
    )
  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500, headers: { 'Content-Type': 'application/json' } }
    )
  }
})

// ----- Utility functions -----

function shuffle<T>(array: T[]): T[] {
  for (let i = array.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1))
    ;[array[i], array[j]] = [array[j], array[i]]
  }
  return array
}

function randomInt(min: number, max: number): number {
  return Math.floor(Math.random() * (max - min + 1)) + min
}

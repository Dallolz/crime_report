import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

interface NotificationPayload {
  user_id: string
  title: string
  body: string
  data?: Record<string, string>
}

serve(async (req) => {
  try {
    const payload: NotificationPayload = await req.json()
    const { user_id, title, body, data } = payload

    if (!user_id || !title || !body) {
      return new Response(
        JSON.stringify({ error: 'user_id, title, and body are required' }),
        { status: 400, headers: { 'Content-Type': 'application/json' } }
      )
    }

    const supabase = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    )

    // Fetch the user's FCM token(s) from the database
    const { data: tokens, error: tokenError } = await supabase
      .from('user_fcm_tokens')
      .select('fcm_token')
      .eq('user_id', user_id)

    if (tokenError) {
      return new Response(
        JSON.stringify({ error: `Failed to fetch tokens: ${tokenError.message}` }),
        { status: 500, headers: { 'Content-Type': 'application/json' } }
      )
    }

    if (!tokens || tokens.length === 0) {
      // Persist the notification in-app even if no push token exists
      await supabase.from('notifications').insert({
        user_id,
        title,
        body,
        data: data || {},
        read: false,
      })

      return new Response(
        JSON.stringify({
          success: true,
          push_sent: false,
          message: 'No FCM token found; notification saved in-app only',
        }),
        { headers: { 'Content-Type': 'application/json' } }
      )
    }

    // Build FCM v1 payload
    const fcmServiceAccountKey = Deno.env.get('FCM_SERVICE_ACCOUNT_KEY')
    const fcmProjectId = Deno.env.get('FCM_PROJECT_ID')

    if (!fcmServiceAccountKey || !fcmProjectId) {
      // Store in-app notification when FCM is not configured
      await supabase.from('notifications').insert({
        user_id,
        title,
        body,
        data: data || {},
        read: false,
      })

      return new Response(
        JSON.stringify({
          success: true,
          push_sent: false,
          message: 'FCM not configured; notification saved in-app only',
        }),
        { headers: { 'Content-Type': 'application/json' } }
      )
    }

    // Send push notification via FCM HTTP v1 API
    const fcmResults = []
    for (const { fcm_token } of tokens) {
      const fcmPayload = {
        message: {
          token: fcm_token,
          notification: { title, body },
          data: data || {},
          android: {
            priority: 'high' as const,
            notification: {
              channel_id: 'sportmatch_default',
              sound: 'default',
            },
          },
          apns: {
            payload: {
              aps: {
                alert: { title, body },
                sound: 'default',
                badge: 1,
              },
            },
          },
        },
      }

      try {
        const accessToken = await getAccessToken(fcmServiceAccountKey)
        const fcmResponse = await fetch(
          `https://fcm.googleapis.com/v1/projects/${fcmProjectId}/messages:send`,
          {
            method: 'POST',
            headers: {
              'Authorization': `Bearer ${accessToken}`,
              'Content-Type': 'application/json',
            },
            body: JSON.stringify(fcmPayload),
          }
        )

        const fcmResult = await fcmResponse.json()
        fcmResults.push({ token: fcm_token.slice(-8), status: fcmResponse.status, result: fcmResult })

        // Remove invalid tokens
        if (fcmResponse.status === 404 || fcmResponse.status === 410) {
          await supabase
            .from('user_fcm_tokens')
            .delete()
            .eq('fcm_token', fcm_token)
        }
      } catch (fcmError) {
        fcmResults.push({ token: fcm_token.slice(-8), status: 'error', result: fcmError.message })
      }
    }

    // Always persist the notification in-app
    await supabase.from('notifications').insert({
      user_id,
      title,
      body,
      data: data || {},
      read: false,
    })

    return new Response(
      JSON.stringify({ success: true, push_sent: true, fcm_results: fcmResults }),
      { headers: { 'Content-Type': 'application/json' } }
    )
  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500, headers: { 'Content-Type': 'application/json' } }
    )
  }
})

/**
 * Obtain a short-lived OAuth2 access token for the FCM v1 API using a
 * service-account key stored as a JSON string in the environment variable.
 */
async function getAccessToken(serviceAccountKeyJson: string): Promise<string> {
  const key = JSON.parse(serviceAccountKeyJson)

  // Build JWT header + claims
  const header = { alg: 'RS256', typ: 'JWT' }
  const now = Math.floor(Date.now() / 1000)
  const claims = {
    iss: key.client_email,
    scope: 'https://www.googleapis.com/auth/firebase.messaging',
    aud: 'https://oauth2.googleapis.com/token',
    iat: now,
    exp: now + 3600,
  }

  const encoder = new TextEncoder()
  const toBase64Url = (data: Uint8Array) =>
    btoa(String.fromCharCode(...data))
      .replace(/\+/g, '-')
      .replace(/\//g, '_')
      .replace(/=+$/, '')

  const headerB64 = toBase64Url(encoder.encode(JSON.stringify(header)))
  const claimsB64 = toBase64Url(encoder.encode(JSON.stringify(claims)))
  const unsignedToken = `${headerB64}.${claimsB64}`

  // Import private key and sign
  const pemContents = key.private_key
    .replace(/-----BEGIN PRIVATE KEY-----/, '')
    .replace(/-----END PRIVATE KEY-----/, '')
    .replace(/\n/g, '')
  const binaryKey = Uint8Array.from(atob(pemContents), (c: string) => c.charCodeAt(0))

  const cryptoKey = await crypto.subtle.importKey(
    'pkcs8',
    binaryKey,
    { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' },
    false,
    ['sign']
  )

  const signature = new Uint8Array(
    await crypto.subtle.sign('RSASSA-PKCS1-v1_5', cryptoKey, encoder.encode(unsignedToken))
  )
  const jwt = `${unsignedToken}.${toBase64Url(signature)}`

  // Exchange JWT for access token
  const tokenResponse = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: `grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=${jwt}`,
  })

  const tokenData = await tokenResponse.json()
  if (!tokenData.access_token) {
    throw new Error(`Failed to get access token: ${JSON.stringify(tokenData)}`)
  }

  return tokenData.access_token
}

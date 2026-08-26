import { createClient } from '@supabase/supabase-js'

const supabaseUrl = 'https://lwasmvzsagowgmiqssph.supabase.co'
const supabasePublishableKey = 'sb_publishable_Zukw53JQ0R_rMuxxC1eeRg_28_QavNC'
const AUTH_STARTUP_TIMEOUT_MS = 10000

const client = createClient(supabaseUrl, supabasePublishableKey)

// iOS standalone PWAs can occasionally stall while Supabase restores the
// persisted auth session. Bound only the initial getSession call so React can
// leave the startup gate instead of waiting forever. This is a maximum wait,
// not a fixed delay: normal local/session/network restoration resolves as soon
// as it is ready. This does not sign the user out, clear storage, or stop the
// normal auth-state listener from restoring a delayed session afterward.
const originalGetSession = client.auth.getSession.bind(client.auth)
client.auth.getSession = (...args) => {
  let timeoutId
  const timeout = new Promise((resolve) => {
    timeoutId = window.setTimeout(() => {
      resolve({ data: { session: null }, error: null })
    }, AUTH_STARTUP_TIMEOUT_MS)
  })

  return Promise.race([originalGetSession(...args), timeout])
    .finally(() => window.clearTimeout(timeoutId))
}

// Keep hosted beta auth callbacks on the Fameverse origin instead of
// Supabase's default localhost fallback when email confirmations are enabled.
const originalSignUp = client.auth.signUp.bind(client.auth)
client.auth.signUp = (credentials) => originalSignUp({
  ...credentials,
  options: {
    ...(credentials.options || {}),
    emailRedirectTo: credentials.options?.emailRedirectTo || window.location.origin,
  },
})

export const supabase = client

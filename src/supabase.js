import { createClient } from '@supabase/supabase-js'

const supabaseUrl = 'https://lwasmvzsagowgmiqssph.supabase.co'
const supabasePublishableKey = 'sb_publishable_Zukw53JQ0R_rMuxxC1eeRg_28_QavNC'

const client = createClient(supabaseUrl, supabasePublishableKey)

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

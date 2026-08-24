import { createClient } from '@supabase/supabase-js'

const supabaseUrl = 'https://lwasmvzsagowgmiqssph.supabase.co'
const supabasePublishableKey = 'sb_publishable_Zukw53JQ0R_rMuxxC1eeRg_28_QavNC'

export const supabase = createClient(supabaseUrl, supabasePublishableKey)

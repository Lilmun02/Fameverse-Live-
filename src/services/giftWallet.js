import { supabase } from './supabase.js'

function normalizeBalance(value) {
  return Math.max(0, Number(value || 0))
}

export async function refillBetaWallet(amount = 10000) {
  const { data, error } = await supabase.rpc('refill_beta_wallet', {
    p_amount: amount,
  })

  if (error) throw error
  return normalizeBalance(data)
}

export async function loadBetaWalletBalance(userId) {
  if (!userId) return 0

  const { data, error } = await supabase
    .from('beta_coin_wallets')
    .select('balance')
    .eq('user_id', userId)
    .maybeSingle()

  if (error) throw error
  if (!data) return refillBetaWallet(10000)
  return normalizeBalance(data.balance)
}

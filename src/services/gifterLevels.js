import { supabase } from './supabase.js'

export function computeGifterLevel(totalCoins = 0) {
  const normalized = Math.max(0, Number(totalCoins) || 0)
  return Math.min(99, Math.max(1, Math.floor(Math.sqrt(normalized / 100)) + 1))
}

export async function loadGifterStats(userId) {
  if (!userId) return { totalCoinsSent: 0, giftCount: 0, level: 1 }

  const { data, error } = await supabase
    .from('gifter_stats')
    .select('total_coins_sent, gift_count, level')
    .eq('user_id', userId)
    .maybeSingle()

  if (error) throw error
  return {
    totalCoinsSent: Number(data?.total_coins_sent || 0),
    giftCount: Number(data?.gift_count || 0),
    level: Number(data?.level || 1),
  }
}

export async function recordBetaGift({ roomId, giftId, quantity }) {
  const { data, error } = await supabase.rpc('record_beta_gift', {
    p_room_id: roomId,
    p_gift_id: giftId,
    p_quantity: quantity,
  })

  if (error) throw error
  const row = Array.isArray(data) ? data[0] : data
  return {
    totalCoinsSent: Number(row?.total_coins_sent || 0),
    giftCount: Number(row?.gift_count || 0),
    level: Number(row?.level || 1),
  }
}

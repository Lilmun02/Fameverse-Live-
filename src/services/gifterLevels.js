import {
  computeGifterLevel,
  getGifterProgress,
  GIFTER_LEVEL_THRESHOLDS,
  gifterLevelRequirement,
} from '../features/badges/gifterProgression.js'
import { supabase } from './supabase.js'

export {
  computeGifterLevel,
  getGifterProgress,
  GIFTER_LEVEL_THRESHOLDS,
  gifterLevelRequirement,
} from '../features/badges/gifterProgression.js'

function normalizeStats(row) {
  const totalCoinsSent = Number(row?.total_coins_sent ?? row?.totalCoinsSent ?? 0)
  return {
    totalCoinsSent,
    giftCount: Number(row?.gift_count ?? row?.giftCount ?? 0),
    level: computeGifterLevel(totalCoinsSent),
  }
}

export async function loadGifterStats(userId) {
  if (!userId) return { totalCoinsSent: 0, giftCount: 0, level: 1 }

  const { data, error } = await supabase
    .from('gifter_stats')
    .select('total_coins_sent, gift_count, level')
    .eq('user_id', userId)
    .maybeSingle()

  if (error) throw error
  return normalizeStats(data)
}

export async function recordBetaGift({ roomId, giftId, quantity }) {
  const { data, error } = await supabase.rpc('record_beta_gift', {
    p_room_id: roomId,
    p_gift_id: giftId,
    p_quantity: quantity,
  })

  if (error) throw error
  const row = Array.isArray(data) ? data[0] : data
  return normalizeStats(row)
}

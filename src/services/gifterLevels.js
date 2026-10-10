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

function normalizeStats(row, imported = null) {
  const totalCoinsSent = Number(row?.total_coins_sent ?? row?.totalCoinsSent ?? 0)
  const level = computeGifterLevel(totalCoinsSent)
  const importedBadgeLevel = Math.min(99, Math.max(0, Number(imported?.approved_level || 0)))
  return {
    totalCoinsSent,
    giftCount: Number(row?.gift_count ?? row?.giftCount ?? 0),
    level,
    // Recognition never changes the earned level, wallet, or spending totals.
    importedBadgeLevel,
    importedBadgeSource: imported?.source_platform || null,
    displayLevel: Math.max(level, importedBadgeLevel),
    walletBalance: Number(row?.wallet_balance ?? row?.walletBalance ?? 0),
  }
}

export async function loadGifterStats(userId) {
  if (!userId) return { totalCoinsSent: 0, giftCount: 0, level: 1, walletBalance: 0 }

  const { data, error } = await supabase
    .from('gifter_stats')
    .select('total_coins_sent, gift_count, level')
    .eq('user_id', userId)
    .maybeSingle()

  if (error) throw error
  // Transfers are an optional recognition layer and must never block base
  // gifter progress when the migration is not yet installed.
  let imported = null
  try {
    const { data: record, error: importError } = await supabase
      .from('badge_imports')
      .select('approved_level,source_platform')
      .eq('user_id', userId)
      .maybeSingle()
    if (!importError) imported = record
  } catch {
    // Older beta backends may not have the import table yet.
  }
  return normalizeStats(data, imported)
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

import { supabase } from '../supabase.js'
import {
  TAP_INTEGRITY_VERSION,
  TAP_LEDGER_SOURCE,
  TAP_NETWORK_BATCH_MAX,
} from '../../features/taps/tapIntegrityConfig.js'

const TOTAL_FIELDS = 'room_id, raw_taps, eligible_taps, updated_at'

export async function getLiveTapTotals(roomId) {
  if (!roomId) return { totals: { rawTaps: 0, eligibleTaps: 0 }, error: null }

  const { data, error } = await supabase
    .from('live_tap_totals')
    .select(TOTAL_FIELDS)
    .eq('room_id', roomId)
    .maybeSingle()

  if (error) return { totals: { rawTaps: 0, eligibleTaps: 0 }, error }

  return {
    totals: {
      rawTaps: Number(data?.raw_taps || 0),
      eligibleTaps: Number(data?.eligible_taps || 0),
      updatedAt: data?.updated_at || null,
    },
    error: null,
  }
}

export async function submitLiveTapBatch({ roomId, batchId, timestamps }) {
  if (!roomId || !batchId || !Array.isArray(timestamps) || timestamps.length < 1) {
    return { result: null, error: new Error('invalid-tap-batch') }
  }
  if (timestamps.length > TAP_NETWORK_BATCH_MAX) {
    return { result: null, error: new Error('tap-batch-too-large') }
  }

  const { data, error } = await supabase.rpc('record_live_tap_batch', {
    p_room_id: roomId,
    p_batch_id: batchId,
    p_timestamps: timestamps,
  })

  if (error) return { result: null, error }
  const row = data?.[0]
  if (!row) return { result: null, error: new Error('tap-ledger-empty-response') }

  return {
    result: {
      source: TAP_LEDGER_SOURCE,
      integrityVersion: row.integrity_version || TAP_INTEGRITY_VERSION,
      rawTapCount: Number(row.raw_tap_count || 0),
      eligibleTapCount: Number(row.eligible_tap_count || 0),
      trustScore: Number(row.trust_score || 0),
      classification: row.classification,
      reasons: Array.isArray(row.reasons) ? row.reasons : [],
      tapsPerSecond: Number(row.taps_per_second || 0),
      intervalCv: row.interval_cv == null ? null : Number(row.interval_cv),
      totalRawTaps: Number(row.total_raw_taps || 0),
      totalEligibleTaps: Number(row.total_eligible_taps || 0),
    },
    error: null,
  }
}

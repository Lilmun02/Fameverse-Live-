import { supabase } from '../supabase.js'

export async function loadLiveViewerIdentityStats(roomId, userIds = []) {
  const ids = [...new Set(userIds.filter(Boolean))].slice(0, 200)
  if (!ids.length) return []

  const { data, error } = await supabase.rpc('get_live_viewer_identity_stats', {
    p_room_id: roomId || null,
    p_user_ids: ids,
  })

  if (error) throw error

  return (data || []).map((row) => ({
    userId: row.user_id,
    username: row.username || null,
    displayName: row.display_name || row.username || 'Fameverse User',
    avatarUrl: row.avatar_url || null,
    totalCoinsSent: Math.max(0, Number(row.total_coins_sent || 0)),
    gifterLevel: Math.min(99, Math.max(1, Number(row.gifter_level || 1))),
    roomGiftCount: Math.max(0, Number(row.room_gift_count || 0)),
    roomFameTaps: Math.max(0, Number(row.room_fame_taps || 0)),
    accountRole: row.account_role || null,
  }))
}

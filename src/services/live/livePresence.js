import { supabase } from '../supabase.js'
import { LIVE_PRESENCE_STALE_MS } from './livePresenceConfig.js'

const ROOM_FIELDS = 'id, host_user_id, title, status, started_at, ended_at, heartbeat_at, created_at, updated_at'

function cleanTitle(title) {
  return String(title || '').trim().slice(0, 120) || 'Live session'
}

export async function startLiveRoom({ hostUserId, title }) {
  if (!hostUserId) return { room: null, error: new Error('missing-host') }

  const now = new Date().toISOString()
  const { error: closeError } = await supabase
    .from('live_rooms')
    .update({ status: 'ended', ended_at: now, updated_at: now })
    .eq('host_user_id', hostUserId)
    .eq('status', 'live')

  if (closeError) return { room: null, error: closeError }

  const { data, error } = await supabase
    .from('live_rooms')
    .insert({
      host_user_id: hostUserId,
      title: cleanTitle(title),
      status: 'live',
      started_at: now,
      heartbeat_at: now,
      updated_at: now,
    })
    .select(ROOM_FIELDS)
    .single()

  return { room: data || null, error: error || null }
}

export async function heartbeatLiveRoom({ roomId, hostUserId }) {
  if (!roomId || !hostUserId) return false
  const now = new Date().toISOString()
  const { error } = await supabase
    .from('live_rooms')
    .update({ heartbeat_at: now, updated_at: now })
    .eq('id', roomId)
    .eq('host_user_id', hostUserId)
    .eq('status', 'live')
  return !error
}

export async function endLiveRoom({ roomId, hostUserId }) {
  if (!roomId || !hostUserId) return true
  const now = new Date().toISOString()
  const { error } = await supabase
    .from('live_rooms')
    .update({ status: 'ended', ended_at: now, heartbeat_at: now, updated_at: now })
    .eq('id', roomId)
    .eq('host_user_id', hostUserId)
    .eq('status', 'live')
  return !error
}

export async function listActiveLiveRooms() {
  const cutoff = new Date(Date.now() - LIVE_PRESENCE_STALE_MS).toISOString()
  const { data, error } = await supabase
    .from('live_rooms')
    .select(ROOM_FIELDS)
    .eq('status', 'live')
    .gte('heartbeat_at', cutoff)
    .order('started_at', { ascending: false })
  return { rooms: data || [], error: error || null }
}

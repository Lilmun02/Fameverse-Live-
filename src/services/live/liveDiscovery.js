import { supabase } from '../supabase.js'
import { listActiveLiveRooms } from './livePresence.js'

const PROFILE_FIELDS = 'id, username, display_name, avatar_url'

function mapProfile(profile) {
  return {
    id: profile?.id || null,
    username: profile?.username || null,
    displayName: profile?.display_name || 'Fameverse creator',
    avatarUrl: profile?.avatar_url || null,
  }
}

export async function listDiscoverableLiveRooms({ excludeUserId } = {}) {
  const { rooms, error } = await listActiveLiveRooms()
  if (error) return { rooms: [], error }

  const visibleRooms = rooms.filter((room) => room.host_user_id !== excludeUserId)
  if (!visibleRooms.length) return { rooms: [], error: null }

  const hostIds = [...new Set(visibleRooms.map((room) => room.host_user_id).filter(Boolean))]
  const { data: profiles, error: profileError } = await supabase
    .from('profiles')
    .select(PROFILE_FIELDS)
    .in('id', hostIds)

  const profilesById = new Map((profiles || []).map((profile) => [profile.id, mapProfile(profile)]))

  return {
    rooms: visibleRooms.map((room) => ({
      ...room,
      host: profilesById.get(room.host_user_id) || mapProfile({ id: room.host_user_id }),
    })),
    error: profileError || null,
  }
}

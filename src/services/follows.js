import { supabase } from './supabase.js'

export async function loadFollowNetwork(userId) {
  if (!userId) return { incoming: [], outgoing: [], profiles: [] }

  const [{ data: incoming, error: incomingError }, { data: outgoing, error: outgoingError }] = await Promise.all([
    supabase.from('follows').select('follower_id, created_at').eq('following_id', userId),
    supabase.from('follows').select('following_id, created_at').eq('follower_id', userId),
  ])

  if (incomingError) throw incomingError
  if (outgoingError) throw outgoingError

  const ids = [...new Set([
    ...(incoming || []).map((item) => item.follower_id),
    ...(outgoing || []).map((item) => item.following_id),
  ])]

  if (!ids.length) return { incoming: incoming || [], outgoing: outgoing || [], profiles: [] }

  const { data: profiles, error: profilesError } = await supabase
    .from('profiles')
    .select('id, username, display_name, avatar_url')
    .in('id', ids)

  if (profilesError) throw profilesError

  return {
    incoming: incoming || [],
    outgoing: outgoing || [],
    profiles: profiles || [],
  }
}

export async function followUser(userId, targetId) {
  const { error } = await supabase.from('follows').insert({ follower_id: userId, following_id: targetId })
  if (error && error.code !== '23505') throw error
}

export async function unfollowUser(userId, targetId) {
  const { error } = await supabase
    .from('follows')
    .delete()
    .eq('follower_id', userId)
    .eq('following_id', targetId)

  if (error) throw error
}

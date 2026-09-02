import { supabase } from './supabase.js'

const LIVE_PROFILE_FIELDS = 'id, username, display_name, bio, avatar_url'

export async function loadLiveIdentity(userId) {
  if (!userId) return null

  const { data: profile, error } = await supabase
    .from('profiles')
    .select(LIVE_PROFILE_FIELDS)
    .eq('id', userId)
    .maybeSingle()

  if (error) throw error
  if (!profile) return null

  const [{ count: followerCount, error: followerError }, { count: followingCount, error: followingError }] = await Promise.all([
    supabase.from('follows').select('follower_id', { count: 'exact', head: true }).eq('following_id', userId),
    supabase.from('follows').select('following_id', { count: 'exact', head: true }).eq('follower_id', userId),
  ])

  if (followerError) throw followerError
  if (followingError) throw followingError

  return {
    id: profile.id,
    username: profile.username || null,
    displayName: profile.display_name || profile.username || 'Fameverse User',
    bio: profile.bio || '',
    avatarUrl: profile.avatar_url || null,
    followerCount: followerCount || 0,
    followingCount: followingCount || 0,
  }
}

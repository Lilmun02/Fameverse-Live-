import { loadAccountRole } from './accountRoles.js'
import { computeGifterLevel } from './gifterLevels.js'
import { supabase } from './supabase.js'

const LIVE_PROFILE_FIELDS = 'id, username, display_name, bio, avatar_url'

async function loadSocialCounts(userId) {
  const { data, error } = await supabase.rpc('get_profile_social_counts', {
    p_user_id: userId,
  })

  if (error) throw error
  const row = Array.isArray(data) ? data[0] : data

  return {
    followerCount: Math.max(0, Number(row?.follower_count || 0)),
    followingCount: Math.max(0, Number(row?.following_count || 0)),
    friendCount: Math.max(0, Number(row?.friend_count || 0)),
  }
}

export async function loadLiveIdentity(userId) {
  if (!userId) return null

  const { data: profile, error } = await supabase
    .from('profiles')
    .select(LIVE_PROFILE_FIELDS)
    .eq('id', userId)
    .maybeSingle()

  if (error) throw error
  if (!profile) return null

  const [
    socialCounts,
    { data: gifterStats, error: gifterError },
    accountRole,
  ] = await Promise.all([
    loadSocialCounts(userId),
    supabase.from('gifter_stats').select('total_coins_sent, level').eq('user_id', userId).maybeSingle(),
    loadAccountRole(userId),
  ])

  if (gifterError) throw gifterError

  const totalCoinsSent = Math.max(0, Number(gifterStats?.total_coins_sent || 0))

  return {
    id: profile.id,
    username: profile.username || null,
    displayName: profile.display_name || profile.username || 'Fameverse User',
    bio: profile.bio || '',
    avatarUrl: profile.avatar_url || null,
    followerCount: socialCounts.followerCount,
    followingCount: socialCounts.followingCount,
    friendCount: socialCounts.friendCount,
    totalCoinsSent,
    gifterLevel: computeGifterLevel(totalCoinsSent),
    accountRole,
  }
}

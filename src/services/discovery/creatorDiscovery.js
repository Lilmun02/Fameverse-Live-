import { supabase } from '../supabase.js'

const PROFILE_FIELDS = 'id, username, display_name, bio, avatar_url, created_at'
const RECOMMENDED_LIMIT = 12

function mapProfile(profile, followerCounts) {
  return {
    id: profile.id,
    username: profile.username || null,
    displayName: profile.display_name || profile.username || 'Fameverse creator',
    bio: profile.bio || '',
    avatarUrl: profile.avatar_url || null,
    createdAt: profile.created_at || null,
    followerCount: followerCounts.get(profile.id) || 0,
  }
}

export async function listRecommendedCreators({ excludeUserId } = {}) {
  let profilesQuery = supabase
    .from('profiles')
    .select(PROFILE_FIELDS)
    .order('created_at', { ascending: false })
    .limit(40)

  if (excludeUserId) profilesQuery = profilesQuery.neq('id', excludeUserId)

  const [{ data: profiles, error: profileError }, { data: follows, error: followsError }] = await Promise.all([
    profilesQuery,
    supabase.from('follows').select('following_id'),
  ])

  if (profileError) return { creators: [], error: profileError }
  if (followsError) return { creators: [], error: followsError }

  const followerCounts = new Map()
  for (const follow of follows || []) {
    followerCounts.set(follow.following_id, (followerCounts.get(follow.following_id) || 0) + 1)
  }

  const creators = (profiles || [])
    .map((profile) => mapProfile(profile, followerCounts))
    .sort((a, b) => {
      if (b.followerCount !== a.followerCount) return b.followerCount - a.followerCount
      return new Date(b.createdAt || 0).getTime() - new Date(a.createdAt || 0).getTime()
    })
    .slice(0, RECOMMENDED_LIMIT)

  return { creators, error: null }
}

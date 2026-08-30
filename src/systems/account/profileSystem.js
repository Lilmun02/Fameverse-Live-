import { supabase } from '../../services/supabase.js'
import { cleanUsername } from '../../utils/profile.js'

const PROFILE_COLUMNS = 'id, username, display_name, bio, avatar_url, created_at, updated_at'

export function emptyProfileDraft() {
  return { display_name: '', username: '', bio: '' }
}

export function profileToDraft(profile) {
  return {
    display_name: profile?.display_name || '',
    username: profile?.username || '',
    bio: profile?.bio || '',
  }
}

export async function loadProfile(userId) {
  return supabase
    .from('profiles')
    .select(PROFILE_COLUMNS)
    .eq('id', userId)
    .single()
}

export async function saveProfile(userId, draft) {
  const nextUsername = cleanUsername(draft.username)
  if (draft.username && nextUsername.length < 3) {
    return { validationError: 'Username must be at least 3 characters' }
  }

  const { data, error } = await supabase
    .from('profiles')
    .update({
      display_name: draft.display_name.trim() || 'Fameverse User',
      username: nextUsername || null,
      bio: draft.bio.trim().slice(0, 160),
    })
    .eq('id', userId)
    .select(PROFILE_COLUMNS)
    .single()

  return { data, error }
}

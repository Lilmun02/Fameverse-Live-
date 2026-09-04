import { supabase } from './supabase.js'

const AVATAR_BUCKET = 'profile-avatars'
const MAX_AVATAR_BYTES = 5 * 1024 * 1024
const AVATAR_TYPES = new Map([
  ['image/jpeg', 'jpg'],
  ['image/png', 'png'],
  ['image/webp', 'webp'],
])

export function validateProfileAvatar(file) {
  if (!file) return { ok: true, message: '' }
  if (!AVATAR_TYPES.has(file.type)) {
    return { ok: false, message: 'Use a JPG, PNG, or WEBP image.' }
  }
  if (file.size > MAX_AVATAR_BYTES) {
    return { ok: false, message: 'Profile photos must be 5 MB or smaller.' }
  }
  return { ok: true, message: '' }
}

export async function uploadProfileAvatar(userId, file) {
  if (!userId) throw new Error('Missing profile owner')

  const validation = validateProfileAvatar(file)
  if (!validation.ok) throw new Error(validation.message)
  if (!file) return null

  const extension = AVATAR_TYPES.get(file.type)
  const suffix = typeof crypto !== 'undefined' && typeof crypto.randomUUID === 'function'
    ? crypto.randomUUID()
    : `${Date.now()}-${Math.random().toString(36).slice(2)}`
  const objectPath = `${userId}/avatar-${suffix}.${extension}`

  const { error } = await supabase.storage
    .from(AVATAR_BUCKET)
    .upload(objectPath, file, {
      cacheControl: '3600',
      contentType: file.type,
      upsert: false,
    })

  if (error) throw error

  const { data } = supabase.storage.from(AVATAR_BUCKET).getPublicUrl(objectPath)
  if (!data?.publicUrl) throw new Error('Profile photo URL was not created')
  return data.publicUrl
}

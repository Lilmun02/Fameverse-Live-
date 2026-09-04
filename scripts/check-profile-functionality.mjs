import { readFileSync } from 'node:fs'

const rules = [
  {
    file: 'src/components/profile/ProfileEdit.jsx',
    required: ['type="file"', 'validateProfileAvatar', 'saveProfile(event, avatarFile)', 'Change photo'],
  },
  {
    file: 'src/services/profileAvatars.js',
    required: ["from(AVATAR_BUCKET)", '.upload(', 'getPublicUrl', 'MAX_AVATAR_BYTES'],
  },
  {
    file: 'src/hooks/useAccount.js',
    required: ['uploadProfileAvatar', 'avatar_url: avatarUrl', "setToast(avatarFile ? 'Profile and photo saved' : 'Profile saved')"],
  },
  {
    file: 'src/components/profile/ProfileScreen.jsx',
    required: ['loadGifterStats', 'setGifterLevel', 'gifterLevel={gifterLevel}'],
  },
  {
    file: 'src/components/profile/ProfileView.jsx',
    required: ["setConnectionsMode('following')", "setConnectionsMode('followers')", "setConnectionsMode('friends')", "openProfileMode('edit')", "openProfileMode('settings')", "openProfileMode('studio')"],
  },
  {
    file: 'src/components/profile/ProfileConnections.jsx',
    required: ["mode === 'friends'", 'toggleFollow(item.id)', 'onClick={onClose}'],
  },
  {
    file: 'supabase/migrations/20260903_profile_avatar_storage.sql',
    required: ["'profile-avatars'", 'file_size_limit', 'allowed_mime_types', 'auth.uid()::text'],
  },
]

let failed = false
for (const rule of rules) {
  const source = readFileSync(rule.file, 'utf8')
  for (const needle of rule.required) {
    if (!source.includes(needle)) {
      failed = true
      console.error(`[profile-law] ${rule.file} is missing: ${needle}`)
    }
  }
}

if (failed) process.exit(1)
console.log('[profile-law] profile functionality wiring passed')

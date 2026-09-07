import assert from 'node:assert/strict'
import { readFileSync } from 'node:fs'

function read(path) {
  return readFileSync(new URL(`../${path}`, import.meta.url), 'utf8')
}

const migration = read('supabase/migrations/20260907_creator_studio_backend_foundation.sql')
const liveSetup = read('src/hooks/useLiveSetup.js')
const creatorBackend = read('src/services/live/creatorStudioBackend.js')
const livePresence = read('src/services/live/livePresence.js')

assert.match(migration, /create table if not exists public\.creator_live_drafts/, 'Creator Live setup must have persistent Supabase storage.')
assert.match(migration, /create table if not exists public\.creator_moderators/, 'Creator moderator assignments must live in Supabase.')
assert.match(migration, /if v_count >= 3/, 'Beta moderator maximum must be enforced by the server at three.')
assert.match(migration, /get_creator_live_history/, 'Creator Studio must have an authoritative Live-history RPC.')
assert.match(migration, /get_creator_gift_activity/, 'Creator Studio must have an authoritative gift-activity RPC.')

assert.match(creatorBackend, /from\('creator_live_drafts'\)/, 'Live setup must load and save through creator_live_drafts.')
assert.match(creatorBackend, /\.upsert\(/, 'Live setup changes must persist through Supabase instead of browser-only state.')
assert.doesNotMatch(creatorBackend, /localStorage|sessionStorage/, 'Creator Live setup must not use browser storage as its authority.')

assert.match(liveSetup, /loadCreatorLiveDraft/, 'Live setup must hydrate the signed-in creator draft from Supabase.')
assert.match(liveSetup, /saveCreatorLiveDraft/, 'Live setup must persist edits to Supabase.')
assert.match(liveSetup, /await saveCreatorLiveDraft/, 'Go Live must wait for the latest setup to reach the backend.')
assert.match(liveSetup, /onAuthStateChange/, 'Live setup hydration must follow authenticated creator changes.')

assert.match(livePresence, /from\('creator_live_drafts'\)/, 'Live-room publication must read the creator backend setup.')
assert.match(livePresence, /goal:\s*setup\.goal/, 'Published Live rooms must persist the creator goal.')
assert.match(livePresence, /wishlist_gift_ids:\s*setup\.wishlistGiftIds/, 'Published Live rooms must persist the creator gift wishlist.')
assert.match(livePresence, /ROOM_FIELDS = 'id, host_user_id, title, goal, wishlist_gift_ids/, 'Live-room reads must retain the persisted setup fields.')

console.log('[creator-backend-law] persistent Live setup, room metadata, Creator Studio history/activity, and the server-side three-mod cap are locked')

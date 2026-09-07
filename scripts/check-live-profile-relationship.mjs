import assert from 'node:assert/strict'
import { readFileSync } from 'node:fs'

function read(path) {
  return readFileSync(new URL(`../${path}`, import.meta.url), 'utf8')
}

const profileSheet = read('src/components/live/LiveProfileSheet.jsx')
const profileService = read('src/services/profiles.js')
const profileCss = read('src/styles/live/profile-sheet.css')
const migration = read('supabase/migrations/20260907_profile_social_counts.sql')

assert.match(profileSheet, /Gifts Sent[\s\S]*\{!isSelf && \([\s\S]*FameTaps/, 'Other-user in-Live profiles must lead with Gifts Sent and FameTaps while self profiles hide FameTaps.')
assert.match(profileSheet, /isSelf \? 'is-self' : ''/, 'Self in-Live profiles must switch the activity row to the single-stat layout.')
assert.match(profileCss, /\.fv-live-profile-room-stats\.is-self\s*\{[\s\S]*grid-template-columns:\s*minmax\(0, 1fr\)/, 'Host self-profile must show Gifts Sent alone without an empty FameTaps column.')
assert.match(profileSheet, /profile\.followerCount[\s\S]*Followers[\s\S]*profile\.followingCount[\s\S]*Following[\s\S]*profile\.friendCount[\s\S]*Friends/, 'Profile social counts must remain Followers, Following, Friends in that order.')
assert.match(profileCss, /\.fv-live-profile-counts\s*\{[\s\S]*grid-template-columns:\s*repeat\(3, minmax\(0, 1fr\)\)/, 'Followers, Following, and Friends must stay three-across.')
assert.match(profileSheet, /isFollowing && isFollower[\s\S]*\? 'Friends'[\s\S]*\? 'Following'[\s\S]*\? 'Follow Back'[\s\S]*: 'Follow'/, 'Relationship button must preserve Friends, Following, Follow Back, and Follow states.')
assert.match(profileSheet, /onClick=\{toggleFollow\}/, 'Relationship button must remain wired to the real follow action.')
assert.match(profileService, /rpc\('get_profile_social_counts'/, 'Profile social counts must come from the Supabase authority RPC.')
assert.match(migration, /friend_count bigint/, 'Backend profile social counts must include mutual-follow friends.')
assert.match(migration, /exists \([\s\S]*incoming\.follower_id = outgoing\.following_id[\s\S]*incoming\.following_id = p_user_id/, 'Friend count must mean mutual following, not a cosmetic client label.')
assert.match(migration, /grant execute on function public\.get_profile_social_counts\(uuid\) to authenticated/, 'Profile social count RPC must be authenticated only.')

console.log('Live profile relationship contract passed: self FameTaps hidden, Gifts Sent preserved, Followers/Following/Friends stay three-across, and follow states remain wired.')

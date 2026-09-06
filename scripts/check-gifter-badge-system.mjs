import assert from 'node:assert/strict'
import { readFileSync } from 'node:fs'

function read(path) {
  return readFileSync(new URL(`../${path}`, import.meta.url), 'utf8')
}

const progression = read('src/features/badges/gifterProgression.js')
const badgeSystem = read('src/features/badges/gifterBadgeSystem.js')
const badgeComponent = read('src/components/profile/GifterBadge.jsx')
const profileView = read('src/components/profile/ProfileView.jsx')
const liveProfile = read('src/components/live/LiveProfileSheet.jsx')
const liveChat = read('src/components/live/LiveChat.jsx')
const liveActivity = read('src/hooks/useLiveActivity.js')
const migration = read('supabase/migrations/20260906_lock_gifter_progression_curve.sql')

assert.match(progression, /0, 100, 250, 500, 1000/, 'Gifter progression must retain the approved fast early levels.')
assert.match(progression, /10000,[\s\S]*15000,[\s\S]*22500/, 'Lv.10-Lv.12 approved thresholds must stay locked.')
assert.match(progression, /2500000,[\s\S]*10000000,[\s\S]*50000000/, 'Late-game gifter progression anchors must stay locked.')
assert.match(badgeSystem, /Spark Gifter[\s\S]*Bronze Gifter[\s\S]*Silver Gifter[\s\S]*Gold Gifter/, 'Early badge ladder must stay intact.')
assert.match(badgeSystem, /Platinum Gifter[\s\S]*Diamond Gifter[\s\S]*Royal Gifter[\s\S]*Legendary Gifter[\s\S]*Fame Icon/, 'Late badge ladder must stay intact.')
assert.match(badgeComponent, /getGifterBadgeForLevel/, 'Profile badge component must resolve the badge from earned level.')
assert.match(profileView, /<GifterBadge/, 'Main profiles must render the earned gifter badge.')
assert.match(profileView, /coinsToNext/, 'Profile gifter card must show level progress from gift coins.')
assert.doesNotMatch(profileView, /nextBadge|next badge/i, 'Profiles must not reveal the next badge before it is earned.')
assert.match(liveProfile, /<GifterBadge/, 'In-Live profile sheets must render the earned badge.')
assert.match(liveProfile, /'Follow Back'/, 'In-Live profile must retain Follow Back state from the existing follow network.')
assert.match(liveProfile, /'Friends'/, 'In-Live profile must retain Friends state from the existing follow network.')
assert.doesNotMatch(liveChat, /GifterBadge|fam-gifter-badge|item\.badge/, 'Live chat must show levels only, never gifter badges.')
assert.doesNotMatch(liveActivity, /badge:/, 'Realtime Live activity must not broadcast gifter badge identity.')
assert.match(migration, /\(11, 15000::bigint\)/, 'Server progression must keep 15,000 gift coins at Lv.11.')
assert.match(migration, /update public\.gifter_stats/, 'Existing gifter stats must be recalculated when the progression migration is applied.')

console.log('[gifter-badge-law] progression, profile-only badges, hidden next badge, and Live level-only identity are locked')

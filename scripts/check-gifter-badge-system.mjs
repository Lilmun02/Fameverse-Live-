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
const liveProfileData = read('src/services/profiles.js')
const accountRoles = read('src/services/accountRoles.js')
const liveChat = read('src/components/live/LiveChat.jsx')
const liveActivity = read('src/hooks/useLiveActivity.js')
const migration = read('supabase/migrations/20260906_lock_gifter_progression_curve.sql')

assert.match(progression, /0, 100, 250, 500, 1000/, 'Gifter progression must retain the approved fast early levels.')
assert.match(progression, /10000,[\s\S]*15000,[\s\S]*22500/, 'Lv.10-Lv.12 approved thresholds must stay locked.')
assert.match(progression, /2500000,[\s\S]*10000000,[\s\S]*50000000/, 'Late-game gifter progression anchors must stay locked.')
assert.match(badgeSystem, /Spark Gifter[\s\S]*Bronze Gifter[\s\S]*Silver Gifter[\s\S]*Gold Gifter/, 'Early badge ladder must stay intact.')
assert.match(badgeSystem, /Platinum Gifter[\s\S]*Diamond Gifter[\s\S]*Royal Gifter[\s\S]*Legendary Gifter[\s\S]*Fame Icon/, 'Late badge ladder must stay intact.')
assert.match(badgeSystem, /Spark Gifter[^\n]*minLevel: 1, maxLevel: 4/, 'Spark Gifter must remain Lv.1-Lv.4.')
assert.match(badgeSystem, /Bronze Gifter[^\n]*minLevel: 5, maxLevel: 9/, 'Bronze Gifter must remain Lv.5-Lv.9.')
assert.match(badgeSystem, /Silver Gifter[^\n]*minLevel: 10, maxLevel: 19/, 'Silver Gifter must remain Lv.10-Lv.19.')
assert.match(badgeSystem, /Gold Gifter[^\n]*minLevel: 20, maxLevel: 29/, 'Gold Gifter must remain Lv.20-Lv.29.')
assert.match(badgeSystem, /Platinum Gifter[^\n]*minLevel: 30, maxLevel: 49/, 'Platinum Gifter must remain Lv.30-Lv.49.')
assert.match(badgeSystem, /Diamond Gifter[^\n]*minLevel: 50, maxLevel: 69/, 'Diamond Gifter must remain Lv.50-Lv.69.')
assert.match(badgeSystem, /Royal Gifter[^\n]*minLevel: 70, maxLevel: 84/, 'Royal Gifter must remain Lv.70-Lv.84.')
assert.match(badgeSystem, /Legendary Gifter[^\n]*minLevel: 85, maxLevel: 98/, 'Legendary Gifter must remain Lv.85-Lv.98.')
assert.match(badgeSystem, /Fame Icon[^\n]*minLevel: 99, maxLevel: 99/, 'Fame Icon must remain Lv.99 only.')
assert.match(badgeComponent, /getGifterBadgeForLevel/, 'Profile badge component must resolve the badge from earned level.')
assert.match(badgeComponent, /data-gifter-artwork/, 'Gifter Badge V1 must render scalable badge artwork.')
assert.match(badgeComponent, /<svg/, 'Gifter Badge V1 must stay vector-based so badges remain crisp on mobile.')
assert.match(badgeComponent, /totalCoinsSent = null/, 'Gifter badges must accept earned-coin state so zero-coin accounts can stay badge-free.')
assert.match(badgeComponent, /if \(!hasEarnedBadge\) return null/, 'Gifter badge component must refuse to render an unearned badge.')
assert.doesNotMatch(badgeComponent, /\{badge\.icon\}/, 'Cheap glyph placeholders must never return as the rendered badge artwork.')

const profileBadgeOccurrences = profileView.match(/<GifterBadge/g) || []
assert.equal(profileBadgeOccurrences.length, 1, 'Main profile must render at most one earned gifter badge.')
assert.match(profileView, /totalCoinsSent > 0 && !hideGifterBadge && \(/, 'Main profile must hide gifter identity until earned and keep owner/admin identities out of user gifter badges.')
assert.match(profileView, /isPrivilegedIdentityRole\(profile\?\.account_role\)/, 'Main profile must derive privileged identity from the backend role, never display-name guessing.')
assert.match(profileView, /totalCoinsSent=\{totalCoinsSent\}/, 'Main profile badge must receive the authoritative earned coin total.')
assert.doesNotMatch(profileView, /fv-gifter-identity-card|coinsToNext|nextBadge|next badge/i, 'Public profile must not duplicate gifter identity or spoil future badge progression.')

assert.match(accountRoles, /new Set\(\['owner', 'admin'\]\)/, 'Owner and admin identities must be explicitly privileged.')
assert.match(liveProfileData, /totalCoinsSent/, 'In-Live profile data must expose authoritative total gift coins.')
assert.match(liveProfileData, /accountRole/, 'In-Live profile data must expose backend account role identity.')
assert.match(liveProfile, /profile\.totalCoinsSent > 0 && !hideGifterBadge && \(/, 'In-Live profile must hide unearned badges and suppress user gifter badges for owner/admin identities.')
assert.match(liveProfile, /isPrivilegedIdentityRole\(profile\?\.accountRole\)/, 'In-Live owner/admin identity suppression must use the backend account role.')
assert.match(liveProfile, /totalCoinsSent=\{profile\.totalCoinsSent\}/, 'In-Live profile badge must use authoritative earned coin totals.')
assert.match(liveProfile, /'Follow Back'/, 'In-Live profile must retain Follow Back state from the existing follow network.')
assert.match(liveProfile, /'Friends'/, 'In-Live profile must retain Friends state from the existing follow network.')

assert.doesNotMatch(liveChat, /GifterBadge|fam-gifter-badge|item\.badge/, 'Live chat must show levels only, never gifter badges.')
assert.doesNotMatch(liveActivity, /badge:/, 'Realtime Live activity must not broadcast gifter badge identity.')
assert.match(migration, /\(11, 15000::bigint\)/, 'Server progression must keep 15,000 gift coins at Lv.11.')
assert.match(migration, /update public\.gifter_stats/, 'Existing gifter stats must be recalculated when the progression migration is applied.')

console.log('[gifter-badge-law] Gifter Badge V1 artwork, earned-only badges, owner/admin exclusion, no future spoilers, progression, and Live level-only identity are locked')

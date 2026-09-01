import assert from 'node:assert/strict'
import { VERSE_EVENT_TYPES, isVerseEventType } from '../src/features/ranking/eventContract.js'
import {
  RANKING_ENABLED,
  VERSE_MOMENTUM_TARGETS,
  VERSE_MOMENTUM_VERSION,
} from '../src/features/ranking/verseMomentumConfig.js'
import {
  aggregateVerseEvents,
  getVerseMomentumStatus,
  scoreVerseMomentum,
} from '../src/features/ranking/verseMomentum.js'

const event = (type, actorId, value = 1, extras = {}) => ({ type, actorId, value, ...extras })
const verifiedTap = (actorId, value) => event(VERSE_EVENT_TYPES.TAP, actorId, value, { integrityVerified: true })
const viewers = (count) => Array.from({ length: count }, (_, index) => event(VERSE_EVENT_TYPES.VIEWER_JOIN, `viewer-${index + 1}`))

assert.equal(RANKING_ENABLED, false, 'Verse Momentum must remain disconnected from Discover until real Live ranking is approved.')
assert.equal(VERSE_MOMENTUM_VERSION, 'FAM-ALGO-1.2')
assert.equal(scoreVerseMomentum([]).score, 0)
assert.equal(isVerseEventType('unfollow'), false, 'Unfollow must never become a ranking event by accident.')

const audienceOnly = scoreVerseMomentum(viewers(VERSE_MOMENTUM_TARGETS.audienceViewers))
const tapsOnly = scoreVerseMomentum([
  verifiedTap('tapper-1', VERSE_MOMENTUM_TARGETS.taps),
])
const giftsOnly = scoreVerseMomentum([
  event(VERSE_EVENT_TYPES.GIFT, 'supporter-1', VERSE_MOMENTUM_TARGETS.giftCoins),
])

assert.equal(audienceOnly.breakdown.audience, 100, 'Audience lane must reach the same 100-point ceiling.')
assert.equal(tapsOnly.breakdown.taps, 100, 'Tap lane must reach the same 100-point ceiling.')
assert.equal(giftsOnly.breakdown.gifts, 100, 'Gift lane must reach the same 100-point ceiling.')
assert.equal(audienceOnly.score, tapsOnly.score, 'Audience and Tap lanes must have equal maximum push.')
assert.equal(tapsOnly.score, giftsOnly.score, 'Tap and Gift lanes must have equal maximum push.')

const unverifiedTap = scoreVerseMomentum([
  event(VERSE_EVENT_TYPES.TAP, 'tapper-1', VERSE_MOMENTUM_TARGETS.taps),
])
assert.equal(unverifiedTap.breakdown.taps, 0, 'Raw tap events must not bypass Tap Integrity.')

const unlimitedTrustedTaps = aggregateVerseEvents([
  verifiedTap('tapper-1', VERSE_MOMENTUM_TARGETS.taps * 4),
])
assert.equal(unlimitedTrustedTaps.taps, VERSE_MOMENTUM_TARGETS.taps * 4, 'Trusted tap volume must not be hard-capped per user.')

const cappedGift = scoreVerseMomentum([
  event(VERSE_EVENT_TYPES.GIFT, 'supporter-1', VERSE_MOMENTUM_TARGETS.giftCoins * 10),
])
assert.equal(cappedGift.breakdown.gifts, 100, 'Money must not push the Gift lane beyond its equal ceiling.')

const roseSupport = scoreVerseMomentum([
  event(VERSE_EVENT_TYPES.GIFT, 'supporter-1', 500, { giftId: 'rose' }),
])
const wyvernSupport = scoreVerseMomentum([
  event(VERSE_EVENT_TYPES.GIFT, 'supporter-1', 500, { giftId: 'blood-wyvern' }),
])
assert.equal(roseSupport.score, wyvernSupport.score, 'Gift type must never change ranking power when eligible coin value is equal.')

const baseRoom = [
  ...viewers(10),
  verifiedTap('viewer-1', 100),
  event(VERSE_EVENT_TYPES.GIFT, 'viewer-2', 500),
]
const baseScore = scoreVerseMomentum(baseRoom)
const socialNoise = scoreVerseMomentum([
  ...baseRoom,
  ...Array.from({ length: 200 }, (_, index) => event(VERSE_EVENT_TYPES.FOLLOW, `follow-${index + 1}`)),
  ...Array.from({ length: 200 }, (_, index) => event(VERSE_EVENT_TYPES.COMMENT, `comment-${index + 1}`)),
  ...Array.from({ length: 20 }, (_, index) => event(VERSE_EVENT_TYPES.WATCH_TIME, `viewer-${index + 1}`, 3600)),
])
assert.equal(socialNoise.score, baseScore.score, 'Follows, comments, and watch-time telemetry must not add ranking points in FAM-ALGO-1.2.')

const allThree = scoreVerseMomentum([
  ...viewers(VERSE_MOMENTUM_TARGETS.audienceViewers),
  verifiedTap('viewer-1', VERSE_MOMENTUM_TARGETS.taps),
  event(VERSE_EVENT_TYPES.GIFT, 'supporter-1', VERSE_MOMENTUM_TARGETS.giftCoins),
])
assert.equal(allThree.score, 100, 'All three full lanes must produce a 100 Verse Momentum score.')

for (const result of [audienceOnly, tapsOnly, giftsOnly, unverifiedTap, cappedGift, baseScore, socialNoise, allThree]) {
  assert.ok(result.score >= 0 && result.score <= 100, 'Verse Momentum score must stay between 0 and 100.')
}

const status = getVerseMomentumStatus()
assert.equal(status.rankingEnabled, false)
assert.equal(status.eventSignalCount, 7)
assert.equal(status.rankingSignalCount, 3)
assert.deepEqual(status.rankingLanes, ['audience', 'taps', 'gifts'])

console.log(`Verse Momentum checks passed (${status.version}): ranking OFF, equal lanes locked, unlimited verified taps, followers excluded.`)

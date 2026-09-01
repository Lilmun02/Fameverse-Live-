import assert from 'node:assert/strict'
import { VERSE_EVENT_TYPES, isVerseEventType } from '../src/features/ranking/eventContract.js'
import {
  MAX_RANKING_TAPS_PER_USER,
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
const viewers = (count) => Array.from({ length: count }, (_, index) => event(VERSE_EVENT_TYPES.VIEWER_JOIN, `viewer-${index + 1}`))

assert.equal(RANKING_ENABLED, false, 'Verse Momentum must remain disconnected from Discover until real Live ranking is approved.')
assert.equal(VERSE_MOMENTUM_VERSION, 'FAM-ALGO-1.1')
assert.equal(scoreVerseMomentum([]).score, 0)
assert.equal(isVerseEventType('unfollow'), false, 'Unfollow must never become a ranking event by accident.')

const audienceOnly = scoreVerseMomentum(viewers(VERSE_MOMENTUM_TARGETS.audienceViewers))
const tapsOnly = scoreVerseMomentum([
  ...viewers(100),
  ...Array.from({ length: 100 }, (_, index) => event(VERSE_EVENT_TYPES.TAP, `viewer-${index + 1}`, MAX_RANKING_TAPS_PER_USER)),
])
const giftsOnly = scoreVerseMomentum([
  event(VERSE_EVENT_TYPES.GIFT, 'supporter-1', VERSE_MOMENTUM_TARGETS.giftCoins),
])

assert.equal(audienceOnly.breakdown.audience, 100, 'Audience lane must reach the same 100-point ceiling.')
assert.equal(tapsOnly.breakdown.taps, 100, 'Tap lane must reach the same 100-point ceiling.')
assert.equal(giftsOnly.breakdown.gifts, 100, 'Gift lane must reach the same 100-point ceiling.')
assert.equal(audienceOnly.score, tapsOnly.score, 'Audience and Tap lanes must have equal maximum push.')
assert.equal(tapsOnly.score, giftsOnly.score, 'Tap and Gift lanes must have equal maximum push.')

const oneUserTapSpam = scoreVerseMomentum([
  ...viewers(1),
  event(VERSE_EVENT_TYPES.TAP, 'viewer-1', 100000),
])
const tapAggregate = aggregateVerseEvents([
  ...viewers(1),
  event(VERSE_EVENT_TYPES.TAP, 'viewer-1', 100000),
])
assert.equal(tapAggregate.taps, MAX_RANKING_TAPS_PER_USER, 'Per-user eligible tap cap failed.')
assert.ok(oneUserTapSpam.breakdown.taps < 5, 'One tapper must not be able to fill the Tap lane.')

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
  event(VERSE_EVENT_TYPES.TAP, 'viewer-1', 100),
  event(VERSE_EVENT_TYPES.GIFT, 'viewer-2', 500),
]
const baseScore = scoreVerseMomentum(baseRoom)
const socialNoise = scoreVerseMomentum([
  ...baseRoom,
  ...Array.from({ length: 200 }, (_, index) => event(VERSE_EVENT_TYPES.FOLLOW, `follow-${index + 1}`)),
  ...Array.from({ length: 200 }, (_, index) => event(VERSE_EVENT_TYPES.COMMENT, `comment-${index + 1}`)),
  ...Array.from({ length: 20 }, (_, index) => event(VERSE_EVENT_TYPES.WATCH_TIME, `viewer-${index + 1}`, 3600)),
])
assert.equal(socialNoise.score, baseScore.score, 'Follows, comments, and watch-time telemetry must not add ranking points in FAM-ALGO-1.1.')

const allThree = scoreVerseMomentum([
  ...viewers(VERSE_MOMENTUM_TARGETS.audienceViewers),
  ...Array.from({ length: 100 }, (_, index) => event(VERSE_EVENT_TYPES.TAP, `viewer-${index + 1}`, MAX_RANKING_TAPS_PER_USER)),
  event(VERSE_EVENT_TYPES.GIFT, 'supporter-1', VERSE_MOMENTUM_TARGETS.giftCoins),
])
assert.equal(allThree.score, 100, 'All three full lanes must produce a 100 Verse Momentum score.')

for (const result of [audienceOnly, tapsOnly, giftsOnly, oneUserTapSpam, cappedGift, baseScore, socialNoise, allThree]) {
  assert.ok(result.score >= 0 && result.score <= 100, 'Verse Momentum score must stay between 0 and 100.')
}

const status = getVerseMomentumStatus()
assert.equal(status.rankingEnabled, false)
assert.equal(status.eventSignalCount, 7)
assert.equal(status.rankingSignalCount, 3)
assert.deepEqual(status.rankingLanes, ['audience', 'taps', 'gifts'])

console.log(`Verse Momentum checks passed (${status.version}): ranking OFF, three equal lanes locked, followers excluded.`)

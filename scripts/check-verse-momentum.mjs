import assert from 'node:assert/strict'
import { VERSE_EVENT_TYPES } from '../src/features/ranking/eventContract.js'
import {
  MAX_RANKING_TAPS_PER_USER,
  RANKING_ENABLED,
  VERSE_MOMENTUM_VERSION,
} from '../src/features/ranking/verseMomentumConfig.js'
import {
  aggregateVerseEvents,
  getVerseMomentumStatus,
  scoreVerseMomentum,
} from '../src/features/ranking/verseMomentum.js'

const event = (type, actorId, value = 1) => ({ type, actorId, value })
const viewers = (count, watchSeconds = 0) => Array.from({ length: count }, (_, index) => {
  const actorId = `viewer-${index + 1}`
  const entries = [event(VERSE_EVENT_TYPES.VIEWER_JOIN, actorId)]
  if (watchSeconds > 0) entries.push(event(VERSE_EVENT_TYPES.WATCH_TIME, actorId, watchSeconds))
  return entries
}).flat()

assert.equal(RANKING_ENABLED, false, 'FAM Algorithm 1 must not rank Discover yet.')
assert.equal(VERSE_MOMENTUM_VERSION, 'FAM-ALGO-1')
assert.equal(scoreVerseMomentum([]).score, 0)

const tapSpam = scoreVerseMomentum([
  ...viewers(1),
  event(VERSE_EVENT_TYPES.TAP, 'viewer-1', 100000),
])
const retainedRoom = scoreVerseMomentum(viewers(20, 180))
assert.ok(retainedRoom.score > tapSpam.score, 'Retention must beat one-user tap spam.')

const tapAggregate = aggregateVerseEvents([
  ...viewers(1),
  event(VERSE_EVENT_TYPES.TAP, 'viewer-1', 100000),
])
assert.equal(tapAggregate.taps, MAX_RANKING_TAPS_PER_USER, 'Per-user tap ranking cap failed.')

const whaleOnly = scoreVerseMomentum([
  ...viewers(2, 10),
  event(VERSE_EVENT_TYPES.GIFT, 'viewer-1', 25000),
])
const healthyCommunity = scoreVerseMomentum([
  ...viewers(30, 180),
  ...Array.from({ length: 10 }, (_, index) => event(VERSE_EVENT_TYPES.COMMENT, `viewer-${index + 1}`)),
  ...Array.from({ length: 5 }, (_, index) => event(VERSE_EVENT_TYPES.FOLLOW, `viewer-${index + 1}`)),
])
assert.ok(healthyCommunity.score > whaleOnly.score, 'Gift spend must not buy the top ranking by itself.')

const healthyEvents = [
  ...viewers(20, 150),
  ...Array.from({ length: 6 }, (_, index) => event(VERSE_EVENT_TYPES.COMMENT, `viewer-${index + 1}`)),
]
const healthy = scoreVerseMomentum(healthyEvents)
const reported = scoreVerseMomentum([
  ...healthyEvents,
  ...Array.from({ length: 4 }, (_, index) => event(VERSE_EVENT_TYPES.REPORT, `viewer-${index + 1}`)),
])
assert.ok(reported.score < healthy.score, 'Reports must reduce Verse Momentum.')

for (const result of [tapSpam, retainedRoom, whaleOnly, healthyCommunity, healthy, reported]) {
  assert.ok(result.score >= 0 && result.score <= 100, 'Verse Momentum score must stay between 0 and 100.')
}

const status = getVerseMomentumStatus()
assert.equal(status.rankingEnabled, false)
assert.equal(status.signalCount, 7)

console.log(`Verse Momentum checks passed (${status.version}): ranking OFF, ${status.signalCount} signals guarded.`)

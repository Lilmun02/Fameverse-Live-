import assert from 'node:assert/strict'
import { TAP_INTEGRITY_VERSION } from '../src/features/taps/tapIntegrityConfig.js'
import {
  assessTapBatch,
  createIntegrityVerifiedTapEvent,
  getTapIntegrityStatus,
} from '../src/features/taps/tapIntegrity.js'

const base = {
  actorId: 'viewer-1',
  sessionId: 'live-1',
  batchId: 'batch-1',
  sessionActive: true,
  replayed: false,
}

const manualLike = assessTapBatch({
  ...base,
  timestamps: [0, 82, 171, 265, 354, 455, 543, 646, 735, 835, 929, 1030, 1121, 1224, 1317, 1418, 1510, 1614, 1705, 1806],
})
assert.equal(manualLike.classification, 'trusted', 'Irregular plausible tapping should remain fully trusted.')
assert.equal(manualLike.eligibleTapCount, manualLike.rawTapCount)

const periodic = assessTapBatch({
  ...base,
  batchId: 'batch-2',
  timestamps: Array.from({ length: 30 }, (_, index) => index * 100),
})
assert.equal(periodic.classification, 'reduced', 'Near-perfect timing should reduce confidence without banning the user.')
assert.ok(periodic.eligibleTapCount > 0 && periodic.eligibleTapCount < periodic.rawTapCount)

const impossible = assessTapBatch({
  ...base,
  batchId: 'batch-3',
  timestamps: Array.from({ length: 40 }, (_, index) => index),
})
assert.equal(impossible.classification, 'rejected', 'Impossible request rates must not reach ranking.')
assert.equal(impossible.eligibleTapCount, 0)

const replayed = assessTapBatch({ ...base, batchId: 'batch-4', replayed: true, timestamps: [0, 100, 220] })
assert.equal(replayed.eligibleTapCount, 0, 'Replayed batches must be rejected.')

const inactive = assessTapBatch({ ...base, batchId: 'batch-5', sessionActive: false, timestamps: [0, 100, 220] })
assert.equal(inactive.eligibleTapCount, 0, 'Taps from an inactive Live session must be rejected.')

const highVolume = assessTapBatch({
  ...base,
  batchId: 'batch-6',
  timestamps: Array.from({ length: 500 }, (_, index) => (index * 100) + ((index % 7) * 11)),
})
assert.equal(highVolume.rawTapCount, 500, 'Raw Fame Taps must remain unlimited.')
assert.ok(highVolume.eligibleTapCount > 250, 'Tap Integrity must replace the old 250-tap hard cap.')

const verifiedEvent = createIntegrityVerifiedTapEvent({
  ...base,
  batchId: 'batch-7',
  timestamps: [0, 82, 171, 265, 354, 455, 543, 646, 735, 835, 929, 1030, 1121, 1224],
})
assert.equal(verifiedEvent?.type, 'tap')
assert.equal(verifiedEvent?.integrityVerified, true)
assert.ok(verifiedEvent?.value > 0)

const rejectedEvent = createIntegrityVerifiedTapEvent({ ...base, batchId: 'batch-8', replayed: true, timestamps: [0, 100] })
assert.equal(rejectedEvent, null)

const status = getTapIntegrityStatus()
assert.equal(status.version, TAP_INTEGRITY_VERSION)
assert.equal(status.rawTapCap, null)
assert.equal(status.classificationOnly, true)
assert.equal(status.liveCaptureConnected, false)

console.log(`Tap Integrity checks passed (${status.version}): no raw tap cap, confidence classification active, replay/impossible traffic rejected.`)

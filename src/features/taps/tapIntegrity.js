import { TAP_INTEGRITY_RULES, TAP_INTEGRITY_VERSION } from './tapIntegrityConfig.js'

const clamp = (value, min = 0, max = 1) => Math.min(max, Math.max(min, value))
const round = (value, digits = 2) => Number(value.toFixed(digits))

function reject(rawTapCount, reasons, extras = {}) {
  return Object.freeze({
    version: TAP_INTEGRITY_VERSION,
    classification: 'rejected',
    trustScore: 0,
    rawTapCount,
    eligibleTapCount: 0,
    tapsPerSecond: extras.tapsPerSecond || 0,
    intervalCv: extras.intervalCv ?? null,
    reasons: Object.freeze(reasons),
  })
}

function coefficientOfVariation(intervals) {
  if (!intervals.length) return null
  const mean = intervals.reduce((total, value) => total + value, 0) / intervals.length
  if (mean <= 0) return 0
  const variance = intervals.reduce((total, value) => total + ((value - mean) ** 2), 0) / intervals.length
  return Math.sqrt(variance) / mean
}

export function assessTapBatch(batch = {}) {
  const actorId = String(batch.actorId || '').trim()
  const sessionId = String(batch.sessionId || '').trim()
  const batchId = String(batch.batchId || '').trim()
  const timestamps = Array.isArray(batch.timestamps) ? batch.timestamps.map(Number) : []
  const rawTapCount = timestamps.length
  const reasons = []

  if (!actorId || !sessionId || !batchId) return reject(rawTapCount, ['missing_identity'])
  if (batch.sessionActive !== true) return reject(rawTapCount, ['inactive_live_session'])
  if (batch.replayed === true) return reject(rawTapCount, ['replayed_batch'])
  if (!rawTapCount) return reject(0, ['empty_batch'])
  if (timestamps.some((value) => !Number.isFinite(value) || value < 0)) return reject(rawTapCount, ['invalid_timestamp'])

  for (let index = 1; index < timestamps.length; index += 1) {
    if (timestamps[index] <= timestamps[index - 1]) return reject(rawTapCount, ['non_monotonic_timestamps'])
  }

  const intervals = timestamps.slice(1).map((value, index) => value - timestamps[index])
  const durationMs = rawTapCount > 1 ? timestamps.at(-1) - timestamps[0] : 0
  const tapsPerSecond = durationMs > 0 ? ((rawTapCount - 1) / durationMs) * 1000 : 0
  const intervalCv = coefficientOfVariation(intervals)
  const rules = TAP_INTEGRITY_RULES

  if (tapsPerSecond > rules.impossibleTapsPerSecond) {
    return reject(rawTapCount, ['impossible_rate'], { tapsPerSecond: round(tapsPerSecond), intervalCv })
  }

  let trustScore = 1

  if (tapsPerSecond > rules.highRateTapsPerSecond) {
    trustScore *= rules.highRateMultiplier
    reasons.push('very_high_rate')
  }

  if (rawTapCount >= rules.minimumPatternTaps && intervalCv !== null) {
    if (intervalCv <= rules.nearPerfectIntervalCv) {
      trustScore *= rules.nearPerfectMultiplier
      reasons.push('near_perfect_timing')
    } else if (intervalCv <= rules.repetitiveIntervalCv) {
      trustScore *= rules.repetitiveMultiplier
      reasons.push('highly_repetitive_timing')
    }
  }

  trustScore = round(clamp(trustScore))
  const eligibleTapCount = Math.round(rawTapCount * trustScore)

  return Object.freeze({
    version: TAP_INTEGRITY_VERSION,
    classification: trustScore >= 0.9 ? 'trusted' : 'reduced',
    trustScore,
    rawTapCount,
    eligibleTapCount,
    tapsPerSecond: round(tapsPerSecond),
    intervalCv: intervalCv === null ? null : round(intervalCv, 4),
    reasons: Object.freeze(reasons),
  })
}

export function createIntegrityVerifiedTapEvent(batch = {}) {
  const assessment = assessTapBatch(batch)
  if (assessment.eligibleTapCount < 1) return null

  return Object.freeze({
    type: 'tap',
    actorId: String(batch.actorId).trim(),
    value: assessment.eligibleTapCount,
    integrityVerified: true,
    integrityVersion: TAP_INTEGRITY_VERSION,
    sessionId: String(batch.sessionId).trim(),
    batchId: String(batch.batchId).trim(),
  })
}

export function getTapIntegrityStatus() {
  return Object.freeze({
    version: TAP_INTEGRITY_VERSION,
    rawTapCap: null,
    classificationOnly: true,
    liveCaptureConnected: false,
  })
}

export const TAP_INTEGRITY_VERSION = 'FAM-TAP-1'

// Conservative beta thresholds. They classify confidence; they do not accuse or ban users.
export const TAP_INTEGRITY_RULES = Object.freeze({
  minimumPatternTaps: 12,
  highRateTapsPerSecond: 15,
  impossibleTapsPerSecond: 30,
  nearPerfectIntervalCv: 0.015,
  repetitiveIntervalCv: 0.04,
  highRateMultiplier: 0.75,
  nearPerfectMultiplier: 0.5,
  repetitiveMultiplier: 0.8,
})

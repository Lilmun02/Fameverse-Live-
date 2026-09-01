export const VERSE_MOMENTUM_VERSION = 'FAM-ALGO-1.2'
export const RANKING_ENABLED = false

// Three equal ranking lanes. These are beta tuning values, not permanent economy rules.
export const VERSE_RANKING_LANES = Object.freeze(['audience', 'taps', 'gifts'])
export const VERSE_MOMENTUM_LANE_MAX = 100

// Tap volume is no longer capped per user. Tap Integrity decides eligible tap value before ranking.

// Gift fairness comes from the lane ceiling, not from making big support meaningless.
// A large supporter can fill the Gift lane, but can never push it beyond 100.
export const MAX_RANKING_GIFT_COINS_PER_USER = 1000000

// These remain telemetry-only for future systems. They do not add ranking points in FAM-ALGO-1.2.
export const MAX_RANKING_COMMENTS_PER_USER = 20
export const MAX_WATCH_SECONDS_PER_USER = 3600

export const VERSE_MOMENTUM_TARGETS = Object.freeze({
  audienceViewers: 100,
  taps: 25000,
  giftCoins: 10000,
})

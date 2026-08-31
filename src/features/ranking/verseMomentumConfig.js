export const VERSE_MOMENTUM_VERSION = 'FAM-ALGO-1'
export const RANKING_ENABLED = false

export const MAX_RANKING_TAPS_PER_USER = 250
export const MAX_RANKING_GIFT_COINS_PER_USER = 1000
export const MAX_RANKING_COMMENTS_PER_USER = 20
export const MAX_WATCH_SECONDS_PER_USER = 3600

export const VERSE_MOMENTUM_WEIGHTS = Object.freeze({
  retention: 35,
  viewerDepth: 20,
  conversation: 15,
  follows: 15,
  taps: 10,
  gifts: 5,
})

export const VERSE_MOMENTUM_TARGETS = Object.freeze({
  retentionSeconds: 180,
  uniqueViewers: 100,
  commenterCoverage: 0.35,
  commentsPerViewer: 2,
  followRate: 0.15,
  tapperCoverage: 0.4,
  tapsPerTapper: 50,
  giftCoins: 5000,
  reportRate: 0.05,
})

export const MAX_REPORT_PENALTY = 30

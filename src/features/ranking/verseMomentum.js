import { VERSE_EVENT_TYPE_COUNT, VERSE_EVENT_TYPES, normalizeVerseEvent } from './eventContract.js'
import {
  MAX_RANKING_COMMENTS_PER_USER,
  MAX_RANKING_GIFT_COINS_PER_USER,
  MAX_RANKING_TAPS_PER_USER,
  MAX_REPORT_PENALTY,
  MAX_WATCH_SECONDS_PER_USER,
  RANKING_ENABLED,
  VERSE_MOMENTUM_TARGETS,
  VERSE_MOMENTUM_VERSION,
  VERSE_MOMENTUM_WEIGHTS,
} from './verseMomentumConfig.js'

const clamp = (value, min = 0, max = 1) => Math.min(max, Math.max(min, value))
const round = (value) => Math.round(value * 10) / 10
const sumMap = (map) => [...map.values()].reduce((total, value) => total + value, 0)

function addCapped(map, key, value, cap) {
  map.set(key, Math.min(cap, (map.get(key) || 0) + value))
}

export function aggregateVerseEvents(events = []) {
  const viewers = new Set()
  const watchByUser = new Map()
  const commentsByUser = new Map()
  const tapsByUser = new Map()
  const giftsByUser = new Map()
  const followActors = new Set()
  const reportActors = new Set()

  for (const rawEvent of events) {
    const event = normalizeVerseEvent(rawEvent)
    if (!event) continue

    switch (event.type) {
      case VERSE_EVENT_TYPES.VIEWER_JOIN:
        viewers.add(event.actorId)
        break
      case VERSE_EVENT_TYPES.WATCH_TIME:
        addCapped(watchByUser, event.actorId, event.value, MAX_WATCH_SECONDS_PER_USER)
        break
      case VERSE_EVENT_TYPES.COMMENT:
        addCapped(commentsByUser, event.actorId, event.value, MAX_RANKING_COMMENTS_PER_USER)
        break
      case VERSE_EVENT_TYPES.FOLLOW:
        followActors.add(event.actorId)
        break
      case VERSE_EVENT_TYPES.TAP:
        addCapped(tapsByUser, event.actorId, event.value, MAX_RANKING_TAPS_PER_USER)
        break
      case VERSE_EVENT_TYPES.GIFT:
        addCapped(giftsByUser, event.actorId, event.value, MAX_RANKING_GIFT_COINS_PER_USER)
        break
      case VERSE_EVENT_TYPES.REPORT:
        reportActors.add(event.actorId)
        break
      default:
        break
    }
  }

  const uniqueViewers = viewers.size
  const watchSeconds = sumMap(watchByUser)
  const comments = sumMap(commentsByUser)
  const taps = sumMap(tapsByUser)
  const giftCoins = sumMap(giftsByUser)

  return Object.freeze({
    uniqueViewers,
    watchSeconds,
    averageWatchSeconds: uniqueViewers > 0 ? watchSeconds / uniqueViewers : 0,
    comments,
    uniqueCommenters: commentsByUser.size,
    follows: followActors.size,
    taps,
    uniqueTappers: tapsByUser.size,
    giftCoins,
    uniqueGifters: giftsByUser.size,
    reports: reportActors.size,
  })
}

function logProgress(value, target) {
  if (value <= 0 || target <= 0) return 0
  return clamp(Math.log1p(value) / Math.log1p(target))
}

export function scoreVerseMomentum(events = []) {
  const signals = aggregateVerseEvents(events)
  const targets = VERSE_MOMENTUM_TARGETS
  const weights = VERSE_MOMENTUM_WEIGHTS
  const viewers = Math.max(signals.uniqueViewers, 1)

  const retention = weights.retention * clamp(signals.averageWatchSeconds / targets.retentionSeconds)
  const viewerDepth = weights.viewerDepth * logProgress(signals.uniqueViewers, targets.uniqueViewers)

  const commenterCoverage = clamp((signals.uniqueCommenters / viewers) / targets.commenterCoverage)
  const commentDensity = clamp((signals.comments / viewers) / targets.commentsPerViewer)
  const conversation = weights.conversation * ((commenterCoverage + commentDensity) / 2)

  const follows = weights.follows * clamp((signals.follows / viewers) / targets.followRate)

  const tapperCoverage = clamp((signals.uniqueTappers / viewers) / targets.tapperCoverage)
  const tapsPerTapper = signals.uniqueTappers > 0 ? signals.taps / signals.uniqueTappers : 0
  const tapIntensity = clamp(tapsPerTapper / targets.tapsPerTapper)
  const taps = weights.taps * ((tapperCoverage + tapIntensity) / 2)

  const gifts = weights.gifts * logProgress(signals.giftCoins, targets.giftCoins)
  const reportRate = signals.reports / viewers
  const reportPenalty = MAX_REPORT_PENALTY * clamp(reportRate / targets.reportRate)

  const breakdown = Object.freeze({
    retention: round(retention),
    viewerDepth: round(viewerDepth),
    conversation: round(conversation),
    follows: round(follows),
    taps: round(taps),
    gifts: round(gifts),
    reportPenalty: round(reportPenalty),
  })

  const positiveTotal = retention + viewerDepth + conversation + follows + taps + gifts
  return Object.freeze({
    score: round(clamp(positiveTotal - reportPenalty, 0, 100)),
    breakdown,
    signals,
  })
}

export function getVerseMomentumStatus() {
  return Object.freeze({
    version: VERSE_MOMENTUM_VERSION,
    rankingEnabled: RANKING_ENABLED,
    signalCount: VERSE_EVENT_TYPE_COUNT,
  })
}

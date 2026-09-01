import { VERSE_EVENT_TYPE_COUNT, VERSE_EVENT_TYPES, normalizeVerseEvent } from './eventContract.js'
import {
  MAX_RANKING_COMMENTS_PER_USER,
  MAX_RANKING_GIFT_COINS_PER_USER,
  MAX_WATCH_SECONDS_PER_USER,
  RANKING_ENABLED,
  VERSE_MOMENTUM_LANE_MAX,
  VERSE_MOMENTUM_TARGETS,
  VERSE_MOMENTUM_VERSION,
  VERSE_RANKING_LANES,
} from './verseMomentumConfig.js'

const clamp = (value, min = 0, max = 1) => Math.min(max, Math.max(min, value))
const round = (value) => Math.round(value * 10) / 10
const sumMap = (map) => [...map.values()].reduce((total, value) => total + value, 0)

function addCapped(map, key, value, cap) {
  map.set(key, Math.min(cap, (map.get(key) || 0) + value))
}

function addValue(map, key, value) {
  map.set(key, (map.get(key) || 0) + value)
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
        if (event.integrityVerified) addValue(tapsByUser, event.actorId, event.value)
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

  return Object.freeze({
    uniqueViewers: viewers.size,
    watchSeconds: sumMap(watchByUser),
    comments: sumMap(commentsByUser),
    uniqueCommenters: commentsByUser.size,
    follows: followActors.size,
    taps: sumMap(tapsByUser),
    uniqueTappers: tapsByUser.size,
    giftCoins: sumMap(giftsByUser),
    uniqueGifters: giftsByUser.size,
    reports: reportActors.size,
  })
}

function laneScore(value, target) {
  return VERSE_MOMENTUM_LANE_MAX * clamp(value / target)
}

export function scoreVerseMomentum(events = []) {
  const signals = aggregateVerseEvents(events)
  const targets = VERSE_MOMENTUM_TARGETS

  const audience = laneScore(signals.uniqueViewers, targets.audienceViewers)
  const taps = laneScore(signals.taps, targets.taps)
  const gifts = laneScore(signals.giftCoins, targets.giftCoins)

  const breakdown = Object.freeze({
    audience: round(audience),
    taps: round(taps),
    gifts: round(gifts),
  })

  return Object.freeze({
    score: round((audience + taps + gifts) / VERSE_RANKING_LANES.length),
    breakdown,
    signals,
  })
}

export function getVerseMomentumStatus() {
  return Object.freeze({
    version: VERSE_MOMENTUM_VERSION,
    rankingEnabled: RANKING_ENABLED,
    eventSignalCount: VERSE_EVENT_TYPE_COUNT,
    rankingSignalCount: VERSE_RANKING_LANES.length,
    rankingLanes: VERSE_RANKING_LANES,
  })
}

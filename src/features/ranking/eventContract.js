export const VERSE_EVENT_TYPES = Object.freeze({
  VIEWER_JOIN: 'viewer_join',
  WATCH_TIME: 'watch_time',
  TAP: 'tap',
  COMMENT: 'comment',
  FOLLOW: 'follow',
  GIFT: 'gift',
  REPORT: 'report',
})

const VALID_EVENT_TYPES = new Set(Object.values(VERSE_EVENT_TYPES))

function positiveNumber(value, fallback = 1) {
  const number = Number(value)
  return Number.isFinite(number) && number > 0 ? number : fallback
}

export function normalizeVerseEvent(event) {
  if (!event || !VALID_EVENT_TYPES.has(event.type)) return null

  const actorId = String(event.actorId || '').trim()
  if (!actorId) return null

  return Object.freeze({
    type: event.type,
    actorId,
    value: positiveNumber(event.value),
    integrityVerified: event.type === VERSE_EVENT_TYPES.TAP ? event.integrityVerified === true : undefined,
  })
}

export function isVerseEventType(type) {
  return VALID_EVENT_TYPES.has(type)
}

export const VERSE_EVENT_TYPE_COUNT = VALID_EVENT_TYPES.size

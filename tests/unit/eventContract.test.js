import { describe, expect, it } from 'vitest'
import {
  VERSE_EVENT_TYPE_COUNT,
  VERSE_EVENT_TYPES,
  isVerseEventType,
  normalizeVerseEvent,
} from '../../src/features/ranking/eventContract.js'

describe('Verse event contract', () => {
  it('rejects unknown event types and missing actors', () => {
    expect(normalizeVerseEvent({ type: 'made_up', actorId: 'user-1' })).toBeNull()
    expect(normalizeVerseEvent({ type: VERSE_EVENT_TYPES.COMMENT, actorId: '   ' })).toBeNull()
  })

  it('normalizes actor ids and invalid values safely', () => {
    expect(normalizeVerseEvent({
      type: VERSE_EVENT_TYPES.GIFT,
      actorId: '  user-1  ',
      value: -50,
    })).toEqual({
      type: VERSE_EVENT_TYPES.GIFT,
      actorId: 'user-1',
      value: 1,
      integrityVerified: undefined,
    })
  })

  it('only marks tap integrity verified when explicitly true', () => {
    expect(normalizeVerseEvent({
      type: VERSE_EVENT_TYPES.TAP,
      actorId: 'user-2',
      value: 5,
      integrityVerified: true,
    })?.integrityVerified).toBe(true)

    expect(normalizeVerseEvent({
      type: VERSE_EVENT_TYPES.TAP,
      actorId: 'user-2',
      value: 5,
      integrityVerified: 'true',
    })?.integrityVerified).toBe(false)
  })

  it('keeps the published event registry internally consistent', () => {
    expect(VERSE_EVENT_TYPE_COUNT).toBe(Object.keys(VERSE_EVENT_TYPES).length)
    expect(isVerseEventType(VERSE_EVENT_TYPES.VIEWER_JOIN)).toBe(true)
  })
})

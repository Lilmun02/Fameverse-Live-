import { describe, expect, it } from 'vitest'
import { cleanUsername } from '../../src/utils/profile.js'

describe('cleanUsername', () => {
  it('normalizes case, @ prefix, spaces, and punctuation', () => {
    expect(cleanUsername('@Fame Verse!!')).toBe('fameverse')
  })

  it('keeps underscores and limits usernames to 24 characters', () => {
    const value = cleanUsername('@THIS_is_a_really_really_long_username')
    expect(value).toBe('this_is_a_really_really_')
    expect(value).toHaveLength(24)
  })
})

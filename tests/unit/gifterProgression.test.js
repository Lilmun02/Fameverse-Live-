import { describe, expect, it } from 'vitest'
import { getGifterBadgeForLevel } from '../../src/features/badges/gifterBadgeSystem.js'
import {
  computeGifterLevel,
  getGifterProgress,
  gifterLevelRequirement,
} from '../../src/features/badges/gifterProgression.js'

describe('gifter progression', () => {
  it('keeps the approved early progression anchors', () => {
    expect(gifterLevelRequirement(2)).toBe(100)
    expect(gifterLevelRequirement(5)).toBe(1000)
    expect(gifterLevelRequirement(10)).toBe(10000)
    expect(gifterLevelRequirement(11)).toBe(15000)
    expect(computeGifterLevel(14999)).toBe(10)
    expect(computeGifterLevel(15000)).toBe(11)
  })

  it('keeps the approved mid and late progression anchors', () => {
    expect(gifterLevelRequirement(20)).toBe(150000)
    expect(gifterLevelRequirement(30)).toBe(500000)
    expect(gifterLevelRequirement(50)).toBe(2500000)
    expect(gifterLevelRequirement(75)).toBe(10000000)
    expect(gifterLevelRequirement(99)).toBe(50000000)
  })

  it('reports progress without exposing another badge', () => {
    const progress = getGifterProgress(15000)
    expect(progress.level).toBe(11)
    expect(progress.nextLevel).toBe(12)
    expect(progress.coinsToNext).toBe(7500)
    expect(progress.progress).toBe(0)
  })
})

describe('gifter badge ladder', () => {
  it('maps levels to the approved earned badge tiers', () => {
    expect(getGifterBadgeForLevel(1).label).toBe('Spark Gifter')
    expect(getGifterBadgeForLevel(5).label).toBe('Bronze Gifter')
    expect(getGifterBadgeForLevel(11).label).toBe('Silver Gifter')
    expect(getGifterBadgeForLevel(20).label).toBe('Gold Gifter')
    expect(getGifterBadgeForLevel(30).label).toBe('Platinum Gifter')
    expect(getGifterBadgeForLevel(50).label).toBe('Diamond Gifter')
    expect(getGifterBadgeForLevel(70).label).toBe('Royal Gifter')
    expect(getGifterBadgeForLevel(85).label).toBe('Legendary Gifter')
    expect(getGifterBadgeForLevel(99).label).toBe('Fame Icon')
  })
})

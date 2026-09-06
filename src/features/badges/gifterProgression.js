export const GIFTER_LEVEL_THRESHOLDS = Object.freeze([
  0, 100, 250, 500, 1000, 2000, 3500, 5000, 7500, 10000,
  15000, 22500, 32500, 45000, 60000, 72500, 87500, 105000, 125000, 150000,
  170000, 190000, 215000, 245000, 275000, 310000, 350000, 395000, 445000, 500000,
  540000, 585000, 635000, 690000, 750000, 810000, 880000, 950000, 1025000, 1125000,
  1200000, 1325000, 1425000, 1550000, 1675000, 1800000, 1975000, 2125000, 2300000, 2500000,
  2650000, 2800000, 2950000, 3125000, 3300000, 3475000, 3675000, 3900000, 4125000, 4350000,
  4600000, 4875000, 5150000, 5425000, 5750000, 6075000, 6425000, 6775000, 7175000, 7575000,
  8000000, 8475000, 8950000, 9450000, 10000000, 10700000, 11400000, 12200000, 13100000, 14000000,
  15000000, 16000000, 17100000, 18300000, 19600000, 20900000, 22400000, 23900000, 25600000, 27300000,
  29200000, 31300000, 33400000, 35800000, 38200000, 40900000, 43700000, 46800000, 50000000,
])

export function gifterLevelRequirement(level = 1) {
  const normalizedLevel = Math.min(99, Math.max(1, Math.floor(Number(level) || 1)))
  return GIFTER_LEVEL_THRESHOLDS[normalizedLevel - 1]
}

export function computeGifterLevel(totalCoins = 0) {
  const normalized = Math.max(0, Number(totalCoins) || 0)
  let low = 0
  let high = GIFTER_LEVEL_THRESHOLDS.length - 1
  let matchedIndex = 0

  while (low <= high) {
    const middle = Math.floor((low + high) / 2)
    if (GIFTER_LEVEL_THRESHOLDS[middle] <= normalized) {
      matchedIndex = middle
      low = middle + 1
    } else {
      high = middle - 1
    }
  }

  return matchedIndex + 1
}

export function getGifterProgress(totalCoins = 0) {
  const normalized = Math.max(0, Number(totalCoins) || 0)
  const level = computeGifterLevel(normalized)
  const currentRequirement = gifterLevelRequirement(level)
  const isMaxLevel = level >= 99
  const nextLevel = isMaxLevel ? null : level + 1
  const nextRequirement = isMaxLevel ? currentRequirement : gifterLevelRequirement(nextLevel)
  const range = Math.max(1, nextRequirement - currentRequirement)
  const progress = isMaxLevel
    ? 1
    : Math.min(1, Math.max(0, (normalized - currentRequirement) / range))

  return {
    level,
    currentRequirement,
    nextLevel,
    nextRequirement,
    coinsToNext: isMaxLevel ? 0 : Math.max(0, nextRequirement - normalized),
    progress,
    isMaxLevel,
  }
}

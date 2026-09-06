const GIFTER_BADGE_TIERS = Object.freeze([
  Object.freeze({ id: 'spark', label: 'Spark Gifter', icon: '✦', minLevel: 1, maxLevel: 4 }),
  Object.freeze({ id: 'bronze', label: 'Bronze Gifter', icon: '◆', minLevel: 5, maxLevel: 9 }),
  Object.freeze({ id: 'silver', label: 'Silver Gifter', icon: '✧', minLevel: 10, maxLevel: 19 }),
  Object.freeze({ id: 'gold', label: 'Gold Gifter', icon: '★', minLevel: 20, maxLevel: 29 }),
  Object.freeze({ id: 'platinum', label: 'Platinum Gifter', icon: '⬢', minLevel: 30, maxLevel: 49 }),
  Object.freeze({ id: 'diamond', label: 'Diamond Gifter', icon: '◇', minLevel: 50, maxLevel: 69 }),
  Object.freeze({ id: 'royal', label: 'Royal Gifter', icon: '♛', minLevel: 70, maxLevel: 84 }),
  Object.freeze({ id: 'legendary', label: 'Legendary Gifter', icon: '✪', minLevel: 85, maxLevel: 98 }),
  Object.freeze({ id: 'fame-icon', label: 'Fame Icon', icon: '♕', minLevel: 99, maxLevel: 99 }),
])

export function listGifterBadgeTiers() {
  return GIFTER_BADGE_TIERS
}

export function getGifterBadgeForLevel(level = 1) {
  const normalized = Math.min(99, Math.max(1, Math.floor(Number(level) || 1)))
  return GIFTER_BADGE_TIERS.find((tier) => normalized >= tier.minLevel && normalized <= tier.maxLevel)
    || GIFTER_BADGE_TIERS[0]
}

export function createGifterBadge(level = 1) {
  return getGifterBadgeForLevel(level)
}

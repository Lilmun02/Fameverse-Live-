export const GIFT_COMBO_WINDOW_MS = 2200
export const MAX_GIFT_COMBO = 10

export function createGiftComboState() {
  return { id: null, at: 0, count: 0 }
}

export function nextGiftCombo(previous, giftId, now = Date.now()) {
  const sameCombo = previous?.id === giftId && now - (previous?.at || 0) < GIFT_COMBO_WINDOW_MS
  return {
    id: giftId,
    at: now,
    count: Math.min(sameCombo ? (previous?.count || 0) + 1 : 1, MAX_GIFT_COMBO),
  }
}

export function nextOverlayCount(previousOverlay, giftId, now = Date.now()) {
  const sameCombo = previousOverlay?.id === giftId
    && now - (previousOverlay?.lastSentAt || 0) < GIFT_COMBO_WINDOW_MS
  return Math.min(sameCombo ? (previousOverlay?.count || 1) + 1 : 1, MAX_GIFT_COMBO)
}

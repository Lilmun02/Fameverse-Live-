export const GIFT_COMBO_WINDOW_MS = 2200

export function createGiftComboState() {
  return { id: null, at: 0, count: 0 }
}

export function nextGiftCombo(previous, giftId, quantity, now = Date.now()) {
  const sameCombo = previous?.id === giftId && now - (previous?.at || 0) < GIFT_COMBO_WINDOW_MS
  return {
    id: giftId,
    at: now,
    count: sameCombo ? (previous?.count || 0) + quantity : quantity,
  }
}

export function nextOverlayCount(previousOverlay, giftId, quantity, now = Date.now()) {
  const sameCombo = previousOverlay?.id === giftId
    && now - (previousOverlay?.lastSentAt || 0) < GIFT_COMBO_WINDOW_MS
  return sameCombo ? (previousOverlay?.count || 1) + quantity : quantity
}

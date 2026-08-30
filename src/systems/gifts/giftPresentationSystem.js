export const SIMPLE_GIFT_DURATION_MS = 1800
export const CINEMATIC_GIFT_DELAY_MS = 180
export const PREMIUM_REPEAT_DURATION_MS = 6800

export function giftActivityMessage(gift, quantity) {
  const activityEmoji = gift.activityEmoji || gift.emoji || '✦'
  return `${activityEmoji} sent ${gift.label}${quantity > 1 ? ` ×${quantity}` : ''}`
}

export function createGiftOverlay(gift, sender, count, now = Date.now()) {
  return {
    ...gift,
    sender,
    duration: SIMPLE_GIFT_DURATION_MS,
    count,
    lastSentAt: now,
  }
}

export function dispatchCinematicGift(gift, sender, comboCount) {
  document.dispatchEvent(new CustomEvent('fameverse:gift', {
    detail: { id: gift.rendererId, sender, comboCount },
  }))
}

export function scheduleGiftPresentation(callback, delayMs) {
  return window.setTimeout(callback, delayMs)
}

export function clearGiftPresentationTimer(timerId) {
  if (timerId != null) window.clearTimeout(timerId)
}

export function stopGiftRenderer() {
  window.FameverseGiftEngine?.stop?.()
}

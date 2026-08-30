export const SIMPLE_GIFT_DURATION_MS = 1800
export const CINEMATIC_GIFT_DELAY_MS = 180
export const PREMIUM_REPEAT_DURATION_MS = 6800

const pendingPresentationTimers = new Set()

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
  let timerId
  const run = () => {
    pendingPresentationTimers.delete(timerId)
    callback()
  }

  timerId = window.setTimeout(run, delayMs)
  pendingPresentationTimers.add(timerId)
  return timerId
}

export function clearGiftPresentationTimer(timerId) {
  if (timerId == null) return
  pendingPresentationTimers.delete(timerId)
  window.clearTimeout(timerId)
}

export function clearAllGiftPresentationTimers() {
  pendingPresentationTimers.forEach((timerId) => window.clearTimeout(timerId))
  pendingPresentationTimers.clear()
}

export function stopGiftRenderer() {
  window.FameverseGiftEngine?.stop?.()
}

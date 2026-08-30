export const SIMPLE_GIFT_DURATION_MS = 1800
export const CINEMATIC_GIFT_DELAY_MS = 180
export const PREMIUM_REPEAT_DURATION_MS = 6800

const pendingPresentationTimers = new Set()
const simpleGiftQueue = []
let activeSimpleGift = null
let simpleGiftTimer = null
let simpleGiftPaused = false

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
  clearSimpleGiftQueue()

  pendingPresentationTimers.forEach((timerId) => {
    window.clearTimeout(timerId)
  })

  pendingPresentationTimers.clear()
}

function playActiveSimpleGift() {
  if (!activeSimpleGift || simpleGiftPaused) return

  activeSimpleGift.showOverlay(activeSimpleGift.overlay)
  simpleGiftTimer = scheduleGiftPresentation(() => {
    simpleGiftTimer = null
    activeSimpleGift.hideOverlay()
    activeSimpleGift = null
    playNextSimpleGift()
  }, SIMPLE_GIFT_DURATION_MS)
}

function playNextSimpleGift() {
  if (activeSimpleGift || simpleGiftPaused) return

  const next = simpleGiftQueue.shift()
  if (!next) return

  activeSimpleGift = {
    ...next,
    overlay: createGiftOverlay(next.gift, next.sender, next.count),
  }
  playActiveSimpleGift()
}

export function enqueueSimpleGift(gift, sender, count, showOverlay, hideOverlay) {
  simpleGiftQueue.push({ gift, sender, count, showOverlay, hideOverlay })
  playNextSimpleGift()
}

export function pauseSimpleGiftPresentation() {
  simpleGiftPaused = true
  if (!activeSimpleGift) return

  clearGiftPresentationTimer(simpleGiftTimer)
  simpleGiftTimer = null
  activeSimpleGift.hideOverlay()
}

export function resumeSimpleGiftPresentation() {
  if (!simpleGiftPaused) return

  simpleGiftPaused = false
  if (activeSimpleGift) playActiveSimpleGift()
  else playNextSimpleGift()
}

export function clearSimpleGiftQueue() {
  const activeGift = activeSimpleGift
  clearGiftPresentationTimer(simpleGiftTimer)
  simpleGiftTimer = null
  simpleGiftQueue.length = 0
  activeSimpleGift = null
  simpleGiftPaused = false
  activeGift?.hideOverlay()
}

export function stopGiftRenderer() {
  window.FameverseGiftEngine?.stop?.()
}

export function giftActivityMessage(gift, quantity) {
  const activityEmoji = gift.activityEmoji || gift.emoji || '✦'
  return `${activityEmoji} sent ${gift.label}${quantity > 1 ? ` ×${quantity}` : ''}`
}

export function createGiftOverlay(gift, sender, count, now = Date.now()) {
  return {
    ...gift,
    sender,
    duration: 1800,
    count,
    lastSentAt: now,
  }
}

export function dispatchCinematicGift(gift, sender, comboCount) {
  document.dispatchEvent(new CustomEvent('fameverse:gift', {
    detail: { id: gift.rendererId, sender, comboCount },
  }))
}

export function seekGiftThumbnail(event, seconds = 0) {
  const video = event.currentTarget
  if (!Number.isFinite(seconds) || seconds <= 0) return
  try { video.currentTime = seconds } catch {}
}

export function videoConstraints(facingMode = 'user') {
  return {
    facingMode: { ideal: facingMode },
    width: { ideal: 720 },
    height: { ideal: 1280 },
    aspectRatio: { ideal: 9 / 16 },
  }
}

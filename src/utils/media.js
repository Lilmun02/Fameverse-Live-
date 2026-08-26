export function seekGiftThumbnail(event, seconds = 0) {
  const video = event.currentTarget
  if (!Number.isFinite(seconds) || seconds <= 0) return
  try { video.currentTime = seconds } catch {}
}

export function videoConstraints(facingMode = 'user') {
  return {
    facingMode: { ideal: facingMode },
    width: { ideal: 1280 },
    height: { ideal: 720 },
  }
}

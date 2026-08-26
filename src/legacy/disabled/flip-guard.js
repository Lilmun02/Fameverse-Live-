// Prevents the live surface from flashing the Fameverse fallback while iOS
// switches physical cameras. Capture the current video frame before React's
// flip handler replaces the MediaStream and hold it until the new camera plays.

if (typeof window !== 'undefined') {
  let activeFreeze = null
  let cleanupTimer = null

  function removeFreeze() {
    if (cleanupTimer) clearTimeout(cleanupTimer)
    cleanupTimer = null
    activeFreeze?.remove()
    activeFreeze = null
  }

  function captureCoverFrame(video, surface) {
    if (!video || !surface || video.readyState < 2 || !video.videoWidth || !video.videoHeight) return null

    const width = Math.max(1, Math.round(surface.clientWidth))
    const height = Math.max(1, Math.round(surface.clientHeight))
    const canvas = document.createElement('canvas')
    canvas.width = width
    canvas.height = height
    canvas.className = 'flip-freeze-frame'
    canvas.setAttribute('aria-hidden', 'true')

    const ctx = canvas.getContext('2d')
    if (!ctx) return null

    const vw = video.videoWidth
    const vh = video.videoHeight
    const scale = Math.max(width / vw, height / vh)
    const dw = vw * scale
    const dh = vh * scale
    const dx = (width - dw) / 2
    const dy = (height - dh) / 2

    if (video.classList.contains('mirror')) {
      ctx.translate(width, 0)
      ctx.scale(-1, 1)
      ctx.drawImage(video, width - dx - dw, dy, dw, dh)
    } else {
      ctx.drawImage(video, dx, dy, dw, dh)
    }

    return canvas
  }

  document.addEventListener('click', (event) => {
    const button = event.target?.closest?.('button')
    if (!button || button.disabled) return
    const label = (button.textContent || '').replace(/\s+/g, '').toLowerCase()
    if (label !== '↻flip' && !label.endsWith('flip')) return

    const shell = button.closest('.mobile-live-shell')
    const surface = shell?.querySelector('.live-video-surface')
    const video = surface?.querySelector('video.host-video')
    if (!surface || !video) return

    removeFreeze()
    const frame = captureCoverFrame(video, surface)
    if (!frame) return

    activeFreeze = frame
    surface.appendChild(frame)

    const releaseWhenPlaying = () => {
      requestAnimationFrame(() => requestAnimationFrame(() => setTimeout(removeFreeze, 140)))
    }

    // The same <video> element receives the replacement stream. Do not expose
    // the purple fallback until that replacement stream has actually begun
    // rendering. The long timeout is only a safety cleanup for a failed flip.
    video.addEventListener('playing', releaseWhenPlaying, { once: true })
    cleanupTimer = setTimeout(removeFreeze, 8000)
  }, true)

  document.addEventListener('click', (event) => {
    const button = event.target?.closest?.('button')
    const label = (button?.textContent || '').replace(/\s+/g, '').toLowerCase()
    if (label === 'end' || label.includes('camera') || label.includes('camon')) {
      if (!label.endsWith('flip')) removeFreeze()
    }
  }, true)
}

// Fameverse live-media compatibility layer for Home Screen PWAs.
// Keeps one microphone capture alive during camera flips so switching cameras
// does not repeatedly tear down/restart the iOS audio session.

if (typeof window !== 'undefined' && navigator.mediaDevices?.getUserMedia) {
  const mediaDevices = navigator.mediaDevices
  const nativeGetUserMedia = mediaDevices.getUserMedia.bind(mediaDevices)

  let sourceAudioTrack = null
  let managedAudioTracks = 0
  let wakeLock = null
  let liveCaptureActive = false
  let healthBanner = null
  let healthTimer = null

  function showMediaHealth(message, persistent = false) {
    if (!document.body) return
    if (!healthBanner) {
      healthBanner = document.createElement('div')
      healthBanner.className = 'toast fameverse-media-health'
      healthBanner.setAttribute('role', 'status')
      healthBanner.setAttribute('aria-live', 'polite')
      document.body.appendChild(healthBanner)
    }
    healthBanner.textContent = message
    healthBanner.hidden = false
    if (healthTimer) clearTimeout(healthTimer)
    if (!persistent) {
      healthTimer = window.setTimeout(() => {
        if (healthBanner) healthBanner.hidden = true
      }, 3200)
    }
  }

  function clearMediaHealth() {
    if (healthTimer) clearTimeout(healthTimer)
    healthTimer = null
    if (healthBanner) healthBanner.hidden = true
  }

  function stopFalseLiveState(message) {
    showMediaHealth(message, true)
    window.setTimeout(() => {
      const endButton = document.querySelector('.top-end-live')
      if (endButton && !endButton.disabled) endButton.click()
      window.setTimeout(clearMediaHealth, 3600)
    }, 0)
  }

  function monitorVideoTrack(track) {
    if (!track || track.__fameverseHealthMonitored) return track
    track.__fameverseHealthMonitored = true

    track.addEventListener?.('mute', () => {
      if (track.readyState !== 'live') return
      showMediaHealth('Camera temporarily unavailable · checking video…', true)
    })

    track.addEventListener?.('unmute', () => {
      if (track.readyState !== 'live') return
      clearMediaHealth()
    })

    track.addEventListener?.('ended', () => {
      stopFalseLiveState('Camera connection ended · live stopped')
    }, { once: true })

    return track
  }

  function monitorStream(stream) {
    stream?.getVideoTracks?.().forEach(monitorVideoTrack)
    return stream
  }

  async function acquireWakeLock() {
    if (!liveCaptureActive || document.visibilityState !== 'visible' || !navigator.wakeLock?.request) return
    if (wakeLock && !wakeLock.released) return
    try {
      wakeLock = await navigator.wakeLock.request('screen')
      wakeLock.addEventListener?.('release', () => { wakeLock = null })
    } catch {
      // Wake Lock is best-effort. iOS may reject it after backgrounding.
    }
  }

  async function releaseWakeLock() {
    const lock = wakeLock
    wakeLock = null
    if (!lock || lock.released) return
    try { await lock.release() } catch {}
  }

  function releaseSourceAudio() {
    if (sourceAudioTrack) {
      try { sourceAudioTrack.stop() } catch {}
    }
    sourceAudioTrack = null
    managedAudioTracks = 0
    liveCaptureActive = false
    clearMediaHealth()
    releaseWakeLock()
  }

  function makeManagedAudioClone() {
    if (!sourceAudioTrack || sourceAudioTrack.readyState !== 'live') return null

    const clone = sourceAudioTrack.clone()
    managedAudioTracks += 1
    let finalized = false
    const nativeStop = clone.stop.bind(clone)

    const finalize = () => {
      if (finalized) return
      finalized = true
      managedAudioTracks = Math.max(0, managedAudioTracks - 1)
      if (managedAudioTracks === 0) releaseSourceAudio()
    }

    clone.stop = () => {
      try { nativeStop() } finally { finalize() }
    }
    clone.addEventListener?.('ended', finalize, { once: true })
    return clone
  }

  mediaDevices.getUserMedia = async function fameverseGetUserMedia(constraints = {}) {
    const wantsAudio = Boolean(constraints?.audio)
    const wantsVideo = Boolean(constraints?.video)

    // The Fameverse host flow requests audio + video together. On the first
    // request, keep the real mic track private and give React a managed clone.
    if (wantsAudio && wantsVideo && (!sourceAudioTrack || sourceAudioTrack.readyState !== 'live')) {
      releaseSourceAudio()
      const sourceStream = await nativeGetUserMedia(constraints)
      const audioTrack = sourceStream.getAudioTracks()[0] || null

      if (!audioTrack) return monitorStream(sourceStream)

      sourceAudioTrack = audioTrack
      liveCaptureActive = true
      const returnedStream = new MediaStream()
      sourceStream.getVideoTracks().forEach((track) => returnedStream.addTrack(monitorVideoTrack(track)))
      const managedAudio = makeManagedAudioClone()
      if (managedAudio) returnedStream.addTrack(managedAudio)
      acquireWakeLock()
      return returnedStream
    }

    // During a camera flip the app asks for video-only replacement capture.
    // Keep monitoring each replacement track so a later device-level failure
    // cannot leave the UI claiming a dead camera is still active.
    if (wantsVideo && !wantsAudio) {
      const videoStream = await nativeGetUserMedia(constraints)
      return monitorStream(videoStream)
    }

    // If a future flow requests audio + video while the source mic remains
    // live, reuse that source and acquire only the replacement camera.
    if (wantsAudio && wantsVideo && sourceAudioTrack?.readyState === 'live') {
      const videoOnlyConstraints = { ...constraints, audio: false }
      const videoStream = await nativeGetUserMedia(videoOnlyConstraints)
      const returnedStream = new MediaStream()
      videoStream.getVideoTracks().forEach((track) => returnedStream.addTrack(monitorVideoTrack(track)))
      const managedAudio = makeManagedAudioClone()
      if (managedAudio) returnedStream.addTrack(managedAudio)
      acquireWakeLock()
      return returnedStream
    }

    return nativeGetUserMedia(constraints)
  }

  document.addEventListener('visibilitychange', () => {
    if (document.visibilityState === 'visible') acquireWakeLock()
  })

  window.addEventListener('pagehide', () => {
    releaseSourceAudio()
  })
}

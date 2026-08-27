import { useEffect, useRef, useState } from 'react'
import { videoConstraints } from '../utils/media.js'

const MEDIA_HEALTH_INTERVAL_MS = 4000
const CAMERA_WARMUP_TIMEOUT_MS = 2500

function waitForVideoFrame(video) {
  return new Promise((resolve, reject) => {
    let settled = false
    const finish = (error) => {
      if (settled) return
      settled = true
      window.clearTimeout(timeout)
      video.removeEventListener('loadeddata', onLoadedData)
      video.removeEventListener('error', onError)
      if (error) reject(error)
      else resolve()
    }
    const onLoadedData = () => finish()
    const onError = () => finish(new Error('camera-preview-error'))
    const timeout = window.setTimeout(() => finish(new Error('camera-preview-timeout')), CAMERA_WARMUP_TIMEOUT_MS)

    if (typeof video.requestVideoFrameCallback === 'function') {
      video.requestVideoFrameCallback(() => finish())
      return
    }

    if (video.readyState >= HTMLMediaElement.HAVE_CURRENT_DATA) {
      window.requestAnimationFrame(() => finish())
      return
    }

    video.addEventListener('loadeddata', onLoadedData, { once: true })
    video.addEventListener('error', onError, { once: true })
  })
}

function configureVideo(video, stream) {
  if (!video) return
  video.muted = true
  video.defaultMuted = true
  video.volume = 0
  video.srcObject = stream
}

export function useLiveMedia(setToast) {
  const [isLive, setIsLive] = useState(false)
  const [isStartingLive, setIsStartingLive] = useState(false)
  const [mediaStream, setMediaStream] = useState(null)
  const [micMuted, setMicMuted] = useState(false)
  const [cameraOff, setCameraOff] = useState(false)
  const [facingMode, setFacingMode] = useState('user')
  const [activeVideoSlot, setActiveVideoSlot] = useState(0)
  const [videoSlotFacing, setVideoSlotFacing] = useState(['user', 'environment'])

  const videoPrimaryRef = useRef(null)
  const videoSecondaryRef = useRef(null)
  const streamRef = useRef(null)
  const wakeLockRef = useRef(null)

  const getVideoElement = (slot) => (slot === 0 ? videoPrimaryRef.current : videoSecondaryRef.current)

  useEffect(() => {
    if (!mediaStream || cameraOff) return
    const video = getVideoElement(activeVideoSlot)
    if (!video) return
    configureVideo(video, mediaStream)
    video.play().catch(() => {})
  }, [mediaStream, cameraOff, activeVideoSlot])

  useEffect(() => () => {
    streamRef.current?.getTracks().forEach((track) => track.stop())
    wakeLockRef.current?.release?.().catch?.(() => {})
  }, [])

  useEffect(() => {
    if (!isLive) return undefined

    let cameraEndedReported = false
    const verifyVideoHealth = () => {
      const stream = streamRef.current
      if (!stream) return
      const videoTrack = stream.getVideoTracks()[0]
      if (!videoTrack || videoTrack.readyState !== 'ended') return
      setCameraOff(true)
      if (!cameraEndedReported) {
        cameraEndedReported = true
        setToast('Camera connection ended')
      }
    }

    const onVisibilityChange = () => {
      if (document.visibilityState !== 'visible') return
      acquireWakeLock()
      verifyVideoHealth()
    }

    const healthTimer = window.setInterval(verifyVideoHealth, MEDIA_HEALTH_INTERVAL_MS)
    document.addEventListener('visibilitychange', onVisibilityChange)
    return () => {
      window.clearInterval(healthTimer)
      document.removeEventListener('visibilitychange', onVisibilityChange)
    }
  }, [isLive, setToast])

  const acquireWakeLock = async () => {
    if (!navigator.wakeLock?.request || document.visibilityState !== 'visible' || !isLive) return
    if (wakeLockRef.current && !wakeLockRef.current.released) return
    try {
      wakeLockRef.current = await navigator.wakeLock.request('screen')
      wakeLockRef.current.addEventListener?.('release', () => { wakeLockRef.current = null })
    } catch {
      // Best effort only. iOS can reject Wake Lock after backgrounding.
    }
  }

  const releaseWakeLock = async () => {
    const lock = wakeLockRef.current
    wakeLockRef.current = null
    if (!lock || lock.released) return
    try { await lock.release() } catch {}
  }

  const stopMedia = () => {
    streamRef.current?.getTracks().forEach((track) => track.stop())
    streamRef.current = null
    setMediaStream(null)
    setCameraOff(false)
    const primary = videoPrimaryRef.current
    const secondary = videoSecondaryRef.current
    if (primary) primary.srcObject = null
    if (secondary) secondary.srcObject = null
    releaseWakeLock()
  }

  const requestMedia = async (nextFacing = facingMode) => {
    if (!navigator.mediaDevices?.getUserMedia) throw new Error('unsupported')
    return navigator.mediaDevices.getUserMedia({
      video: videoConstraints(nextFacing),
      audio: { echoCancellation: true, noiseSuppression: true, autoGainControl: true },
    })
  }

  const requestVideo = async (nextFacing = facingMode) => {
    if (!navigator.mediaDevices?.getUserMedia) throw new Error('unsupported')
    return navigator.mediaDevices.getUserMedia({ video: videoConstraints(nextFacing), audio: false })
  }

  const startLive = async () => {
    if (isLive) {
      stopMedia()
      setIsLive(false)
      setMicMuted(false)
      setCameraOff(false)
      setToast('Live ended · camera and mic released')
      return false
    }

    setIsStartingLive(true)
    try {
      const stream = await requestMedia(facingMode)
      streamRef.current = stream
      setVideoSlotFacing((slots) => {
        const next = [...slots]
        next[activeVideoSlot] = facingMode
        return next
      })
      setMediaStream(stream)
      setMicMuted(false)
      setCameraOff(false)
      setIsLive(true)
      setTimeout(() => acquireWakeLock(), 0)
      setToast('Camera + microphone ready')
      return true
    } catch (error) {
      const denied = error?.name === 'NotAllowedError' || error?.name === 'PermissionDeniedError'
      const unavailable = error?.name === 'NotFoundError' || error?.name === 'DevicesNotFoundError'
      if (denied) setToast('Allow Camera + Microphone for Fameverse in iPhone settings')
      else if (unavailable) setToast('No camera or microphone was found')
      else if (error?.message === 'unsupported') setToast('This browser does not support live camera access')
      else setToast('Could not start camera · try reopening the PWA')
      return false
    } finally {
      setIsStartingLive(false)
    }
  }

  const toggleMic = () => {
    const audioTracks = streamRef.current?.getAudioTracks() || []
    if (!audioTracks.length) return
    const nextMuted = !micMuted
    audioTracks.forEach((track) => { track.enabled = !nextMuted })
    setMicMuted(nextMuted)
  }

  const toggleCamera = () => {
    const videoTracks = streamRef.current?.getVideoTracks() || []
    if (!videoTracks.length) return
    const nextOff = !cameraOff
    videoTracks.forEach((track) => { track.enabled = !nextOff })
    setCameraOff(nextOff)
  }

  // FAM-5: keep the current camera visibly playing while a replacement camera
  // warms on the hidden video slot. Only swap DOM visibility after the new
  // camera has produced a real frame; microphone access is never re-requested.
  const flipCamera = async () => {
    if (!isLive || cameraOff || isStartingLive) return

    const currentStream = streamRef.current
    const currentVideoTrack = currentStream?.getVideoTracks()[0]
    if (!currentStream || !currentVideoTrack) return

    const previousFacing = facingMode
    const nextFacing = previousFacing === 'user' ? 'environment' : 'user'
    const nextSlot = activeVideoSlot === 0 ? 1 : 0
    const stagingVideo = getVideoElement(nextSlot)
    const currentVideo = getVideoElement(activeVideoSlot)
    let cameraStream = null

    if (!stagingVideo) return
    setIsStartingLive(true)

    try {
      cameraStream = await requestVideo(nextFacing)
      const nextVideoTrack = cameraStream.getVideoTracks()[0]
      if (!nextVideoTrack) throw new Error('camera-track-missing')

      configureVideo(stagingVideo, cameraStream)
      await stagingVideo.play()
      await waitForVideoFrame(stagingVideo)

      const audioTracks = currentStream.getAudioTracks()
      const nextStream = new MediaStream([...audioTracks, nextVideoTrack])
      configureVideo(stagingVideo, nextStream)
      await stagingVideo.play()

      streamRef.current = nextStream
      setVideoSlotFacing((slots) => {
        const next = [...slots]
        next[nextSlot] = nextFacing
        return next
      })
      setFacingMode(nextFacing)
      setActiveVideoSlot(nextSlot)
      setMediaStream(nextStream)

      await new Promise((resolve) => {
        window.requestAnimationFrame(() => window.requestAnimationFrame(resolve))
      })

      if (currentVideo) currentVideo.srcObject = null
      try { currentStream.removeTrack(currentVideoTrack) } catch {}
      try { currentVideoTrack.stop() } catch {}
    } catch {
      if (stagingVideo) stagingVideo.srcObject = null
      cameraStream?.getTracks().forEach((track) => {
        if (track !== currentVideoTrack) {
          try { track.stop() } catch {}
        }
      })
      setFacingMode(previousFacing)
      setToast('Could not switch cameras')
    } finally {
      setIsStartingLive(false)
    }
  }

  return {
    isLive,
    setIsLive,
    isStartingLive,
    mediaStream,
    micMuted,
    cameraOff,
    facingMode,
    activeVideoSlot,
    videoSlotFacing,
    videoPrimaryRef,
    videoSecondaryRef,
    startLive,
    toggleMic,
    toggleCamera,
    flipCamera,
    stopMedia,
  }
}

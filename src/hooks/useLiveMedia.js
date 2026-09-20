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
  const activeVideoSlot = 0
  const [videoSlotFacing, setVideoSlotFacing] = useState(['user', 'environment'])

  const videoPrimaryRef = useRef(null)
  const videoSecondaryRef = useRef(null)
  const streamRef = useRef(null)
  const wakeLockRef = useRef(null)
  const flipLockRef = useRef(false)

  const getVideoElement = (slot) => (slot === 0 ? videoPrimaryRef.current : videoSecondaryRef.current)

  useEffect(() => {
    if (!mediaStream || cameraOff) return
    const video = getVideoElement(activeVideoSlot)
    if (!video) return
    configureVideo(video, mediaStream)
    video.play().catch(() => {})
  }, [mediaStream, cameraOff])

  useEffect(() => () => {
    streamRef.current?.getTracks().forEach((track) => track.stop())
    wakeLockRef.current?.release?.().catch?.(() => {})
  }, [])

  useEffect(() => {
    if (!isLive) return undefined

    let cameraEndedReported = false
    const verifyVideoHealth = () => {
      if (flipLockRef.current) return
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
    flipLockRef.current = false
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

  // FAM-5 / FVB-001: iOS WebKit must never hand a flip to a second rendered
  // <video> compositor. Physical iPhone evidence showed that the newly-active
  // element can remain at the camera's intrinsic 9:16 rectangle even though CSS
  // says full-canvas. Keep one mounted full-screen video element for the entire
  // Live and replace only the MediaStream feeding it.
  const flipCamera = async () => {
    if (!isLive || cameraOff || isStartingLive || flipLockRef.current) return
    flipLockRef.current = true

    const currentStream = streamRef.current
    const currentVideoTrack = currentStream?.getVideoTracks()[0]
    const activeVideo = getVideoElement(activeVideoSlot)
    if (!currentStream || !currentVideoTrack || !activeVideo) {
      flipLockRef.current = false
      return
    }

    const previousFacing = facingMode
    const nextFacing = previousFacing === 'user' ? 'environment' : 'user'
    let cameraStream = null
    setIsStartingLive(true)

    try {
      cameraStream = await requestVideo(nextFacing)
      const nextVideoTrack = cameraStream.getVideoTracks()[0]
      if (!nextVideoTrack || nextVideoTrack.readyState !== 'live') throw new Error('camera-track-missing')

      const audioTracks = currentStream.getAudioTracks().filter((track) => track.readyState === 'live')
      const nextStream = new MediaStream([...audioTracks, nextVideoTrack])

      configureVideo(activeVideo, nextStream)
      await activeVideo.play()
      await waitForVideoFrame(activeVideo)

      streamRef.current = nextStream
      setVideoSlotFacing((slots) => {
        const next = [...slots]
        next[activeVideoSlot] = nextFacing
        return next
      })
      setFacingMode(nextFacing)
      setMediaStream(nextStream)
      setCameraOff(false)

      try { currentStream.removeTrack(currentVideoTrack) } catch {}
      if (currentVideoTrack.readyState === 'live') {
        try { currentVideoTrack.stop() } catch {}
      }
      cameraStream = null
    } catch {
      cameraStream?.getTracks().forEach((track) => {
        if (track !== currentVideoTrack) {
          try { track.stop() } catch {}
        }
      })
      setFacingMode(previousFacing)

      if (currentVideoTrack.readyState === 'live') {
        configureVideo(activeVideo, currentStream)
        await activeVideo.play().catch(() => {})
        setCameraOff(false)
        setToast('Could not switch cameras · original camera kept')
      } else {
        try {
          const recoveryCamera = await requestVideo(previousFacing)
          const recoveryTrack = recoveryCamera.getVideoTracks()[0]
          if (!recoveryTrack) throw new Error('camera-recovery-missing')
          const audioTracks = currentStream.getAudioTracks().filter((track) => track.readyState === 'live')
          const recoveryStream = new MediaStream([...audioTracks, recoveryTrack])
          streamRef.current = recoveryStream
          configureVideo(activeVideo, recoveryStream)
          await activeVideo.play()
          await waitForVideoFrame(activeVideo)
          setMediaStream(recoveryStream)
          setCameraOff(false)
          setToast('Camera switch canceled · camera restored')
        } catch {
          setCameraOff(true)
          setToast('Camera connection ended · tap Cam on to recover')
        }
      }
    } finally {
      flipLockRef.current = false
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

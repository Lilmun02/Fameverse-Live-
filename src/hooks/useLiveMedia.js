import { useEffect, useRef, useState } from 'react'
import { videoConstraints } from '../utils/media.js'

export function useLiveMedia(setToast) {
  const [isLive, setIsLive] = useState(false)
  const [isStartingLive, setIsStartingLive] = useState(false)
  const [mediaStream, setMediaStream] = useState(null)
  const [micMuted, setMicMuted] = useState(false)
  const [cameraOff, setCameraOff] = useState(false)
  const [facingMode, setFacingMode] = useState('user')

  const videoRef = useRef(null)
  const streamRef = useRef(null)
  const wakeLockRef = useRef(null)

  useEffect(() => {
    if (!videoRef.current || !mediaStream || cameraOff) return
    videoRef.current.muted = true
    videoRef.current.defaultMuted = true
    videoRef.current.volume = 0
    videoRef.current.srcObject = mediaStream
    videoRef.current.play().catch(() => {})
  }, [mediaStream, cameraOff, facingMode])

  useEffect(() => () => {
    streamRef.current?.getTracks().forEach((track) => track.stop())
    wakeLockRef.current?.release?.().catch?.(() => {})
  }, [])

  useEffect(() => {
    const reacquire = () => {
      if (document.visibilityState === 'visible' && isLive) acquireWakeLock()
    }
    document.addEventListener('visibilitychange', reacquire)
    return () => document.removeEventListener('visibilitychange', reacquire)
  }, [isLive])

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
    if (videoRef.current) videoRef.current.srcObject = null
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

  // Official FAM-5 camera-first patch: acquire the replacement camera before
  // retiring the active video track. Audio is deliberately preserved and is
  // never re-requested during a camera switch.
  const flipCamera = async () => {
    if (!isLive || cameraOff || isStartingLive) return

    const currentStream = streamRef.current
    if (!currentStream) return

    const previousFacing = facingMode
    const nextFacing = previousFacing === 'user' ? 'environment' : 'user'
    const audioTracks = currentStream.getAudioTracks()
    const oldVideoTracks = currentStream.getVideoTracks()

    setIsStartingLive(true)
    try {
      const cameraStream = await requestVideo(nextFacing)
      const nextVideoTrack = cameraStream.getVideoTracks()[0]
      if (!nextVideoTrack) throw new Error('camera-track-missing')

      const nextStream = new MediaStream([...audioTracks, nextVideoTrack])
      streamRef.current = nextStream
      setFacingMode(nextFacing)
      setMediaStream(nextStream)

      const video = videoRef.current
      if (video) {
        video.muted = true
        video.defaultMuted = true
        video.volume = 0
        video.srcObject = nextStream
        video.play().catch(() => {})
      }

      oldVideoTracks.forEach((track) => {
        try { currentStream.removeTrack(track) } catch {}
        try { track.stop() } catch {}
      })
    } catch {
      try {
        const restoreStream = await requestVideo(previousFacing)
        const restoredVideoTrack = restoreStream.getVideoTracks()[0]
        if (restoredVideoTrack) {
          const restoredStream = new MediaStream([...audioTracks, restoredVideoTrack])
          streamRef.current = restoredStream
          setMediaStream(restoredStream)
        } else {
          setCameraOff(true)
        }
      } catch {
        setCameraOff(true)
      }
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
    videoRef,
    startLive,
    toggleMic,
    toggleCamera,
    flipCamera,
    stopMedia,
  }
}

import { useEffect, useRef, useState } from 'react'
import { videoConstraints } from '../utils/media.js'
import {
  attachCameraStream,
  buildStreamWithCamera,
  requestCameraStream,
  retireVideoTracks,
} from '../systems/media/cameraSystem.js'
import { getMicrophoneTracks, setMicrophoneMuted } from '../systems/media/microphoneSystem.js'
import { requestLiveStream, stopLiveStream } from '../systems/media/liveStreamSystem.js'
import { acquireScreenWakeLock, releaseScreenWakeLock } from '../systems/device/wakeLockSystem.js'

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
    attachCameraStream(videoRef.current, mediaStream)
  }, [mediaStream, cameraOff, facingMode])

  useEffect(() => () => {
    stopLiveStream(streamRef.current)
    releaseScreenWakeLock(wakeLockRef.current)
  }, [])

  const acquireWakeLock = async () => {
    if (!isLive) return
    const nextLock = await acquireScreenWakeLock(wakeLockRef.current)
    wakeLockRef.current = nextLock
    nextLock?.addEventListener?.('release', () => {
      if (wakeLockRef.current === nextLock) wakeLockRef.current = null
    }, { once: true })
  }

  const releaseWakeLock = async () => {
    const lock = wakeLockRef.current
    wakeLockRef.current = null
    await releaseScreenWakeLock(lock)
  }

  useEffect(() => {
    const reacquire = () => {
      if (document.visibilityState === 'visible' && isLive) acquireWakeLock()
    }
    document.addEventListener('visibilitychange', reacquire)
    return () => document.removeEventListener('visibilitychange', reacquire)
  }, [isLive])

  const stopMedia = () => {
    stopLiveStream(streamRef.current)
    streamRef.current = null
    setMediaStream(null)
    setCameraOff(false)
    if (videoRef.current) videoRef.current.srcObject = null
    releaseWakeLock()
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
      const stream = await requestLiveStream(videoConstraints(facingMode))
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
    const nextMuted = !micMuted
    if (!setMicrophoneMuted(streamRef.current, nextMuted)) return
    setMicMuted(nextMuted)
  }

  const toggleCamera = () => {
    const videoTracks = streamRef.current?.getVideoTracks() || []
    if (!videoTracks.length) return
    const nextOff = !cameraOff
    videoTracks.forEach((track) => { track.enabled = !nextOff })
    setCameraOff(nextOff)
  }

  const flipCamera = async () => {
    if (!isLive || cameraOff || isStartingLive) return

    const currentStream = streamRef.current
    if (!currentStream) return

    const previousFacing = facingMode
    const nextFacing = previousFacing === 'user' ? 'environment' : 'user'
    const audioTracks = getMicrophoneTracks(currentStream)

    setIsStartingLive(true)
    try {
      const cameraStream = await requestCameraStream(videoConstraints(nextFacing))
      const nextVideoTrack = cameraStream.getVideoTracks()[0]
      if (!nextVideoTrack) throw new Error('camera-track-missing')

      const nextStream = buildStreamWithCamera(audioTracks, nextVideoTrack)
      streamRef.current = nextStream
      setFacingMode(nextFacing)
      setMediaStream(nextStream)
      attachCameraStream(videoRef.current, nextStream)
      retireVideoTracks(currentStream)
    } catch {
      try {
        const restoreStream = await requestCameraStream(videoConstraints(previousFacing))
        const restoredVideoTrack = restoreStream.getVideoTracks()[0]
        if (restoredVideoTrack) {
          const restoredStream = buildStreamWithCamera(audioTracks, restoredVideoTrack)
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

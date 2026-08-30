export function requestCameraStream(videoConstraints) {
  if (!navigator.mediaDevices?.getUserMedia) throw new Error('unsupported')
  return navigator.mediaDevices.getUserMedia({ video: videoConstraints, audio: false })
}

export function buildStreamWithCamera(audioTracks, videoTrack) {
  return new MediaStream([...audioTracks, videoTrack])
}

export function attachCameraStream(videoElement, stream) {
  if (!videoElement) return
  videoElement.muted = true
  videoElement.defaultMuted = true
  videoElement.volume = 0
  videoElement.srcObject = stream
  videoElement.play().catch(() => {})
}

export function detachCameraStream(videoElement) {
  if (!videoElement) return
  videoElement.srcObject = null
}

export function setCameraEnabled(stream, enabled) {
  const videoTracks = stream?.getVideoTracks?.() || []
  if (!videoTracks.length) return false
  videoTracks.forEach((track) => { track.enabled = enabled })
  return true
}

export function retireVideoTracks(stream) {
  stream?.getVideoTracks().forEach((track) => {
    try { stream.removeTrack(track) } catch {}
    try { track.stop() } catch {}
  })
}

export async function switchCameraStream({
  currentStream,
  audioTracks,
  nextVideoConstraints,
  previousVideoConstraints,
}) {
  try {
    const cameraStream = await requestCameraStream(nextVideoConstraints)
    const nextVideoTrack = cameraStream.getVideoTracks()[0]
    if (!nextVideoTrack) throw new Error('camera-track-missing')

    const nextStream = buildStreamWithCamera(audioTracks, nextVideoTrack)
    retireVideoTracks(currentStream)
    return { stream: nextStream, switched: true, cameraAvailable: true }
  } catch {
    try {
      const restoreStream = await requestCameraStream(previousVideoConstraints)
      const restoredVideoTrack = restoreStream.getVideoTracks()[0]
      if (!restoredVideoTrack) {
        return { stream: currentStream, switched: false, cameraAvailable: false }
      }

      const restoredStream = buildStreamWithCamera(audioTracks, restoredVideoTrack)
      return { stream: restoredStream, switched: false, cameraAvailable: true }
    } catch {
      return { stream: currentStream, switched: false, cameraAvailable: false }
    }
  }
}

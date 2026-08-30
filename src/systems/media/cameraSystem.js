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

export function retireVideoTracks(stream) {
  stream?.getVideoTracks().forEach((track) => {
    try { stream.removeTrack(track) } catch {}
    try { track.stop() } catch {}
  })
}

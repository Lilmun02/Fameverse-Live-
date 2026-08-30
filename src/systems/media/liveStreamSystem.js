export function requestLiveStream(videoConstraints) {
  if (!navigator.mediaDevices?.getUserMedia) throw new Error('unsupported')
  return navigator.mediaDevices.getUserMedia({
    video: videoConstraints,
    audio: { echoCancellation: true, noiseSuppression: true, autoGainControl: true },
  })
}

export function stopLiveStream(stream) {
  stream?.getTracks().forEach((track) => {
    try { track.stop() } catch {}
  })
}

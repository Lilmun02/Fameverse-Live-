export function setMicrophoneMuted(stream, muted) {
  const audioTracks = stream?.getAudioTracks() || []
  if (!audioTracks.length) return false
  audioTracks.forEach((track) => { track.enabled = !muted })
  return true
}

export function getMicrophoneTracks(stream) {
  return stream?.getAudioTracks() || []
}

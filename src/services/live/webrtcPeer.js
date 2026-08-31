export function createCohostPeer({
  iceServers = [],
  onIceCandidate,
  onTrack,
  onConnectionStateChange,
} = {}) {
  if (typeof RTCPeerConnection === 'undefined') throw new Error('webrtc-unsupported')

  const peer = new RTCPeerConnection({ iceServers })
  peer.onicecandidate = (event) => {
    if (event.candidate) onIceCandidate?.(event.candidate)
  }
  peer.ontrack = (event) => onTrack?.(event)
  peer.onconnectionstatechange = () => onConnectionStateChange?.(peer.connectionState)
  return peer
}

export function attachLocalStream(peer, stream) {
  if (!peer || !stream) return
  const existingTrackIds = new Set(peer.getSenders().map((sender) => sender.track?.id).filter(Boolean))
  stream.getTracks().forEach((track) => {
    if (!existingTrackIds.has(track.id)) peer.addTrack(track, stream)
  })
}

export async function createCohostOffer(peer) {
  const offer = await peer.createOffer()
  await peer.setLocalDescription(offer)
  return peer.localDescription
}

export async function acceptCohostOffer(peer, offer) {
  await peer.setRemoteDescription(offer)
  const answer = await peer.createAnswer()
  await peer.setLocalDescription(answer)
  return peer.localDescription
}

export async function acceptCohostAnswer(peer, answer) {
  await peer.setRemoteDescription(answer)
}

export async function addCohostIceCandidate(peer, candidate) {
  if (!candidate) return
  await peer.addIceCandidate(candidate)
}

export function closeCohostPeer(peer) {
  if (!peer) return
  peer.onicecandidate = null
  peer.ontrack = null
  peer.onconnectionstatechange = null
  peer.close()
}

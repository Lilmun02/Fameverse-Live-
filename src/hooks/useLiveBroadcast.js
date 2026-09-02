import { useEffect, useRef, useState } from 'react'
import {
  acceptCohostAnswer,
  addCohostIceCandidate,
  attachLocalStream,
  closeCohostPeer,
  createCohostOffer,
  createCohostPeer,
} from '../services/live/webrtcPeer.js'
import {
  createLiveRelayChannel,
  LIVE_RELAY_ICE_SERVERS,
  removeLiveRelayChannel,
  sendLiveRelayEvent,
} from '../services/live/liveRelay.js'

function serializeCandidate(candidate) {
  return candidate?.toJSON ? candidate.toJSON() : candidate
}

export function useLiveBroadcast({ roomId, stream, enabled }) {
  const streamRef = useRef(stream)
  const peersRef = useRef(new Map())
  const [viewerCount, setViewerCount] = useState(0)
  const hasStream = Boolean(stream)

  const updateViewerCount = () => {
    const connected = [...peersRef.current.values()].filter((entry) => entry.connected).length
    setViewerCount(connected)
  }

  useEffect(() => {
    streamRef.current = stream
    if (!stream) return

    peersRef.current.forEach(({ peer }) => {
      for (const kind of ['video', 'audio']) {
        const nextTrack = stream.getTracks().find((track) => track.kind === kind)
        const sender = peer.getSenders().find((item) => item.track?.kind === kind)
        if (nextTrack && sender && sender.track !== nextTrack) {
          void sender.replaceTrack(nextTrack).catch(() => {})
        }
      }
    })
  }, [stream])

  useEffect(() => {
    if (!enabled || !roomId || !hasStream) {
      setViewerCount(0)
      return undefined
    }

    let active = true
    const channel = createLiveRelayChannel(roomId)
    const peers = peersRef.current

    const send = (event, payload) => sendLiveRelayEvent(channel, event, payload)

    const removePeer = (viewerId) => {
      const entry = peers.get(viewerId)
      if (!entry) return
      closeCohostPeer(entry.peer)
      peers.delete(viewerId)
      updateViewerCount()
    }

    const flushPendingIce = async (entry) => {
      if (!entry?.peer?.remoteDescription || !entry.pendingIce.length) return
      const pending = entry.pendingIce.splice(0)
      for (const candidate of pending) {
        try { await addCohostIceCandidate(entry.peer, candidate) } catch {}
      }
    }

    const offerViewer = async (viewerId) => {
      if (!active || !viewerId || !streamRef.current) return
      removePeer(viewerId)

      const entry = { peer: null, pendingIce: [], connected: false }
      const peer = createCohostPeer({
        iceServers: LIVE_RELAY_ICE_SERVERS,
        onIceCandidate: (candidate) => {
          void send('host-ice', { viewerId, candidate: serializeCandidate(candidate) })
        },
        onConnectionStateChange: (state) => {
          const current = peers.get(viewerId)
          if (!current) return
          if (state === 'connected') {
            current.connected = true
            updateViewerCount()
          } else if (state === 'failed' || state === 'closed') {
            removePeer(viewerId)
          }
        },
      })
      entry.peer = peer
      peers.set(viewerId, entry)

      try {
        attachLocalStream(peer, streamRef.current)
        const offer = await createCohostOffer(peer)
        if (!active || peers.get(viewerId)?.peer !== peer) return
        await send('host-offer', { viewerId, offer })
      } catch {
        removePeer(viewerId)
      }
    }

    channel
      .on('broadcast', { event: 'viewer-ready' }, ({ payload }) => {
        void offerViewer(payload?.viewerId)
      })
      .on('broadcast', { event: 'viewer-answer' }, async ({ payload }) => {
        const viewerId = payload?.viewerId
        const entry = peers.get(viewerId)
        if (!entry?.peer || !payload?.answer) return
        try {
          await acceptCohostAnswer(entry.peer, payload.answer)
          await flushPendingIce(entry)
        } catch {
          removePeer(viewerId)
        }
      })
      .on('broadcast', { event: 'viewer-ice' }, async ({ payload }) => {
        const viewerId = payload?.viewerId
        const entry = peers.get(viewerId)
        if (!entry?.peer || !payload?.candidate) return
        if (!entry.peer.remoteDescription) {
          entry.pendingIce.push(payload.candidate)
          return
        }
        try { await addCohostIceCandidate(entry.peer, payload.candidate) } catch {}
      })
      .on('broadcast', { event: 'viewer-left' }, ({ payload }) => {
        removePeer(payload?.viewerId)
      })
      .subscribe((status) => {
        if (status === 'SUBSCRIBED') void send('host-ready', { roomId })
      })

    return () => {
      active = false
      void send('host-ended', { roomId })
      peers.forEach(({ peer }) => closeCohostPeer(peer))
      peers.clear()
      setViewerCount(0)
      void removeLiveRelayChannel(channel)
    }
  }, [enabled, hasStream, roomId])

  return { viewerCount }
}

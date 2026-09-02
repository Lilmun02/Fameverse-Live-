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

const OFFER_RETRY_AFTER_MS = 8000

function serializeCandidate(candidate) {
  return candidate?.toJSON ? candidate.toJSON() : candidate
}

function makeOfferId() {
  if (globalThis.crypto?.randomUUID) return globalThis.crypto.randomUUID()
  return `${Date.now()}-${Math.random().toString(36).slice(2, 9)}`
}

function viewerProfile(payload) {
  return {
    userId: payload?.userId || null,
    displayName: payload?.displayName || 'Fameverse viewer',
    avatarUrl: payload?.avatarUrl || null,
  }
}

export function useLiveBroadcast({ roomId, stream, enabled }) {
  const streamRef = useRef(stream)
  const peersRef = useRef(new Map())
  const [viewerCount, setViewerCount] = useState(0)
  const [viewerIds, setViewerIds] = useState([])
  const [viewerRoster, setViewerRoster] = useState([])
  const hasStream = Boolean(stream)

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
      setViewerIds([])
      setViewerRoster([])
      return undefined
    }

    let active = true
    const channel = createLiveRelayChannel(roomId)
    const peers = peersRef.current

    const send = (event, payload) => sendLiveRelayEvent(channel, event, payload)

    const publishViewerCount = () => {
      const connected = [...peers.entries()].filter(([, entry]) => entry.connected)
      const connectedIds = connected.map(([viewerId]) => viewerId)
      const roster = connected.map(([viewerId, entry]) => ({ viewerId, ...entry.profile }))
      setViewerIds(connectedIds)
      setViewerRoster(roster)
      setViewerCount(connectedIds.length)
      void send('viewer-count', { roomId, viewerCount: connectedIds.length })
    }

    const removePeer = (viewerId) => {
      const entry = peers.get(viewerId)
      if (!entry) return
      closeCohostPeer(entry.peer)
      peers.delete(viewerId)
      publishViewerCount()
    }

    const flushPendingIce = async (entry) => {
      if (!entry?.peer?.remoteDescription || !entry.pendingIce.length) return
      const pending = entry.pendingIce.splice(0)
      for (const candidate of pending) {
        try { await addCohostIceCandidate(entry.peer, candidate) } catch {}
      }
    }

    const offerViewer = async (payload) => {
      const viewerId = payload?.viewerId
      if (!active || !viewerId || !streamRef.current) return
      const existing = peers.get(viewerId)
      if (existing) existing.profile = viewerProfile(payload)
      if (
        existing
        && existing.peer?.connectionState !== 'failed'
        && existing.peer?.connectionState !== 'closed'
        && Date.now() - existing.createdAt < OFFER_RETRY_AFTER_MS
      ) {
        if (existing.connected) publishViewerCount()
        return
      }

      removePeer(viewerId)
      const offerId = makeOfferId()
      const entry = {
        peer: null,
        offerId,
        pendingIce: [],
        connected: false,
        createdAt: Date.now(),
        profile: viewerProfile(payload),
      }
      const peer = createCohostPeer({
        iceServers: LIVE_RELAY_ICE_SERVERS,
        onIceCandidate: (candidate) => {
          void send('host-ice', {
            viewerId,
            offerId,
            candidate: serializeCandidate(candidate),
          })
        },
        onConnectionStateChange: (state) => {
          const current = peers.get(viewerId)
          if (!current || current.peer !== peer) return
          if (state === 'connected') {
            current.connected = true
            publishViewerCount()
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
        await send('host-offer', { viewerId, offerId, offer })
      } catch {
        removePeer(viewerId)
      }
    }

    channel
      .on('broadcast', { event: 'viewer-ready' }, ({ payload }) => {
        void offerViewer(payload)
      })
      .on('broadcast', { event: 'viewer-answer' }, async ({ payload }) => {
        const viewerId = payload?.viewerId
        const entry = peers.get(viewerId)
        if (!entry?.peer || !payload?.answer || payload?.offerId !== entry.offerId) return
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
        if (!entry?.peer || !payload?.candidate || payload?.offerId !== entry.offerId) return
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
        if (status === 'SUBSCRIBED') {
          publishViewerCount()
          void send('host-ready', { roomId, viewerCount: 0 })
        }
      })

    return () => {
      active = false
      void send('host-ended', { roomId })
      peers.forEach(({ peer }) => closeCohostPeer(peer))
      peers.clear()
      setViewerCount(0)
      setViewerIds([])
      setViewerRoster([])
      void removeLiveRelayChannel(channel)
    }
  }, [enabled, hasStream, roomId])

  return { viewerCount, viewerIds, viewerRoster }
}

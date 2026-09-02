import { useEffect, useRef, useState } from 'react'
import {
  acceptCohostOffer,
  addCohostIceCandidate,
  closeCohostPeer,
  createCohostPeer,
} from '../services/live/webrtcPeer.js'
import {
  createLiveRelayChannel,
  LIVE_RELAY_ICE_SERVERS,
  removeLiveRelayChannel,
  sendLiveRelayEvent,
} from '../services/live/liveRelay.js'

const VIEWER_RETRY_MS = 2500

function makeViewerId() {
  if (globalThis.crypto?.randomUUID) return `viewer-${globalThis.crypto.randomUUID()}`
  return `viewer-${Date.now()}-${Math.random().toString(36).slice(2, 9)}`
}

function serializeCandidate(candidate) {
  return candidate?.toJSON ? candidate.toJSON() : candidate
}

export function useLiveViewer({ roomId, enabled = true }) {
  const viewerIdRef = useRef(makeViewerId())
  const peerRef = useRef(null)
  const stateRef = useRef('idle')
  const pendingIceRef = useRef([])
  const [remoteStream, setRemoteStream] = useState(null)
  const [state, setState] = useState('idle')

  const changeState = (next) => {
    stateRef.current = next
    setState(next)
  }

  useEffect(() => {
    if (!enabled || !roomId) {
      changeState('idle')
      setRemoteStream(null)
      return undefined
    }

    let active = true
    const viewerId = viewerIdRef.current
    const channel = createLiveRelayChannel(roomId)
    changeState('connecting')

    const send = (event, payload = {}) => sendLiveRelayEvent(channel, event, { viewerId, ...payload })

    const closePeer = () => {
      closeCohostPeer(peerRef.current)
      peerRef.current = null
      pendingIceRef.current = []
    }

    const requestHost = () => {
      if (!active || stateRef.current === 'connected' || stateRef.current === 'ended') return
      void send('viewer-ready', { roomId })
    }

    const flushPendingIce = async (peer) => {
      if (!peer?.remoteDescription || !pendingIceRef.current.length) return
      const pending = pendingIceRef.current.splice(0)
      for (const candidate of pending) {
        try { await addCohostIceCandidate(peer, candidate) } catch {}
      }
    }

    const acceptOffer = async (payload) => {
      if (!active || payload?.viewerId !== viewerId || !payload?.offer) return
      closePeer()
      setRemoteStream(null)
      changeState('connecting')

      const peer = createCohostPeer({
        iceServers: LIVE_RELAY_ICE_SERVERS,
        onIceCandidate: (candidate) => {
          void send('viewer-ice', { candidate: serializeCandidate(candidate) })
        },
        onTrack: (event) => {
          if (!active) return
          const incoming = event.streams?.[0] || new MediaStream([event.track])
          setRemoteStream(incoming)
        },
        onConnectionStateChange: (connectionState) => {
          if (!active || peerRef.current !== peer) return
          if (connectionState === 'connected') changeState('connected')
          if (connectionState === 'failed' || connectionState === 'closed') {
            setRemoteStream(null)
            changeState('connecting')
          }
        },
      })
      peerRef.current = peer

      try {
        const answer = await acceptCohostOffer(peer, payload.offer)
        await flushPendingIce(peer)
        if (!active || peerRef.current !== peer) return
        await send('viewer-answer', { answer })
      } catch {
        if (peerRef.current === peer) closePeer()
        setRemoteStream(null)
        changeState('connecting')
      }
    }

    channel
      .on('broadcast', { event: 'host-ready' }, () => requestHost())
      .on('broadcast', { event: 'host-offer' }, ({ payload }) => {
        void acceptOffer(payload)
      })
      .on('broadcast', { event: 'host-ice' }, async ({ payload }) => {
        if (payload?.viewerId !== viewerId || !payload?.candidate) return
        const peer = peerRef.current
        if (!peer?.remoteDescription) {
          pendingIceRef.current.push(payload.candidate)
          return
        }
        try { await addCohostIceCandidate(peer, payload.candidate) } catch {}
      })
      .on('broadcast', { event: 'host-ended' }, () => {
        closePeer()
        setRemoteStream(null)
        changeState('ended')
      })
      .subscribe((status) => {
        if (status === 'SUBSCRIBED') requestHost()
        if (status === 'CHANNEL_ERROR' || status === 'TIMED_OUT') changeState('degraded')
      })

    const retryTimer = window.setInterval(requestHost, VIEWER_RETRY_MS)

    return () => {
      active = false
      window.clearInterval(retryTimer)
      void send('viewer-left', { roomId })
      closePeer()
      setRemoteStream(null)
      void removeLiveRelayChannel(channel)
    }
  }, [enabled, roomId])

  return { remoteStream, state }
}

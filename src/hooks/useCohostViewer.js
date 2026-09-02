import { useCallback, useEffect, useRef, useState } from 'react'
import {
  acceptCohostAnswer,
  acceptCohostOffer,
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

function makeRequestId() {
  if (globalThis.crypto?.randomUUID) return globalThis.crypto.randomUUID()
  return `${Date.now()}-${Math.random().toString(36).slice(2, 9)}`
}

function makeOfferId() {
  if (globalThis.crypto?.randomUUID) return globalThis.crypto.randomUUID()
  return `${Date.now()}-${Math.random().toString(36).slice(2, 9)}`
}

function serializeCandidate(candidate) {
  return candidate?.toJSON ? candidate.toJSON() : candidate
}

function stopStream(stream) {
  stream?.getTracks?.().forEach((track) => track.stop())
}

export function useCohostViewer({
  roomId,
  viewerId,
  userId,
  displayName,
  avatarUrl,
  enabled,
  setToast,
}) {
  const channelRef = useRef(null)
  const localStreamRef = useRef(null)
  const sourcePeersRef = useRef(new Map())
  const targetPeerRef = useRef(null)
  const targetOfferIdRef = useRef(null)
  const targetSourceIdRef = useRef(null)
  const pendingTargetIceRef = useRef([])
  const latestTargetsRef = useRef([])
  const statusRef = useRef('idle')
  const [status, setStatus] = useState('idle')
  const [localStream, setLocalStream] = useState(null)
  const [remoteStream, setRemoteStream] = useState(null)
  const [activeCohost, setActiveCohost] = useState(null)

  const changeStatus = useCallback((next) => {
    statusRef.current = next
    setStatus(next)
  }, [])

  const send = useCallback((event, payload = {}) => {
    if (!channelRef.current) return Promise.resolve('error')
    return sendLiveRelayEvent(channelRef.current, event, payload)
  }, [])

  const closeSourcePeers = useCallback(() => {
    sourcePeersRef.current.forEach(({ peer }) => closeCohostPeer(peer))
    sourcePeersRef.current.clear()
  }, [])

  const closeTargetPeer = useCallback(() => {
    closeCohostPeer(targetPeerRef.current)
    targetPeerRef.current = null
    targetOfferIdRef.current = null
    targetSourceIdRef.current = null
    pendingTargetIceRef.current = []
    setRemoteStream(null)
  }, [])

  const clearSource = useCallback(() => {
    closeSourcePeers()
    stopStream(localStreamRef.current)
    localStreamRef.current = null
    setLocalStream(null)
    latestTargetsRef.current = []
    if (statusRef.current === 'live' || statusRef.current === 'connecting') changeStatus('idle')
  }, [changeStatus, closeSourcePeers])

  const connectTarget = useCallback(async (targetId, profile) => {
    if (!targetId || !localStreamRef.current || !viewerId) return
    const existing = sourcePeersRef.current.get(targetId)
    if (existing?.peer?.connectionState === 'connected' || existing?.peer?.connectionState === 'connecting') return
    if (existing) closeCohostPeer(existing.peer)

    const offerId = makeOfferId()
    const entry = { peer: null, offerId, pendingIce: [] }
    const peer = createCohostPeer({
      iceServers: LIVE_RELAY_ICE_SERVERS,
      onIceCandidate: (candidate) => {
        void send('cohost-ice-source', {
          sourceViewerId: viewerId,
          targetId,
          offerId,
          candidate: serializeCandidate(candidate),
        })
      },
      onConnectionStateChange: (state) => {
        if (state === 'failed' || state === 'closed') {
          const current = sourcePeersRef.current.get(targetId)
          if (current?.peer === peer) sourcePeersRef.current.delete(targetId)
        }
      },
    })
    entry.peer = peer
    sourcePeersRef.current.set(targetId, entry)

    try {
      attachLocalStream(peer, localStreamRef.current)
      const offer = await createCohostOffer(peer)
      await send('cohost-offer', {
        sourceViewerId: viewerId,
        targetId,
        offerId,
        profile,
        offer,
      })
    } catch {
      closeCohostPeer(peer)
      sourcePeersRef.current.delete(targetId)
    }
  }, [send, viewerId])

  const syncTargets = useCallback((targetIds) => {
    const normalized = [...new Set((targetIds || []).filter(Boolean))]
    latestTargetsRef.current = normalized
    const profile = { userId, displayName, avatarUrl: avatarUrl || null }
    sourcePeersRef.current.forEach(({ peer }, targetId) => {
      if (!normalized.includes(targetId)) {
        closeCohostPeer(peer)
        sourcePeersRef.current.delete(targetId)
      }
    })
    if (!localStreamRef.current) return
    normalized.forEach((targetId) => void connectTarget(targetId, profile))
  }, [avatarUrl, connectTarget, displayName, userId])

  const startSource = useCallback(async () => {
    if (!navigator.mediaDevices?.getUserMedia || localStreamRef.current) return
    changeStatus('connecting')
    try {
      const stream = await navigator.mediaDevices.getUserMedia({
        video: { facingMode: 'user' },
        audio: true,
      })
      localStreamRef.current = stream
      setLocalStream(stream)
      changeStatus('live')
      const profile = { userId, displayName, avatarUrl: avatarUrl || null }
      setActiveCohost({ viewerId, ...profile })
      await send('cohost-active', { viewerId, ...profile })
      syncTargets(latestTargetsRef.current)
    } catch {
      clearSource()
      changeStatus('idle')
      setToast?.('Camera and microphone are required to co-host')
      void send('cohost-failed', { viewerId, userId })
    }
  }, [avatarUrl, changeStatus, clearSource, displayName, send, setToast, syncTargets, userId, viewerId])

  useEffect(() => {
    if (!enabled || !roomId || !viewerId || !userId) {
      clearSource()
      closeTargetPeer()
      changeStatus('idle')
      setActiveCohost(null)
      return undefined
    }

    let active = true
    const channel = createLiveRelayChannel(roomId)
    channelRef.current = channel

    const acceptIncomingOffer = async (payload) => {
      if (!active || payload?.targetId !== viewerId || !payload?.offer || !payload?.offerId) return
      if (payload?.sourceViewerId === viewerId) return
      closeTargetPeer()
      const offerId = payload.offerId
      targetOfferIdRef.current = offerId
      targetSourceIdRef.current = payload.sourceViewerId
      if (payload.profile) setActiveCohost({ viewerId: payload.sourceViewerId, ...payload.profile })

      const peer = createCohostPeer({
        iceServers: LIVE_RELAY_ICE_SERVERS,
        onIceCandidate: (candidate) => {
          void send('cohost-ice-target', {
            sourceViewerId: payload.sourceViewerId,
            targetId: viewerId,
            offerId,
            candidate: serializeCandidate(candidate),
          })
        },
        onTrack: (event) => {
          if (!active || targetPeerRef.current !== peer) return
          setRemoteStream(event.streams?.[0] || new MediaStream([event.track]))
        },
        onConnectionStateChange: (state) => {
          if (!active || targetPeerRef.current !== peer) return
          if (state === 'failed' || state === 'closed') setRemoteStream(null)
        },
      })
      targetPeerRef.current = peer

      try {
        const answer = await acceptCohostOffer(peer, payload.offer)
        const pending = pendingTargetIceRef.current.splice(0)
        for (const candidate of pending) {
          try { await addCohostIceCandidate(peer, candidate) } catch {}
        }
        if (!active || targetPeerRef.current !== peer) return
        await send('cohost-answer', {
          sourceViewerId: payload.sourceViewerId,
          targetId: viewerId,
          offerId,
          answer,
        })
      } catch {
        closeTargetPeer()
      }
    }

    channel
      .on('broadcast', { event: 'cohost-accept' }, ({ payload }) => {
        if (payload?.viewerId !== viewerId) return
        void startSource()
      })
      .on('broadcast', { event: 'cohost-decline' }, ({ payload }) => {
        if (payload?.viewerId !== viewerId) return
        changeStatus('declined')
        window.setTimeout(() => changeStatus('idle'), 1800)
      })
      .on('broadcast', { event: 'cohost-peer-list' }, ({ payload }) => {
        if (payload?.viewerId !== viewerId) return
        syncTargets(payload.targetIds)
      })
      .on('broadcast', { event: 'cohost-active' }, ({ payload }) => {
        if (!payload?.viewerId || payload.viewerId === viewerId) return
        setActiveCohost({
          viewerId: payload.viewerId,
          userId: payload.userId || null,
          displayName: payload.displayName || 'Co-host',
          avatarUrl: payload.avatarUrl || null,
        })
      })
      .on('broadcast', { event: 'cohost-offer' }, ({ payload }) => {
        void acceptIncomingOffer(payload)
      })
      .on('broadcast', { event: 'cohost-ice-source' }, async ({ payload }) => {
        if (payload?.targetId !== viewerId || !payload?.candidate) return
        if (payload?.offerId !== targetOfferIdRef.current || payload?.sourceViewerId !== targetSourceIdRef.current) return
        const peer = targetPeerRef.current
        if (!peer?.remoteDescription) {
          pendingTargetIceRef.current.push(payload.candidate)
          return
        }
        try { await addCohostIceCandidate(peer, payload.candidate) } catch {}
      })
      .on('broadcast', { event: 'cohost-answer' }, async ({ payload }) => {
        if (payload?.sourceViewerId !== viewerId || !payload?.targetId || !payload?.answer) return
        const entry = sourcePeersRef.current.get(payload.targetId)
        if (!entry?.peer || payload.offerId !== entry.offerId) return
        try {
          await acceptCohostAnswer(entry.peer, payload.answer)
          const pending = entry.pendingIce.splice(0)
          for (const candidate of pending) {
            try { await addCohostIceCandidate(entry.peer, candidate) } catch {}
          }
        } catch {}
      })
      .on('broadcast', { event: 'cohost-ice-target' }, async ({ payload }) => {
        if (payload?.sourceViewerId !== viewerId || !payload?.targetId || !payload?.candidate) return
        const entry = sourcePeersRef.current.get(payload.targetId)
        if (!entry?.peer || payload.offerId !== entry.offerId) return
        if (!entry.peer.remoteDescription) {
          entry.pendingIce.push(payload.candidate)
          return
        }
        try { await addCohostIceCandidate(entry.peer, payload.candidate) } catch {}
      })
      .on('broadcast', { event: 'cohost-ended' }, ({ payload }) => {
        if (!payload?.viewerId) return
        if (payload.viewerId === viewerId) clearSource()
        if (activeCohost?.viewerId === payload.viewerId || targetSourceIdRef.current === payload.viewerId) {
          closeTargetPeer()
          setActiveCohost(null)
        }
      })
      .subscribe()

    return () => {
      active = false
      if (localStreamRef.current) void send('cohost-source-left', { viewerId, userId })
      channelRef.current = null
      clearSource()
      closeTargetPeer()
      setActiveCohost(null)
      void removeLiveRelayChannel(channel)
    }
  }, [activeCohost?.viewerId, changeStatus, clearSource, closeTargetPeer, enabled, roomId, send, startSource, syncTargets, userId, viewerId])

  const requestCohost = useCallback(() => {
    if (statusRef.current !== 'idle' || !viewerId || !userId) return false
    const requestId = makeRequestId()
    changeStatus('requested')
    void send('cohost-request', {
      requestId,
      viewerId,
      userId,
      displayName,
      avatarUrl: avatarUrl || null,
    })
    return true
  }, [avatarUrl, changeStatus, displayName, send, userId, viewerId])

  const leaveCohost = useCallback(() => {
    if (!localStreamRef.current || !viewerId) return
    void send('cohost-source-left', { viewerId, userId })
    clearSource()
    setActiveCohost(null)
  }, [clearSource, send, userId, viewerId])

  return {
    status,
    localStream,
    remoteStream,
    activeCohost,
    requestCohost,
    leaveCohost,
  }
}

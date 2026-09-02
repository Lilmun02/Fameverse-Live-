import { useCallback, useEffect, useRef, useState } from 'react'
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

function serializeCandidate(candidate) {
  return candidate?.toJSON ? candidate.toJSON() : candidate
}

function makeInviteId() {
  if (globalThis.crypto?.randomUUID) return globalThis.crypto.randomUUID()
  return `${Date.now()}-${Math.random().toString(36).slice(2, 9)}`
}

export function useCohostHost({ roomId, enabled, viewerRoster = [], setToast }) {
  const channelRef = useRef(null)
  const peerRef = useRef(null)
  const offerIdRef = useRef(null)
  const pendingIceRef = useRef([])
  const activeRef = useRef(null)
  const viewerRosterRef = useRef(viewerRoster)
  const [requests, setRequests] = useState([])
  const [pendingInvite, setPendingInvite] = useState(null)
  const [activeCohost, setActiveCohost] = useState(null)
  const [remoteStream, setRemoteStream] = useState(null)
  const targetId = roomId ? `host:${roomId}` : null

  const send = useCallback((event, payload = {}) => {
    if (!channelRef.current) return Promise.resolve('error')
    return sendLiveRelayEvent(channelRef.current, event, payload)
  }, [])

  const clearPeer = useCallback(() => {
    closeCohostPeer(peerRef.current)
    peerRef.current = null
    offerIdRef.current = null
    pendingIceRef.current = []
    setRemoteStream(null)
  }, [])

  const clearActive = useCallback(() => {
    clearPeer()
    activeRef.current = null
    setActiveCohost(null)
    setPendingInvite(null)
  }, [clearPeer])

  const viewerIds = useCallback(() => (
    viewerRosterRef.current.map((viewer) => viewer.viewerId).filter(Boolean)
  ), [])

  const publishTargets = useCallback((cohost = activeRef.current) => {
    if (!cohost?.viewerId || !roomId || !targetId) return
    const targetIds = [targetId, ...viewerIds().filter((id) => id !== cohost.viewerId)]
    void send('cohost-peer-list', { viewerId: cohost.viewerId, targetIds })
  }, [roomId, send, targetId, viewerIds])

  useEffect(() => {
    viewerRosterRef.current = viewerRoster
    if (activeRef.current?.status === 'live') publishTargets(activeRef.current)
    const invitedViewerId = pendingInvite?.viewerId
    if (invitedViewerId && !viewerRoster.some((viewer) => viewer.viewerId === invitedViewerId)) {
      activeRef.current = null
      setPendingInvite(null)
    }
  }, [pendingInvite?.viewerId, publishTargets, viewerRoster])

  useEffect(() => {
    if (!enabled || !roomId) {
      setRequests([])
      clearActive()
      return undefined
    }

    let active = true
    const channel = createLiveRelayChannel(roomId)
    channelRef.current = channel

    const flushPendingIce = async (peer) => {
      const pending = pendingIceRef.current.splice(0)
      for (const candidate of pending) {
        try { await addCohostIceCandidate(peer, candidate) } catch {}
      }
    }

    const acceptOffer = async (payload) => {
      if (!active || payload?.targetId !== targetId || !payload?.offer || !payload?.offerId) return
      if (!activeRef.current || payload?.sourceViewerId !== activeRef.current.viewerId) return
      clearPeer()
      const offerId = payload.offerId
      offerIdRef.current = offerId

      const peer = createCohostPeer({
        iceServers: LIVE_RELAY_ICE_SERVERS,
        onIceCandidate: (candidate) => {
          void send('cohost-ice-target', {
            sourceViewerId: payload.sourceViewerId,
            targetId,
            offerId,
            candidate: serializeCandidate(candidate),
          })
        },
        onTrack: (event) => {
          if (!active || peerRef.current !== peer) return
          setRemoteStream(event.streams?.[0] || new MediaStream([event.track]))
        },
        onConnectionStateChange: (state) => {
          if (!active || peerRef.current !== peer) return
          if (state === 'failed' || state === 'closed') setRemoteStream(null)
        },
      })
      peerRef.current = peer

      try {
        const answer = await acceptCohostOffer(peer, payload.offer)
        await flushPendingIce(peer)
        if (!active || peerRef.current !== peer) return
        await send('cohost-answer', {
          sourceViewerId: payload.sourceViewerId,
          targetId,
          offerId,
          answer,
        })
      } catch {
        clearPeer()
      }
    }

    channel
      .on('broadcast', { event: 'cohost-request' }, ({ payload }) => {
        if (!active || !payload?.viewerId || !payload?.userId) return
        if (activeRef.current?.viewerId === payload.viewerId) return
        const request = {
          requestId: payload.requestId || payload.viewerId,
          viewerId: payload.viewerId,
          userId: payload.userId,
          displayName: payload.displayName || 'Fameverse viewer',
          avatarUrl: payload.avatarUrl || null,
        }
        setRequests((items) => [request, ...items.filter((item) => item.viewerId !== request.viewerId)].slice(0, 12))
      })
      .on('broadcast', { event: 'cohost-invite-accepted' }, ({ payload }) => {
        const invited = activeRef.current
        if (!invited || invited.status !== 'invited' || payload?.viewerId !== invited.viewerId) return
        setPendingInvite(null)
        const next = { ...invited, status: 'connecting' }
        activeRef.current = next
        setActiveCohost(next)
        publishTargets(next)
      })
      .on('broadcast', { event: 'cohost-invite-declined' }, ({ payload }) => {
        const invited = activeRef.current
        if (!invited || invited.status !== 'invited' || payload?.viewerId !== invited.viewerId) return
        activeRef.current = null
        setPendingInvite(null)
        setToast?.(`${invited.displayName || 'Viewer'} declined the co-host invite`)
      })
      .on('broadcast', { event: 'cohost-active' }, ({ payload }) => {
        if (!active || payload?.viewerId !== activeRef.current?.viewerId) return
        const next = { ...activeRef.current, status: 'live' }
        activeRef.current = next
        setPendingInvite(null)
        setActiveCohost(next)
        publishTargets(next)
      })
      .on('broadcast', { event: 'cohost-offer' }, ({ payload }) => {
        void acceptOffer(payload)
      })
      .on('broadcast', { event: 'cohost-ice-source' }, async ({ payload }) => {
        if (payload?.targetId !== targetId || payload?.sourceViewerId !== activeRef.current?.viewerId) return
        if (!payload?.candidate || payload?.offerId !== offerIdRef.current) return
        const peer = peerRef.current
        if (!peer?.remoteDescription) {
          pendingIceRef.current.push(payload.candidate)
          return
        }
        try { await addCohostIceCandidate(peer, payload.candidate) } catch {}
      })
      .on('broadcast', { event: 'cohost-source-left' }, ({ payload }) => {
        if (payload?.viewerId !== activeRef.current?.viewerId) return
        void send('cohost-ended', { viewerId: payload.viewerId })
        clearActive()
      })
      .on('broadcast', { event: 'cohost-failed' }, ({ payload }) => {
        if (payload?.viewerId !== activeRef.current?.viewerId) return
        setToast?.('Co-host could not start camera or microphone')
        void send('cohost-ended', { viewerId: payload.viewerId })
        clearActive()
      })
      .subscribe()

    return () => {
      active = false
      channelRef.current = null
      clearActive()
      setRequests([])
      void removeLiveRelayChannel(channel)
    }
  }, [clearActive, clearPeer, enabled, publishTargets, roomId, send, setToast, targetId])

  const inviteViewer = useCallback((viewer) => {
    if (!viewer?.viewerId || !viewer?.userId || activeRef.current) return false
    const invite = { ...viewer, inviteId: makeInviteId(), status: 'invited' }
    activeRef.current = invite
    setPendingInvite(invite)
    void send('cohost-invite', {
      inviteId: invite.inviteId,
      viewerId: invite.viewerId,
      userId: invite.userId,
    })
    return true
  }, [send])

  const cancelInvite = useCallback(() => {
    const invite = pendingInvite
    if (!invite) return
    void send('cohost-invite-cancelled', { viewerId: invite.viewerId, inviteId: invite.inviteId })
    activeRef.current = null
    setPendingInvite(null)
  }, [pendingInvite, send])

  const acceptRequest = useCallback((request) => {
    if (!request?.viewerId || activeRef.current) return false
    const next = { ...request, status: 'connecting' }
    activeRef.current = next
    setActiveCohost(next)
    setRequests((items) => items.filter((item) => item.viewerId !== request.viewerId))
    void send('cohost-accept', { viewerId: request.viewerId, requestId: request.requestId })
    publishTargets(next)
    return true
  }, [publishTargets, send])

  const declineRequest = useCallback((request) => {
    if (!request?.viewerId) return
    setRequests((items) => items.filter((item) => item.viewerId !== request.viewerId))
    void send('cohost-decline', { viewerId: request.viewerId, requestId: request.requestId })
  }, [send])

  const endCohost = useCallback(() => {
    const cohost = activeRef.current
    if (!cohost) return
    if (cohost.status === 'invited') {
      cancelInvite()
      return
    }
    void send('cohost-ended', { viewerId: cohost.viewerId })
    clearActive()
  }, [cancelInvite, clearActive, send])

  return {
    viewers: viewerRoster,
    requests,
    pendingInvite,
    activeCohost,
    remoteStream,
    inviteViewer,
    cancelInvite,
    acceptRequest,
    declineRequest,
    endCohost,
  }
}

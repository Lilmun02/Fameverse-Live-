import { useEffect, useMemo, useRef, useState } from 'react'
import LiveGiftTray from '../gifts/LiveGiftTray.jsx'
import CohostInvitePrompt from './CohostInvitePrompt.jsx'
import CohostVideoTile from './CohostVideoTile.jsx'
import LiveChat from './LiveChat.jsx'
import LiveProfileSheet from './LiveProfileSheet.jsx'
import { useCohostViewer } from '../../hooks/useCohostViewer.js'
import { useLiveProfileSheet } from '../../hooks/useLiveProfileSheet.js'
import { useLiveTapTotals } from '../../hooks/useLiveTapTotals.js'
import { useLiveViewer } from '../../hooks/useLiveViewer.js'
import { useViewerTapCapture } from '../../hooks/useViewerTapCapture.js'

const TAP_PARTICLE_LIFETIME_MS = 1250
const compactNumber = new Intl.NumberFormat('en-US', { notation: 'compact', maximumFractionDigits: 1 })

function formatStat(value) {
  const number = Number(value)
  return compactNumber.format(Number.isFinite(number) && number > 0 ? number : 0)
}

function stopLiveTap(event) {
  event.stopPropagation()
}

export default function ViewerLiveScreen({
  room,
  onClose,
  followNetwork,
  shareRoom,
  liveMessages,
  commentText,
  setCommentText,
  submitComment,
  giftTrayOpen,
  setGiftTrayOpen,
  coins,
  sendGift,
  addTestCoins,
  currentUserId,
  currentDisplayName,
  currentAvatarUrl,
  setToast,
}) {
  const videoRef = useRef(null)
  const particleIdRef = useRef(0)
  const particleTimersRef = useRef(new Set())
  const [needsPlay, setNeedsPlay] = useState(false)
  const [tapParticles, setTapParticles] = useState([])
  const [menuOpen, setMenuOpen] = useState(false)
  const profileSheet = useLiveProfileSheet()
  const relay = useLiveViewer({
    roomId: room?.id,
    enabled: Boolean(room?.id),
    userId: currentUserId,
    displayName: currentDisplayName,
    avatarUrl: currentAvatarUrl,
  })
  const cohost = useCohostViewer({
    roomId: room?.id,
    viewerId: relay.viewerId,
    userId: currentUserId,
    displayName: currentDisplayName,
    avatarUrl: currentAvatarUrl,
    enabled: Boolean(room?.id && currentUserId),
    setToast,
  })
  const totals = useLiveTapTotals({ roomId: room?.id })
  const capture = useViewerTapCapture({ roomId: room?.id })
  const hostLabel = room?.host?.username
    ? `@${room.host.username}`
    : room?.host?.displayName || 'Fameverse creator'
  const hostName = room?.host?.displayName || hostLabel
  const hostInitial = hostName.trim().charAt(0).toUpperCase() || 'F'
  const hostAvatar = room?.host?.avatarUrl || null
  const serverTotal = Math.max(totals.rawTaps, Number(capture.lastResult?.totalRawTaps || 0))
  const ended = relay.state === 'ended' || capture.lastResult?.reasons?.includes('inactive_live_session')
  const cohostStream = cohost.localStream || cohost.remoteStream
  const isSelfCohost = Boolean(cohost.localStream)
  const hasDirectHostAudio = Boolean(isSelfCohost && cohost.directHostStream?.getAudioTracks?.().length)
  const isFollowing = useMemo(
    () => Boolean(followNetwork?.following?.some((profile) => profile.id === room?.host_user_id)),
    [followNetwork?.following, room?.host_user_id],
  )

  useEffect(() => {
    const video = videoRef.current
    if (!video) return
    video.srcObject = relay.remoteStream || null
    if (!relay.remoteStream) {
      setNeedsPlay(false)
      return
    }

    video.play()
      .then(() => setNeedsPlay(false))
      .catch(() => setNeedsPlay(true))
  }, [relay.remoteStream])

  useEffect(() => () => {
    particleTimersRef.current.forEach((timer) => window.clearTimeout(timer))
    particleTimersRef.current.clear()
  }, [])

  const playVideo = () => {
    videoRef.current?.play?.()
      .then(() => setNeedsPlay(false))
      .catch(() => setNeedsPlay(true))
  }

  const spawnTapParticles = (event) => {
    const rect = event.currentTarget.getBoundingClientRect()
    const baseX = event.clientX - rect.left
    const baseY = event.clientY - rect.top
    const seed = particleIdRef.current++
    const nextParticles = [
      { id: `${seed}-f`, symbol: 'F', x: baseX - 9, y: baseY - 5, drift: -26, delay: 0 },
      { id: `${seed}-fire`, symbol: '🔥', x: baseX + 8, y: baseY + 2, drift: 22, delay: 70 },
    ]

    setTapParticles((items) => [...items.slice(-22), ...nextParticles])
    const timer = window.setTimeout(() => {
      setTapParticles((items) => items.filter((item) => !nextParticles.some((particle) => particle.id === item.id)))
      particleTimersRef.current.delete(timer)
    }, TAP_PARTICLE_LIFETIME_MS)
    particleTimersRef.current.add(timer)
  }

  const onTap = (event) => {
    if (event.pointerType === 'mouse' && event.button !== 0) return
    if (relay.state !== 'connected' || ended) return
    setMenuOpen(false)
    playVideo()
    capture.tap()
    spawnTapParticles(event)
  }

  const toggleFollow = () => {
    if (!room?.host_user_id || followNetwork?.busyTargetId === room.host_user_id) return
    void followNetwork?.toggleFollow?.(room.host_user_id)
  }

  const openHostProfile = () => {
    if (room?.host_user_id) profileSheet.open(room.host_user_id)
  }

  const shareLive = () => {
    setMenuOpen(false)
    void shareRoom?.()
  }

  const requestCohost = () => {
    if (cohost.requestCohost()) setMenuOpen(false)
  }

  const leaveCohost = () => {
    cohost.leaveCohost()
    setMenuOpen(false)
  }

  const openGiftTray = () => {
    setMenuOpen(false)
    setGiftTrayOpen(true)
  }

  const cohostMenuLabel = cohost.status === 'requested'
    ? 'Request sent'
    : cohost.status === 'connecting'
      ? 'Joining co-host…'
      : cohost.status === 'declined'
        ? 'Request declined'
        : 'Request co-host'

  return (
    <section className={`fv-viewer-live ${cohostStream ? 'has-cohost' : ''}`} aria-label={`Watching ${hostLabel} live`}>
      <div className="fv-viewer-live-stage" onPointerDown={onTap}>
        <video
          ref={videoRef}
          autoPlay
          playsInline
          muted={hasDirectHostAudio}
          className="fv-viewer-live-video"
        />
        <CohostVideoTile
          stream={cohostStream}
          label={cohost.activeCohost?.displayName || 'Co-host'}
          local={isSelfCohost}
          audioReturnStream={isSelfCohost ? cohost.directHostStream : null}
        />
        <div className="fv-viewer-live-vignette" aria-hidden="true" />

        {!relay.remoteStream && !ended && (
          <div className="fv-viewer-live-connecting" aria-live="polite">
            <span className="fv-viewer-live-pulse" aria-hidden="true" />
            <strong>{relay.state === 'degraded' ? 'Reconnecting…' : 'Connecting to Live…'}</strong>
            <small>Opening the creator’s live camera and audio.</small>
          </div>
        )}

        {ended && (
          <div className="fv-viewer-live-ended">
            <strong>This Live ended</strong>
            <small>Return to Discover to find another live creator.</small>
            <button type="button" onPointerDown={stopLiveTap} onClick={onClose}>Back to Discover</button>
          </div>
        )}

        {needsPlay && !ended && (
          <button
            type="button"
            className="fv-viewer-live-play"
            onPointerDown={stopLiveTap}
            onClick={playVideo}
          >
            Tap to play Live
          </button>
        )}

        <div className="fv-viewer-live-particles" aria-hidden="true">
          {tapParticles.map((particle) => (
            <span
              key={particle.id}
              className={`fv-viewer-tap-particle ${particle.symbol === 'F' ? 'is-f' : 'is-fire'}`}
              style={{
                left: `${particle.x}px`,
                top: `${particle.y}px`,
                '--tap-drift': `${particle.drift}px`,
                '--tap-delay': `${particle.delay}ms`,
              }}
            >
              {particle.symbol}
            </span>
          ))}
        </div>

        <header className="fv-viewer-live-header" onPointerDown={stopLiveTap}>
          <button type="button" className="fv-viewer-live-back" onClick={onClose} aria-label="Back to Discover">‹</button>

          <div className="fv-viewer-live-creator">
            <button
              type="button"
              className="fv-viewer-identity-button"
              onPointerDown={stopLiveTap}
              onClick={openHostProfile}
              aria-label={`Open ${hostName} profile`}
            >
              {hostAvatar ? (
                <img className="fv-viewer-live-avatar" src={hostAvatar} alt="" />
              ) : (
                <span className="fv-viewer-live-avatar fv-viewer-live-avatar-fallback">{hostInitial}</span>
              )}
            </button>
            <div className="fv-viewer-live-identity">
              <div className="fv-viewer-live-name-row">
                <button
                  type="button"
                  className="fv-viewer-identity-button"
                  onPointerDown={stopLiveTap}
                  onClick={openHostProfile}
                >
                  <strong>{hostName}</strong>
                </button>
                <span className="fv-viewer-live-badge">LIVE</span>
              </div>
              <button
                type="button"
                className={`fv-viewer-follow ${isFollowing ? 'is-following' : ''}`}
                onPointerDown={stopLiveTap}
                onClick={toggleFollow}
                disabled={followNetwork?.busyTargetId === room?.host_user_id}
              >
                {isFollowing ? '✓ Following' : '+ Follow'}
              </button>
            </div>
          </div>

          <div className="fv-viewer-live-stats" aria-label={`${relay.viewerCount} viewers and ${serverTotal} Fame Taps`}>
            <span><b aria-hidden="true">👥</b>{formatStat(relay.viewerCount)}</span>
            <i aria-hidden="true" />
            <span className="is-fame"><b aria-hidden="true">F</b>{formatStat(serverTotal)}</span>
          </div>
        </header>

        {!ended && (
          <div className="fv-viewer-live-chat-layer" onPointerDown={stopLiveTap}>
            <LiveChat
              liveMessages={liveMessages}
              commentText={commentText}
              setCommentText={setCommentText}
              submitComment={submitComment}
              onGiftClick={openGiftTray}
              onOpenIdentity={profileSheet.open}
            />
          </div>
        )}

        {!ended && (
          <div className="fv-viewer-live-more" onPointerDown={stopLiveTap}>
            {menuOpen && (
              <div className="fv-viewer-live-menu" role="menu" aria-label="Live options">
                {isSelfCohost ? (
                  <button type="button" role="menuitem" onPointerDown={stopLiveTap} onClick={leaveCohost}>
                    <span aria-hidden="true">◫</span>
                    <b>Leave co-host</b>
                  </button>
                ) : (
                  <button
                    type="button"
                    role="menuitem"
                    onPointerDown={stopLiveTap}
                    onClick={requestCohost}
                    disabled={cohost.status !== 'idle' || Boolean(cohost.activeCohost) || Boolean(cohost.incomingInvite)}
                  >
                    <span aria-hidden="true">◫</span>
                    <b>{cohost.activeCohost && cohost.status === 'idle' ? 'Co-host occupied' : cohostMenuLabel}</b>
                  </button>
                )}
                <button type="button" role="menuitem" onPointerDown={stopLiveTap} onClick={shareLive}>
                  <span aria-hidden="true">↗</span>
                  <b>Share Live</b>
                </button>
              </div>
            )}
            <button
              type="button"
              className="fv-viewer-live-f-menu"
              aria-label="Open Fameverse Live menu"
              aria-expanded={menuOpen}
              onPointerDown={stopLiveTap}
              onClick={() => setMenuOpen((open) => !open)}
            >
              F
            </button>
          </div>
        )}
      </div>

      <CohostInvitePrompt
        invite={cohost.incomingInvite}
        hostName={hostName}
        onAccept={cohost.acceptInvite}
        onDecline={cohost.declineInvite}
      />

      <LiveProfileSheet
        sheet={profileSheet}
        currentUserId={currentUserId}
        followNetwork={followNetwork}
      />

      <LiveGiftTray
        open={giftTrayOpen}
        onClose={() => setGiftTrayOpen(false)}
        coins={coins}
        sendGift={sendGift}
        addTestCoins={addTestCoins}
      />
    </section>
  )
}

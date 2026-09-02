import { useEffect, useMemo, useRef, useState } from 'react'
import LiveGiftTray from '../gifts/LiveGiftTray.jsx'
import LiveChat from './LiveChat.jsx'
import { useLiveTapTotals } from '../../hooks/useLiveTapTotals.js'
import { useLiveViewer } from '../../hooks/useLiveViewer.js'
import { useViewerTapCapture } from '../../hooks/useViewerTapCapture.js'

const TAP_PARTICLE_LIFETIME_MS = 1250

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
}) {
  const videoRef = useRef(null)
  const particleIdRef = useRef(0)
  const particleTimersRef = useRef(new Set())
  const [needsPlay, setNeedsPlay] = useState(false)
  const [tapParticles, setTapParticles] = useState([])
  const relay = useLiveViewer({ roomId: room?.id, enabled: Boolean(room?.id) })
  const totals = useLiveTapTotals({ roomId: room?.id })
  const capture = useViewerTapCapture({ roomId: room?.id })
  const hostLabel = room?.host?.username
    ? `@${room.host.username}`
    : room?.host?.displayName || 'Fameverse creator'
  const hostName = room?.host?.displayName || hostLabel
  const hostInitial = hostName.trim().charAt(0).toUpperCase() || 'F'
  const serverTotal = Math.max(totals.rawTaps, Number(capture.lastResult?.totalRawTaps || 0))
  const ended = relay.state === 'ended' || capture.lastResult?.reasons?.includes('inactive_live_session')
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
    playVideo()
    capture.tap()
    spawnTapParticles(event)
  }

  const toggleFollow = () => {
    if (!room?.host_user_id) return
    void followNetwork?.toggleFollow?.(room.host_user_id)
  }

  return (
    <section className="fv-viewer-live" aria-label={`Watching ${hostLabel} live`}>
      <div className="fv-viewer-live-stage" onPointerDown={onTap}>
        <video ref={videoRef} autoPlay playsInline className="fv-viewer-live-video" />
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
            <button type="button" onPointerDown={(event) => event.stopPropagation()} onClick={onClose}>Back to Discover</button>
          </div>
        )}

        {needsPlay && !ended && (
          <button
            type="button"
            className="fv-viewer-live-play"
            onPointerDown={(event) => event.stopPropagation()}
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

        <header className="fv-viewer-live-header" onPointerDown={(event) => event.stopPropagation()}>
          <button type="button" className="fv-viewer-live-back" onClick={onClose} aria-label="Back to Discover">‹</button>
          <div className="fv-viewer-live-creator">
            <span className="fv-viewer-live-avatar">{hostInitial}</span>
            <div className="fv-viewer-live-identity">
              <div><strong>{hostName}</strong><span>LIVE</span></div>
              <small>{room?.title || hostLabel}</small>
            </div>
          </div>
          <div className="fv-viewer-live-header-actions">
            <button
              type="button"
              className={`fv-viewer-follow ${isFollowing ? 'is-following' : ''}`}
              onClick={toggleFollow}
              disabled={followNetwork?.busyTargetId === room?.host_user_id}
            >
              {isFollowing ? 'Following' : 'Follow'}
            </button>
            <b className="fv-viewer-live-total" aria-label={`${serverTotal} Fame Taps`}>♥ {serverTotal}</b>
          </div>
        </header>

        {!ended && (
          <aside className="fv-viewer-live-actions" onPointerDown={(event) => event.stopPropagation()} aria-label="Live actions">
            <button type="button" onClick={() => setGiftTrayOpen(true)}><span>🎁</span><small>Gift</small></button>
            <button type="button" onClick={shareRoom}><span>↗</span><small>Share</small></button>
          </aside>
        )}

        {!ended && (
          <div className="fv-viewer-live-chat-layer" onPointerDown={(event) => event.stopPropagation()}>
            <LiveChat
              liveMessages={liveMessages}
              commentText={commentText}
              setCommentText={setCommentText}
              submitComment={submitComment}
            />
          </div>
        )}
      </div>

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

import { useEffect, useMemo, useRef, useState } from 'react'
import LiveGiftTray from '../gifts/LiveGiftTray.jsx'
import LiveChat from './LiveChat.jsx'
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
}) {
  const videoRef = useRef(null)
  const particleIdRef = useRef(0)
  const particleTimersRef = useRef(new Set())
  const [needsPlay, setNeedsPlay] = useState(false)
  const [tapParticles, setTapParticles] = useState([])
  const [menuOpen, setMenuOpen] = useState(false)
  const relay = useLiveViewer({ roomId: room?.id, enabled: Boolean(room?.id) })
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

  const shareLive = () => {
    setMenuOpen(false)
    void shareRoom?.()
  }

  const openGiftTray = () => {
    setMenuOpen(false)
    setGiftTrayOpen(true)
  }

  return (
    <section className="fv-viewer-live" aria-label={`Watching ${hostLabel} live`}>
      <div className="fv-viewer-live-stage" onPointerDown={onTap}>
        <video ref={videoRef} autoPlay playsInline className="fv-viewer-live-video" />
        <div className="fv-viewer-live-vignette" aria-hidden="true" />
        <div className={`fv-live-stage-brand ${relay.remoteStream && !ended ? 'is-dim' : ''}`} aria-hidden="true">
          <span className="fv-live-stage-arch" />
          <small>LIVE ON FAMEVERSE</small>
          <strong>{hostName}</strong>
          <em>{room?.title || 'Late Night Vibes'}</em>
          <span className="fv-live-stage-rule">F</span>
          <i>MUSIC. ENERGY. COMMUNITY.</i>
        </div>
        <div className="fv-live-fall" aria-hidden="true">
          {['F', '🔥', 'F', '🔥', 'F', '🔥', 'F', '🔥'].map((symbol, index) => (
            <span key={`fall-${index}`} className={symbol === 'F' ? 'is-f' : 'is-fire'} style={{ '--fall-i': index }}>
              {symbol}
            </span>
          ))}
        </div>

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
            {hostAvatar ? (
              <img className="fv-viewer-live-avatar" src={hostAvatar} alt="" />
            ) : (
              <span className="fv-viewer-live-avatar fv-viewer-live-avatar-fallback">{hostInitial}</span>
            )}
            <div className="fv-viewer-live-identity">
              <div className="fv-viewer-live-name-row">
                <strong>{hostName}</strong>
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
            <span className="is-fame"><b aria-hidden="true">🔥</b>{formatStat(serverTotal)}</span>
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
            />
          </div>
        )}

        {!ended && (
          <div className="fv-viewer-live-more" onPointerDown={stopLiveTap}>
            {menuOpen && (
              <div className="fv-viewer-live-menu" role="menu" aria-label="Live options">
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

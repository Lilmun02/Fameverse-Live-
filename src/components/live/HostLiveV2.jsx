import { useEffect, useRef, useState } from 'react'
import { gifts as giftCatalog } from '../../config/gifts.js'
import { useLiveProfileSheet } from '../../hooks/useLiveProfileSheet.js'
import LiveGiftTray from '../gifts/LiveGiftTray.jsx'
import CohostSheet from './CohostSheet.jsx'
import CohostVideoTile from './CohostVideoTile.jsx'
import EndLiveSummaryPanel from './EndLiveSummaryPanel.jsx'
import LiveProfileSheet from './LiveProfileSheet.jsx'
import LiveViewerSheet from './LiveViewerSheet.jsx'
import PreLiveSetupPanel from './PreLiveSetupPanel.jsx'

const ROSE_GIFT = giftCatalog.find((gift) => gift.id === 'rose')

function compactCount(value) {
  const count = Math.max(0, Number(value) || 0)
  if (count < 1000) return String(count)
  if (count < 1_000_000) return `${(count / 1000).toFixed(count >= 10_000 ? 0 : 1).replace('.0', '')}K`
  return `${(count / 1_000_000).toFixed(count >= 10_000_000 ? 0 : 1).replace('.0', '')}M`
}

function initialFor(value) {
  return String(value || 'F').trim().charAt(0).toUpperCase() || 'F'
}

function PurpleRoseIcon() {
  return (
    <svg viewBox="0 0 32 32" aria-hidden="true">
      <path d="M16 4c5 0 8 2.9 8 6.3 0 4.5-4.7 7.3-8 9.6-3.3-2.3-8-5.1-8-9.6C8 6.9 11 4 16 4Z" />
      <path d="M16 19.5v8.2M16 23c-3.7-.4-6.2-2-7.6-4.7M16 24.6c3-.2 5.5-1.4 7.3-3.7" />
    </svg>
  )
}

function ViewerIcon() {
  return (
    <svg viewBox="0 0 24 24" aria-hidden="true">
      <path d="M2.5 12s3.5-6 9.5-6 9.5 6 9.5 6-3.5 6-9.5 6-9.5-6-9.5-6Z" />
      <circle cx="12" cy="12" r="2.8" />
    </svg>
  )
}

export default function HostLiveV2({
  isLive,
  mediaStream,
  cameraOff,
  activeVideoSlot,
  videoSlotFacing,
  videoPrimaryRef,
  videoSecondaryRef,
  displayName,
  username,
  initial,
  avatarUrl,
  viewerCount,
  tapCount,
  isStartingLive,
  startLive,
  liveSetup,
  sessionSummary,
  setGiftTrayOpen,
  micMuted,
  toggleMic,
  toggleCamera,
  flipCamera,
  shareRoom,
  liveMessages,
  commentText,
  setCommentText,
  submitComment,
  giftTrayOpen,
  coins,
  sendGift,
  addTestCoins,
  cohostTrayOpen,
  setCohostTrayOpen,
  cohost,
  currentUserId,
  followNetwork,
}) {
  const [fMenuOpen, setFMenuOpen] = useState(false)
  const [viewerSheetOpen, setViewerSheetOpen] = useState(false)
  const chatRef = useRef(null)
  const profileSheet = useLiveProfileSheet()
  const cohostStream = cohost?.remoteStream || null

  useEffect(() => {
    const node = chatRef.current
    if (node) node.scrollTop = node.scrollHeight
  }, [liveMessages])

  useEffect(() => {
    if (!isLive) setFMenuOpen(false)
  }, [isLive])

  if (!isLive && sessionSummary.summary) {
    return <EndLiveSummaryPanel summary={sessionSummary.summary} onDone={sessionSummary.dismissSummary} />
  }

  if (!isLive) {
    return (
      <PreLiveSetupPanel
        displayName={displayName}
        username={username}
        initial={initial}
        draft={liveSetup.draft}
        updateField={liveSetup.updateField}
        toggleWishlistGift={liveSetup.toggleWishlistGift}
        beginLive={() => liveSetup.beginLive(startLive)}
        isStartingLive={isStartingLive}
      />
    )
  }

  const quickRose = () => {
    if (ROSE_GIFT) void sendGift(ROSE_GIFT, 1)
  }

  return (
    <section className={`fv2-host-live ${cohostStream ? 'has-cohost' : ''}`} aria-label="Famaverse Live host room">
      <div className="fv2-stage" aria-hidden={cameraOff ? 'true' : 'false'}>
        {mediaStream && !cameraOff ? (
          <>
            <video ref={videoPrimaryRef} className={`fv2-video ${activeVideoSlot === 0 ? 'is-active' : ''} ${videoSlotFacing[0] === 'user' ? 'is-mirrored' : ''}`} autoPlay muted playsInline />
            <video ref={videoSecondaryRef} className={`fv2-video ${activeVideoSlot === 1 ? 'is-active' : ''} ${videoSlotFacing[1] === 'user' ? 'is-mirrored' : ''}`} autoPlay muted playsInline />
          </>
        ) : (
          <div className="fv2-camera-off"><strong>Camera off</strong><span>Your microphone can stay on.</span></div>
        )}
        <CohostVideoTile stream={cohostStream} label={cohost?.activeCohost?.displayName || 'Co-host'} />
      </div>

      <header className="fv2-topbar">
        <button type="button" className="fv2-identity" onClick={() => profileSheet.open(currentUserId)}>
          <span className="fv2-avatar">
            {avatarUrl ? <img src={avatarUrl} alt="" /> : <span>{initial}</span>}
          </span>
          <span className="fv2-identity-copy">
            <span className="fv2-name-row">
              <strong>{displayName}</strong>
              <span className="fv2-verified" aria-label="Verified">✓</span>
              <span className="fv2-live-badge">LIVE</span>
            </span>
            <small>{liveSetup.active?.title || 'Live session'}</small>
          </span>
        </button>

        <div className="fv2-top-actions">
          <button type="button" className="fv2-stats" onClick={() => setViewerSheetOpen(true)} aria-label={`${tapCount} Fame taps and ${viewerCount} viewers`}>
            <span className="fv2-famtaps"><b>F</b>{compactCount(tapCount)}</span>
            <span className="fv2-stat-divider" />
            <span className="fv2-viewers"><ViewerIcon />{compactCount(viewerCount)}</span>
          </button>
          <button type="button" className="fv2-end" disabled={isStartingLive} onClick={startLive}>End</button>
        </div>
      </header>

      {liveMessages.length > 0 && (
        <div className="fv2-chat" ref={chatRef} aria-label="Live comments">
          {liveMessages.map((item) => (
            <div className={`fv2-chat-line ${item.kind === 'gift' ? 'is-gift' : ''}`} key={item.id}>
              <span className="fv2-chat-avatar">{initialFor(item.user)}</span>
              <span className="fv2-chat-copy">
                <strong>{item.user}</strong>
                <span>{item.kind === 'gift' ? `sent ${Math.max(1, Number(item.quantity) || 1)} gift${Number(item.quantity) === 1 ? '' : 's'}` : item.text}</span>
              </span>
            </div>
          ))}
        </div>
      )}

      {fMenuOpen && (
        <div className="fv2-f-menu" role="menu" aria-label="F menu">
          <button type="button" onClick={flipCamera}>Flip camera</button>
          <button type="button" onClick={toggleMic}>{micMuted ? 'Unmute mic' : 'Mute mic'}</button>
          <button type="button" onClick={toggleCamera}>{cameraOff ? 'Turn camera on' : 'Turn camera off'}</button>
          <button type="button" onClick={() => { setFMenuOpen(false); setCohostTrayOpen(true) }}>Co-host</button>
        </div>
      )}

      <form className="fv2-composer" onSubmit={submitComment}>
        <div className="fv2-comment-entry">
          <input value={commentText} onChange={(event) => setCommentText(event.target.value)} maxLength={160} enterKeyHint="send" placeholder="Say something..." aria-label="Add comment" />
          <span className="fv2-smile" aria-hidden="true">☺</span>
        </div>
        <button type="button" className="fv2-control fv2-rose" aria-label="Send Rose" onClick={quickRose}><PurpleRoseIcon /></button>
        <button type="button" className="fv2-control" aria-label="Open gifts" onClick={() => setGiftTrayOpen(true)}>🎁</button>
        <button type="button" className="fv2-control fv2-share" aria-label="Share Live" onClick={shareRoom}>➤</button>
        <button type="button" className={`fv2-f-button ${fMenuOpen ? 'is-open' : ''}`} aria-label="Open F menu" aria-expanded={fMenuOpen} onClick={() => setFMenuOpen((open) => !open)}>F</button>
      </form>

      <LiveViewerSheet open={viewerSheetOpen} onClose={() => setViewerSheetOpen(false)} viewers={cohost?.viewers || []} onOpenIdentity={(userId) => { setViewerSheetOpen(false); profileSheet.open(userId) }} />
      <LiveProfileSheet sheet={profileSheet} currentUserId={currentUserId} followNetwork={followNetwork} />
      <CohostSheet
        open={cohostTrayOpen}
        onClose={() => setCohostTrayOpen(false)}
        shareRoom={shareRoom}
        viewers={cohost?.viewers || []}
        requests={cohost?.requests || []}
        pendingInvite={cohost?.pendingInvite || null}
        activeCohost={cohost?.activeCohost || null}
        onInvite={cohost?.inviteViewer}
        onCancelInvite={cohost?.cancelInvite}
        onAccept={cohost?.acceptRequest}
        onDecline={cohost?.declineRequest}
        onEndCohost={cohost?.endCohost}
      />
      <LiveGiftTray open={giftTrayOpen} onClose={() => setGiftTrayOpen(false)} coins={coins} sendGift={sendGift} addTestCoins={addTestCoins} />
    </section>
  )
}

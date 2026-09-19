import { useEffect, useState } from 'react'
import LiveGiftTray from '../gifts/LiveGiftTray.jsx'
import CohostVideoTile from './CohostVideoTile.jsx'
import EndLiveSummaryPanel from './EndLiveSummaryPanel.jsx'
import LiveActions from './LiveActions.jsx'
import LiveChat from './LiveChat.jsx'
import LiveHeader from './LiveHeader.jsx'
import LiveProfileSheet from './LiveProfileSheet.jsx'
import LiveViewerSheet from './LiveViewerSheet.jsx'
import PreLiveSetupPanel from './PreLiveSetupPanel.jsx'
import { useLiveProfileSheet } from '../../hooks/useLiveProfileSheet.js'

export default function LiveScreen({
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
  viewerCount,
  tapCount,
  isStartingLive,
  startLive,
  liveSetup,
  sessionSummary,
  premiumRepeat,
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
  cohost,
  presenceState,
  currentUserId,
  followNetwork,
}) {
  const [viewerSheetOpen, setViewerSheetOpen] = useState(false)
  const profileSheet = useLiveProfileSheet()
  const cohostStream = cohost?.remoteStream || null

  /*
   * One-PWA law: media lifecycle recovery is shared by every installed PWA.
   * There is no iOS/Safari shell, UA branch, viewport geometry override, or
   * device-specific presentation path here. Android and iPhone execute this
   * exact same recovery path and the CSS shell owns all geometry.
   */
  useEffect(() => {
    if (!isLive || cohostStream) return undefined

    let firstFrame = 0
    let secondFrame = 0
    let settleTimer = 0

    const getActiveVideo = () => activeVideoSlot === 0 ? videoPrimaryRef.current : videoSecondaryRef.current

    const restoreMediaLayer = () => {
      window.cancelAnimationFrame(firstFrame)
      window.cancelAnimationFrame(secondFrame)
      window.clearTimeout(settleTimer)

      const activeVideo = getActiveVideo()
      if (!activeVideo || !mediaStream || cameraOff) return

      activeVideo.pause?.()
      activeVideo.srcObject = null

      firstFrame = window.requestAnimationFrame(() => {
        secondFrame = window.requestAnimationFrame(() => {
          const currentVideo = getActiveVideo()
          if (!currentVideo || !mediaStream || cameraOff) return
          currentVideo.srcObject = mediaStream
          currentVideo.play?.().catch?.(() => {})
        })
      })

      settleTimer = window.setTimeout(() => {
        const currentVideo = getActiveVideo()
        if (currentVideo && mediaStream && !cameraOff) {
          if (currentVideo.srcObject !== mediaStream) currentVideo.srcObject = mediaStream
          currentVideo.play?.().catch?.(() => {})
        }
      }, 240)
    }

    const onVisibilityChange = () => {
      if (document.visibilityState === 'visible') restoreMediaLayer()
    }
    const onPageShow = () => restoreMediaLayer()
    const onFocus = () => {
      if (document.visibilityState === 'visible') restoreMediaLayer()
    }

    document.addEventListener('visibilitychange', onVisibilityChange)
    window.addEventListener('pageshow', onPageShow)
    window.addEventListener('focus', onFocus)

    return () => {
      window.cancelAnimationFrame(firstFrame)
      window.cancelAnimationFrame(secondFrame)
      window.clearTimeout(settleTimer)
      document.removeEventListener('visibilitychange', onVisibilityChange)
      window.removeEventListener('pageshow', onPageShow)
      window.removeEventListener('focus', onFocus)
    }
  }, [isLive, cohostStream, activeVideoSlot, mediaStream, cameraOff, videoPrimaryRef, videoSecondaryRef])

  const openViewerProfile = (userId) => {
    setViewerSheetOpen(false)
    profileSheet.open(userId)
  }

  if (!isLive && sessionSummary.summary) {
    return (
      <EndLiveSummaryPanel
        summary={sessionSummary.summary}
        onDone={sessionSummary.dismissSummary}
      />
    )
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

  return (
    <section className={`mobile-live-shell fam-live-shell is-live ${cohostStream ? 'has-cohost' : ''}`}>
      <div className="live-video-surface fam-live-video-surface">
        {mediaStream && !cameraOff ? (
          <>
            <video ref={videoPrimaryRef} className={`host-video immersive-video ${activeVideoSlot === 0 ? 'active' : 'inactive'} ${videoSlotFacing[0] === 'user' ? 'mirror' : ''}`} autoPlay muted playsInline />
            <video ref={videoSecondaryRef} className={`host-video immersive-video ${activeVideoSlot === 1 ? 'active' : 'inactive'} ${videoSlotFacing[1] === 'user' ? 'mirror' : ''}`} autoPlay muted playsInline />
          </>
        ) : (
          <div className="camera-off-placeholder fam-camera-off">
            <div className="preview-camera-icon">◉</div><strong>Camera off</strong><small>Your microphone can stay on while video is hidden.</small>
          </div>
        )}
        <CohostVideoTile stream={cohostStream} label={cohost?.activeCohost?.displayName || 'Co-host'} />
        <div className="live-vignette fam-live-vignette" />
      </div>

      <LiveHeader
        isLive
        initial={initial}
        displayName={displayName}
        username={username}
        viewerCount={viewerCount}
        tapCount={tapCount}
        startLive={startLive}
        liveTitle={liveSetup.active?.title}
        presenceState={presenceState}
        currentUserId={currentUserId}
        onOpenIdentity={profileSheet.open}
        onOpenViewers={() => setViewerSheetOpen(true)}
      />

      <LiveActions
        premiumRepeat={premiumRepeat}
        cohost={cohost}
        micMuted={micMuted}
        toggleMic={toggleMic}
        cameraOff={cameraOff}
        toggleCamera={toggleCamera}
        flipCamera={flipCamera}
        isStartingLive={isStartingLive}
        shareRoom={shareRoom}
      />

      <LiveChat
        liveMessages={liveMessages}
        commentText={commentText}
        setCommentText={setCommentText}
        submitComment={submitComment}
        onGiftClick={() => setGiftTrayOpen(true)}
        onOpenIdentity={profileSheet.open}
      />

      <LiveViewerSheet
        open={viewerSheetOpen}
        onClose={() => setViewerSheetOpen(false)}
        viewers={cohost?.viewers || []}
        onOpenIdentity={openViewerProfile}
      />

      <LiveProfileSheet
        sheet={profileSheet}
        currentUserId={currentUserId}
        followNetwork={followNetwork}
      />

      <LiveGiftTray open={giftTrayOpen} onClose={() => setGiftTrayOpen(false)} coins={coins} sendGift={sendGift} addTestCoins={addTestCoins} />
    </section>
  )
}

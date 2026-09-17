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

const IOS_LIVE_STYLE_PROPS = [
  'position', 'inset', 'top', 'right', 'bottom', 'left', 'width', 'height',
  'min-width', 'min-height', 'max-width', 'max-height', 'aspect-ratio',
  'object-fit', 'object-position', 'display', 'overflow', 'contain',
]

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

  useEffect(() => {
    if (!isLive || cohostStream) return undefined

    const standalone = window.matchMedia?.('(display-mode: standalone)')?.matches || window.navigator.standalone === true
    const isiOSWebKit = /iP(ad|hone|od)/.test(window.navigator.userAgent) && /WebKit/i.test(window.navigator.userAgent)
    if (!standalone || !isiOSWebKit) return undefined

    let firstFrame = 0
    let secondFrame = 0
    let settleTimer = 0

    const getActiveVideo = () => activeVideoSlot === 0 ? videoPrimaryRef.current : videoSecondaryRef.current

    const getViewportHeight = () => {
      const height = Math.round(window.visualViewport?.height || window.innerHeight || 0)
      return height > 0 ? height : 0
    }

    const applyStandaloneGeometry = () => {
      const viewportHeight = getViewportHeight()
      if (!viewportHeight) return

      document.documentElement.style.setProperty('--fv-visible-viewport-height', `${viewportHeight}px`)

      const activeVideo = getActiveVideo()
      const surface = activeVideo?.closest?.('.fam-live-video-surface')
      if (surface) {
        surface.style.setProperty('position', 'fixed', 'important')
        surface.style.setProperty('inset', '0', 'important')
        surface.style.setProperty('width', '100vw', 'important')
        surface.style.setProperty('height', `${viewportHeight}px`, 'important')
        surface.style.setProperty('min-width', '100vw', 'important')
        surface.style.setProperty('min-height', `${viewportHeight}px`, 'important')
        surface.style.setProperty('max-width', 'none', 'important')
        surface.style.setProperty('max-height', 'none', 'important')
        surface.style.setProperty('overflow', 'hidden', 'important')
        surface.style.setProperty('contain', 'layout paint', 'important')
      }

      if (activeVideo) {
        activeVideo.style.setProperty('position', 'fixed', 'important')
        activeVideo.style.setProperty('inset', '0', 'important')
        activeVideo.style.setProperty('width', '100vw', 'important')
        activeVideo.style.setProperty('height', `${viewportHeight}px`, 'important')
        activeVideo.style.setProperty('min-width', '100vw', 'important')
        activeVideo.style.setProperty('min-height', `${viewportHeight}px`, 'important')
        activeVideo.style.setProperty('max-width', 'none', 'important')
        activeVideo.style.setProperty('max-height', 'none', 'important')
        activeVideo.style.setProperty('aspect-ratio', 'auto', 'important')
        activeVideo.style.setProperty('object-fit', 'cover', 'important')
        activeVideo.style.setProperty('object-position', 'center center', 'important')
        activeVideo.style.setProperty('display', 'block', 'important')
      }
    }

    const restoreMediaLayer = () => {
      window.cancelAnimationFrame(firstFrame)
      window.cancelAnimationFrame(secondFrame)
      window.clearTimeout(settleTimer)

      applyStandaloneGeometry()

      const activeVideo = getActiveVideo()
      if (!activeVideo || !mediaStream || cameraOff) return

      activeVideo.pause?.()
      activeVideo.srcObject = null
      void activeVideo.offsetHeight

      firstFrame = window.requestAnimationFrame(() => {
        applyStandaloneGeometry()
        secondFrame = window.requestAnimationFrame(() => {
          const currentVideo = getActiveVideo()
          if (!currentVideo || !mediaStream || cameraOff) return
          applyStandaloneGeometry()
          currentVideo.srcObject = mediaStream
          currentVideo.play?.().catch?.(() => {})
        })
      })

      settleTimer = window.setTimeout(() => {
        const currentVideo = getActiveVideo()
        applyStandaloneGeometry()
        if (currentVideo && mediaStream && !cameraOff) {
          if (currentVideo.srcObject !== mediaStream) currentVideo.srcObject = mediaStream
          currentVideo.play?.().catch?.(() => {})
        }
      }, 240)
    }

    const clearStandaloneGeometry = () => {
      const videos = [videoPrimaryRef.current, videoSecondaryRef.current]
      videos.forEach((video) => {
        IOS_LIVE_STYLE_PROPS.forEach((property) => video?.style?.removeProperty(property))
      })
      const surface = videos.find(Boolean)?.closest?.('.fam-live-video-surface')
      IOS_LIVE_STYLE_PROPS.forEach((property) => surface?.style?.removeProperty(property))
    }

    const onVisibilityChange = () => {
      if (document.visibilityState === 'visible') restoreMediaLayer()
    }
    const onPageShow = () => restoreMediaLayer()
    const onFocus = () => {
      if (document.visibilityState === 'visible') restoreMediaLayer()
    }
    const onViewportResize = () => applyStandaloneGeometry()

    applyStandaloneGeometry()
    document.addEventListener('visibilitychange', onVisibilityChange)
    window.addEventListener('pageshow', onPageShow)
    window.addEventListener('focus', onFocus)
    window.visualViewport?.addEventListener('resize', onViewportResize)

    return () => {
      window.cancelAnimationFrame(firstFrame)
      window.cancelAnimationFrame(secondFrame)
      window.clearTimeout(settleTimer)
      document.removeEventListener('visibilitychange', onVisibilityChange)
      window.removeEventListener('pageshow', onPageShow)
      window.removeEventListener('focus', onFocus)
      window.visualViewport?.removeEventListener('resize', onViewportResize)
      clearStandaloneGeometry()
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

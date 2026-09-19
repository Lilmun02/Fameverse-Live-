import { useState } from 'react'
import '../../styles/live/fresh-host-live.css'
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

  const openViewerProfile = (userId) => {
    setViewerSheetOpen(false)
    profileSheet.open(userId)
  }

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

  return (
    <section className={`fvx-host-live ${cohostStream ? 'is-cohost' : ''}`} data-fresh-host-live="true">
      <div className="fvx-host-stage">
        {mediaStream && !cameraOff ? (
          <>
            <video
              ref={videoPrimaryRef}
              className={`fvx-host-video ${activeVideoSlot === 0 ? 'is-active' : 'is-inactive'} ${videoSlotFacing[0] === 'user' ? 'is-mirror' : ''}`}
              autoPlay
              muted
              playsInline
            />
            <video
              ref={videoSecondaryRef}
              className={`fvx-host-video ${activeVideoSlot === 1 ? 'is-active' : 'is-inactive'} ${videoSlotFacing[1] === 'user' ? 'is-mirror' : ''}`}
              autoPlay
              muted
              playsInline
            />
          </>
        ) : (
          <div className="fvx-camera-off">
            <div className="preview-camera-icon">◉</div>
            <strong>Camera off</strong>
            <small>Your microphone can stay on while video is hidden.</small>
          </div>
        )}
        <CohostVideoTile stream={cohostStream} label={cohost?.activeCohost?.displayName || 'Co-host'} />
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

      <LiveViewerSheet open={viewerSheetOpen} onClose={() => setViewerSheetOpen(false)} viewers={cohost?.viewers || []} onOpenIdentity={openViewerProfile} />
      <LiveProfileSheet sheet={profileSheet} currentUserId={currentUserId} followNetwork={followNetwork} />
      <LiveGiftTray open={giftTrayOpen} onClose={() => setGiftTrayOpen(false)} coins={coins} sendGift={sendGift} addTestCoins={addTestCoins} />
    </section>
  )
}

import LiveGiftTray from '../gifts/LiveGiftTray.jsx'
import CohostSheet from './CohostSheet.jsx'
import CohostVideoTile from './CohostVideoTile.jsx'
import EndLiveSummaryPanel from './EndLiveSummaryPanel.jsx'
import LiveActions from './LiveActions.jsx'
import LiveChat from './LiveChat.jsx'
import LiveHeader from './LiveHeader.jsx'
import LiveProfileSheet from './LiveProfileSheet.jsx'
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
  setCohostTrayOpen,
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
  cohost,
  presenceState,
  currentUserId,
  followNetwork,
}) {
  const profileSheet = useLiveProfileSheet()
  const cohostStream = cohost?.remoteStream || null

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
      />

      <LiveActions
        premiumRepeat={premiumRepeat}
        setCohostTrayOpen={setCohostTrayOpen}
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

      <LiveProfileSheet
        sheet={profileSheet}
        currentUserId={currentUserId}
        followNetwork={followNetwork}
      />

      <LiveGiftTray open={giftTrayOpen} onClose={() => setGiftTrayOpen(false)} coins={coins} sendGift={sendGift} addTestCoins={addTestCoins} />
      <CohostSheet
        open={cohostTrayOpen}
        onClose={() => setCohostTrayOpen(false)}
        shareRoom={shareRoom}
        requests={cohost?.requests || []}
        activeCohost={cohost?.activeCohost || null}
        onAccept={cohost?.acceptRequest}
        onDecline={cohost?.declineRequest}
        onEndCohost={cohost?.endCohost}
      />
    </section>
  )
}

import LiveGiftTray from '../gifts/LiveGiftTray.jsx'
import CohostSheet from './CohostSheet.jsx'
import EndLiveSummaryPanel from './EndLiveSummaryPanel.jsx'
import LiveActions from './LiveActions.jsx'
import LiveChat from './LiveChat.jsx'
import LiveHeader from './LiveHeader.jsx'
import PreLiveSetupPanel from './PreLiveSetupPanel.jsx'

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
  presenceState,
}) {
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
    <section className="mobile-live-shell fam-live-shell is-live">
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
        <div className="live-vignette fam-live-vignette" />
      </div>

      <LiveHeader
        isLive
        initial={initial}
        displayName={displayName}
        username={username}
        viewerCount={viewerCount}
        startLive={startLive}
        liveTitle={liveSetup.active?.title}
        presenceState={presenceState}
      />

      <LiveActions
        premiumRepeat={premiumRepeat}
        setGiftTrayOpen={setGiftTrayOpen}
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
      />

      <LiveGiftTray open={giftTrayOpen} onClose={() => setGiftTrayOpen(false)} coins={coins} sendGift={sendGift} addTestCoins={addTestCoins} />
      <CohostSheet open={cohostTrayOpen} onClose={() => setCohostTrayOpen(false)} shareRoom={shareRoom} />
    </section>
  )
}

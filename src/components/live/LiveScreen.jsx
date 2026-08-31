import LiveGiftTray from '../gifts/LiveGiftTray.jsx'
import CohostSheet from './CohostSheet.jsx'
import LiveActions from './LiveActions.jsx'
import LiveChat from './LiveChat.jsx'
import LiveHeader from './LiveHeader.jsx'
import LiveLaunchPanel from './LiveLaunchPanel.jsx'

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
}) {
  return (
    <section className={`mobile-live-shell fam-live-shell ${isLive ? 'is-live' : 'is-preview'}`}>
      <div className="live-video-surface fam-live-video-surface">
        {isLive && mediaStream && !cameraOff ? (
          <>
            <video
              ref={videoPrimaryRef}
              className={`host-video immersive-video ${activeVideoSlot === 0 ? 'active' : 'inactive'} ${videoSlotFacing[0] === 'user' ? 'mirror' : ''}`}
              autoPlay
              muted
              playsInline
            />
            <video
              ref={videoSecondaryRef}
              className={`host-video immersive-video ${activeVideoSlot === 1 ? 'active' : 'inactive'} ${videoSlotFacing[1] === 'user' ? 'mirror' : ''}`}
              autoPlay
              muted
              playsInline
            />
          </>
        ) : isLive && cameraOff ? (
          <div className="camera-off-placeholder fam-camera-off">
            <div className="preview-camera-icon">◉</div>
            <strong>Camera off</strong>
            <small>Your microphone can stay on while video is hidden.</small>
          </div>
        ) : (
          <div className="fam-preview-stage" aria-hidden="true">
            <div className="fam-orbit fam-orbit-one" />
            <div className="fam-orbit fam-orbit-two" />
            <div className="fam-preview-core">F</div>
          </div>
        )}
        <div className="live-vignette fam-live-vignette" />
      </div>

      <LiveHeader
        isLive={isLive}
        initial={initial}
        displayName={displayName}
        username={username}
        viewerCount={viewerCount}
        startLive={startLive}
      />

      {isLive ? (
        <>
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
        </>
      ) : (
        <LiveLaunchPanel
          isStartingLive={isStartingLive}
          startLive={startLive}
          flipCamera={flipCamera}
        />
      )}

      <LiveGiftTray
        open={isLive && giftTrayOpen}
        onClose={() => setGiftTrayOpen(false)}
        coins={coins}
        sendGift={sendGift}
        addTestCoins={addTestCoins}
      />

      <CohostSheet
        open={cohostTrayOpen}
        onClose={() => setCohostTrayOpen(false)}
        shareRoom={shareRoom}
      />
    </section>
  )
}

import { gifts } from '../../config/gifts.js'
import { seekGiftThumbnail } from '../../utils/media.js'

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
    <section className={`mobile-live-shell ${isLive ? 'is-live' : 'is-preview'}`}>
      <div className="live-video-surface">
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
          <div className="camera-off-placeholder">
            <div className="preview-camera-icon">◉</div>
            <strong>Camera off</strong>
            <small>Your microphone can stay on while video is hidden.</small>
          </div>
        ) : (
          <div className="live-preview-placeholder">
            <div className="preview-brand"><span>FAMEVERSE</span> LIVE</div>
            <div className="preview-camera-icon">◉</div>
            <strong>Ready to go live?</strong>
            <small>Camera + microphone stay on this device during the current beta.</small>
          </div>
        )}
        <div className="live-vignette" />
      </div>

      <div className="live-floating-top">
        <div className="live-host-chip">
          <div className="avatar owner live-avatar">{initial}</div>
          <div><strong>{displayName}</strong><small>{username}</small></div>
        </div>
        <div className="live-status-cluster">
          {isLive ? (
            <>
              <span className="viewer-chip">👁 {viewerCount}</span>
              <button className="top-end-live" onClick={startLive}>End</button>
            </>
          ) : (
            <><span className="live-pill">READY</span><span className="viewer-chip">👁 {viewerCount}</span></>
          )}
        </div>
      </div>

      {isLive && !premiumRepeat && (
        <div className="live-action-rail">
          <button className="live-action" onClick={() => setGiftTrayOpen(true)}><span>🎁</span><small>Gift</small></button>
          <button className="live-action" onClick={() => setCohostTrayOpen(true)}><span>＋</span><small>Co-host</small></button>
          <button className="live-action" onClick={toggleMic}><span>{micMuted ? '🔇' : '🎙️'}</span><small>{micMuted ? 'Unmute' : 'Mute'}</small></button>
          <button className="live-action" onClick={toggleCamera}><span>{cameraOff ? '🚫' : '📷'}</span><small>{cameraOff ? 'Cam on' : 'Camera'}</small></button>
          <button className="live-action" onClick={flipCamera} disabled={isStartingLive || cameraOff}><span>↻</span><small>Flip</small></button>
          <button className="live-action" onClick={shareRoom}><span>↗</span><small>Share</small></button>
        </div>
      )}

      {isLive && liveMessages.length > 0 && (
        <div className="live-chat-overlay" aria-label="Live comments">
          {liveMessages.map((item) => (
            <div className="live-chat-line" key={item.id}><strong>{item.user}</strong><span>{item.text}</span></div>
          ))}
        </div>
      )}

      {!isLive ? (
        <div className="live-launch-controls">
          <button className="go-live-main" onClick={startLive} disabled={isStartingLive}>{isStartingLive ? 'Starting…' : 'Go Live'}</button>
          <button className="preview-tool preview-tool-wide" onClick={flipCamera}>↻ Camera</button>
        </div>
      ) : (
        <form className="live-comment-composer" onSubmit={submitComment}>
          <input value={commentText} onChange={(event) => setCommentText(event.target.value)} maxLength={160} placeholder="Add comment…" aria-label="Add comment" />
          <button type="submit" aria-label="Send comment" disabled={!commentText.trim()}>↑</button>
        </form>
      )}

      {isLive && giftTrayOpen && !premiumRepeat && (
        <div className="live-sheet-backdrop" onClick={() => setGiftTrayOpen(false)}>
          <div className="live-sheet gift-test-sheet" onClick={(event) => event.stopPropagation()}>
            <div className="sheet-handle" />
            <div className="sheet-heading">
              <div><span>GIFTS · BETA TEST</span><strong>Send gifts</strong></div>
              <div className="test-balance">🪙 {coins.toLocaleString()}</div>
            </div>
            <p>Tap simple gifts repeatedly. Cinematic gifts collapse to a compact combo control so the animation stays visible.</p>
            <div className="live-gift-grid">
              {gifts.map((gift) => (
                <button
                  className={`live-gift-item ${gift.cinematic ? 'live-gift-item-cinematic' : ''}`}
                  key={gift.id}
                  onClick={() => sendGift(gift)}
                >
                  {gift.video ? (
                    <video
                      className="live-gift-thumbnail"
                      src={`${gift.video}#t=${gift.thumbnailTime || 0}`}
                      muted
                      playsInline
                      preload="metadata"
                      onLoadedMetadata={(event) => seekGiftThumbnail(event, gift.thumbnailTime)}
                    />
                  ) : (
                    <span>{gift.emoji}</span>
                  )}
                  <strong>{gift.label}</strong>
                  <small>{gift.cost} {gift.cost === 1 ? 'coin' : 'coins'}</small>
                </button>
              ))}
            </div>
            <div className="test-wallet-row">
              <small>Beta tester balance</small>
              <button onClick={() => addTestCoins(10000)}>+10K test coins</button>
            </div>
          </div>
        </div>
      )}

      {cohostTrayOpen && (
        <div className="live-sheet-backdrop" onClick={() => setCohostTrayOpen(false)}>
          <div className="live-sheet" onClick={(event) => event.stopPropagation()}>
            <div className="sheet-handle" />
            <div className="sheet-heading"><div><span>CO-HOST</span><strong>No requests yet</strong></div></div>
            <p>Realtime co-host requests and remote video are still being connected. No fake users are shown.</p>
            <button className="sheet-primary-action" onClick={shareRoom}>Share live link</button>
          </div>
        </div>
      )}
    </section>
  )
}

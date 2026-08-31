export default function LiveActions({
  premiumRepeat,
  setGiftTrayOpen,
  setCohostTrayOpen,
  micMuted,
  toggleMic,
  cameraOff,
  toggleCamera,
  flipCamera,
  isStartingLive,
  shareRoom,
}) {
  if (premiumRepeat) return null

  return (
    <div className="fam-action-rail" aria-label="Live controls">
      <button type="button" className="fam-action-button" onClick={() => setGiftTrayOpen(true)}>
        <span aria-hidden="true">🎁</span><small>Gift</small>
      </button>
      <button type="button" className="fam-action-button" onClick={() => setCohostTrayOpen(true)}>
        <span aria-hidden="true">＋</span><small>Co-host</small>
      </button>
      <button type="button" className="fam-action-button" onClick={toggleMic}>
        <span aria-hidden="true">{micMuted ? '🔇' : '🎙️'}</span><small>{micMuted ? 'Unmute' : 'Mute'}</small>
      </button>
      <button type="button" className="fam-action-button" onClick={toggleCamera}>
        <span aria-hidden="true">{cameraOff ? '🚫' : '📷'}</span><small>{cameraOff ? 'Cam on' : 'Camera'}</small>
      </button>
      <button
        type="button"
        className="fam-action-button"
        onClick={flipCamera}
        disabled={isStartingLive || cameraOff}
      >
        <span aria-hidden="true">↻</span><small>Flip</small>
      </button>
      <button type="button" className="fam-action-button" onClick={shareRoom}>
        <span aria-hidden="true">↗</span><small>Share</small>
      </button>
    </div>
  )
}

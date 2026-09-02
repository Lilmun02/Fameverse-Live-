import { useState } from 'react'

function stopLiveTap(event) {
  event.stopPropagation()
}

export default function LiveActions({
  premiumRepeat,
  setCohostTrayOpen,
  micMuted,
  toggleMic,
  cameraOff,
  toggleCamera,
  flipCamera,
  isStartingLive,
  shareRoom,
}) {
  const [menuOpen, setMenuOpen] = useState(false)

  if (premiumRepeat) return null

  const runAction = (action) => {
    setMenuOpen(false)
    action?.()
  }

  return (
    <div className="fam-live-more" onPointerDown={stopLiveTap}>
      {menuOpen && (
        <div className="fam-live-control-menu" role="menu" aria-label="Host Live controls">
          <button type="button" role="menuitem" onClick={() => runAction(() => setCohostTrayOpen(true))}>
            <span aria-hidden="true">＋</span><b>Co-host</b>
          </button>
          <button type="button" role="menuitem" onClick={() => runAction(toggleMic)}>
            <span aria-hidden="true">{micMuted ? '🔇' : '🎙️'}</span><b>{micMuted ? 'Unmute' : 'Mute'}</b>
          </button>
          <button type="button" role="menuitem" onClick={() => runAction(toggleCamera)}>
            <span aria-hidden="true">{cameraOff ? '◉' : '📷'}</span><b>{cameraOff ? 'Camera on' : 'Camera off'}</b>
          </button>
          <button
            type="button"
            role="menuitem"
            disabled={isStartingLive || cameraOff}
            onClick={() => runAction(flipCamera)}
          >
            <span aria-hidden="true">↻</span><b>Flip camera</b>
          </button>
          <button type="button" role="menuitem" onClick={() => runAction(shareRoom)}>
            <span aria-hidden="true">↗</span><b>Share Live</b>
          </button>
        </div>
      )}
      <button
        type="button"
        className="fam-live-f-menu"
        aria-label="Open host Live controls"
        aria-expanded={menuOpen}
        onPointerDown={stopLiveTap}
        onClick={() => setMenuOpen((open) => !open)}
      >
        F
      </button>
    </div>
  )
}

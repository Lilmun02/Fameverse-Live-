import { useLiveTapTotals } from '../../hooks/useLiveTapTotals.js'
import { useViewerTapCapture } from '../../hooks/useViewerTapCapture.js'

export default function ViewerLiveTapScreen({ room, onClose }) {
  const totals = useLiveTapTotals({ roomId: room?.id })
  const capture = useViewerTapCapture({ roomId: room?.id })
  const serverTotal = Math.max(
    totals.rawTaps,
    Number(capture.lastResult?.totalRawTaps || 0),
  )
  const hostLabel = room?.host?.username
    ? `@${room.host.username}`
    : room?.host?.displayName || 'Fameverse creator'
  const ended = capture.lastResult?.reasons?.includes('inactive_live_session')

  const onTap = (event) => {
    if (event.pointerType === 'mouse' && event.button !== 0) return
    capture.tap()
  }

  const onTapKey = (event) => {
    if (event.key !== 'Enter' && event.key !== ' ') return
    event.preventDefault()
    capture.tap()
  }

  return (
    <section className="fv-viewer-tap-shell" aria-label={`Viewing ${hostLabel} live tap test`}>
      <header className="fv-viewer-tap-header">
        <button type="button" onClick={onClose} aria-label="Back to Discover">‹</button>
        <div>
          <span>LIVE · BETA INTERACTION</span>
          <strong>{room?.title || 'Live session'}</strong>
          <small>{hostLabel}</small>
        </div>
        <b>♥ {serverTotal}</b>
      </header>

      <div className="fv-viewer-tap-stage">
        <div className="fv-viewer-tap-copy">
          <span>FAME TAP TEST</span>
          <h1>{ended ? 'This Live ended' : 'Tap to support'}</h1>
          <p>
            {ended
              ? 'Return to Discover to find another active room.'
              : 'Cross-device video relay is not connected in this pass. This surface only verifies real account-to-account Fame Taps.'}
          </p>
        </div>

        <button
          type="button"
          className="fv-viewer-tap-zone"
          onPointerDown={onTap}
          onKeyDown={onTapKey}
          disabled={ended}
          aria-label="Send Fame Tap"
        >
          <span aria-hidden="true">♥</span>
          <strong>{capture.localTapCount}</strong>
          <small>your taps this visit</small>
        </button>

        <div className="fv-viewer-tap-status" aria-live="polite">
          <span>Room total <b>{serverTotal}</b></span>
          <span>{capture.state === 'degraded' ? 'Tap sync retrying' : capture.state === 'sending' ? 'Syncing taps…' : 'Tap ledger connected'}</span>
        </div>
      </div>
    </section>
  )
}

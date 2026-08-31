import { FAMEVERSE_RELEASE } from '../../config/version.js'

export default function LiveLaunchPanel({
  isStartingLive,
  startLive,
  flipCamera,
}) {
  return (
    <div className="fam-launch-panel">
      <div className="fam-launch-glow" aria-hidden="true" />
      <span className="fam-launch-kicker">{FAMEVERSE_RELEASE.label}</span>
      <h2>Enter the Verse</h2>
      <p>Your camera and microphone connect only when you start the live room.</p>

      <div className="fam-readiness-row" aria-label="Live room readiness">
        <span><b>●</b> Camera on start</span>
        <span><b>●</b> Mic on start</span>
      </div>

      <button
        type="button"
        className="fam-enter-verse"
        onClick={startLive}
        disabled={isStartingLive}
      >
        <span>{isStartingLive ? 'Opening room…' : 'Enter the Verse'}</span>
        <small>{isStartingLive ? 'Connecting camera + mic' : 'Start Live'}</small>
      </button>

      <button type="button" className="fam-preview-camera" onClick={flipCamera}>
        ↻ Camera direction
      </button>
    </div>
  )
}

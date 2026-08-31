export default function LiveLaunchPanel({
  isStartingLive,
  startLive,
  flipCamera,
}) {
  return (
    <div className="community-live-launch">
      <div className="community-live-ready">
        <span><b>●</b> Camera + mic connect when you go live</span>
      </div>
      <div className="community-live-launch-actions">
        <button
          type="button"
          className="community-go-live"
          onClick={startLive}
          disabled={isStartingLive}
        >
          {isStartingLive ? 'Starting…' : 'Go Live'}
        </button>
        <button type="button" className="community-flip-camera" onClick={flipCamera} aria-label="Change camera direction">
          ↻
        </button>
      </div>
    </div>
  )
}

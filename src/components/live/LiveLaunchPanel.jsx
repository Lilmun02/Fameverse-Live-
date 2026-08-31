export default function LiveLaunchPanel({
  isStartingLive,
  startLive,
  flipCamera,
}) {
  return (
    <div className="fv-live-launch">
      <button type="button" className="fv-live-primary" onClick={startLive} disabled={isStartingLive}>
        {isStartingLive ? 'Starting…' : 'Go Live'}
      </button>
      <button type="button" className="fv-live-flip" onClick={flipCamera} aria-label="Change camera direction">↻</button>
      <small>Camera and microphone start after you tap Go Live.</small>
    </div>
  )
}

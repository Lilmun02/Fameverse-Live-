export default function LiveHeader({
  isLive,
  initial,
  displayName,
  username,
  viewerCount,
  startLive,
}) {
  return (
    <div className="fam-live-header">
      <div className="fam-creator-capsule">
        <div className={`fam-avatar-orbit ${isLive ? 'is-live' : ''}`}>
          <div className="avatar owner live-avatar">{initial}</div>
        </div>
        <div className="fam-creator-copy">
          <div className="fam-creator-name-row">
            <strong>{displayName}</strong>
            {isLive && <span className="fam-live-badge">LIVE</span>}
          </div>
          <small>{username}</small>
        </div>
      </div>

      {isLive && (
        <div className="fam-header-meta">
          <span className="fam-viewer-chip" aria-label={`${viewerCount} viewers`}>
            <span aria-hidden="true">◉</span> {viewerCount}
          </span>
          <button type="button" className="fam-end-live" onClick={startLive}>
            End
          </button>
        </div>
      )}
    </div>
  )
}

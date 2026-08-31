export default function LiveHeader({
  isLive,
  initial,
  displayName,
  username,
  viewerCount,
  startLive,
}) {
  if (!isLive) {
    return (
      <div className="fv-prelive-header">
        <div><span>LIVE</span><strong>Start a room</strong><small>{username}</small></div>
        <div className="fv-prelive-avatar" aria-label={displayName}>{initial}</div>
      </div>
    )
  }

  return (
    <div className="fam-live-header">
      <div className="fam-creator-capsule">
        <div className="fam-avatar-orbit is-live"><div className="avatar owner live-avatar">{initial}</div></div>
        <div className="fam-creator-copy">
          <div className="fam-creator-name-row"><strong>{displayName}</strong><span className="fam-live-badge">LIVE</span></div>
          <small>{username}</small>
        </div>
      </div>
      <div className="fam-header-meta">
        <span className="fam-viewer-chip" aria-label={`${viewerCount} viewers`}><span aria-hidden="true">◉</span> {viewerCount}</span>
        <button type="button" className="fam-end-live" onClick={startLive}>End</button>
      </div>
    </div>
  )
}

export default function LiveHeader({
  isLive,
  initial,
  displayName,
  username,
  viewerCount,
  tapCount,
  startLive,
  liveTitle,
  presenceState,
}) {
  if (!isLive) return null

  return (
    <div className="fam-live-header" data-presence-state={presenceState || 'unknown'}>
      <div className="fam-creator-capsule">
        <div className="fam-avatar-orbit is-live"><div className="avatar owner live-avatar">{initial}</div></div>
        <div className="fam-creator-copy">
          <div className="fam-creator-name-row"><strong>{displayName}</strong><span className="fam-live-badge">LIVE</span></div>
          <small>{liveTitle || username}</small>
        </div>
      </div>
      <div className="fam-header-meta">
        <span className="fam-viewer-chip" aria-label={`${viewerCount} viewers and ${tapCount} Fame Taps`}>
          <span aria-hidden="true">👥</span> {viewerCount}
          <i aria-hidden="true" />
          <span className="fam-header-fame" aria-hidden="true">F</span> {tapCount}
        </span>
        <button type="button" className="fam-end-live" onClick={startLive}>End</button>
      </div>
    </div>
  )
}

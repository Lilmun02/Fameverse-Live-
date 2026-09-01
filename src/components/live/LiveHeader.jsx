export default function LiveHeader({
  isLive,
  initial,
  displayName,
  username,
  viewerCount,
  startLive,
  liveTitle,
  presenceState,
}) {
  if (!isLive) return null

  const presenceLabel = presenceState === 'live'
    ? 'LIVE · SYNCED'
    : presenceState === 'degraded'
      ? 'LIVE · RETRYING'
      : 'LIVE · SYNCING'

  return (
    <div className="fam-live-header">
      <div className="fam-creator-capsule">
        <div className="fam-avatar-orbit is-live"><div className="avatar owner live-avatar">{initial}</div></div>
        <div className="fam-creator-copy">
          <div className="fam-creator-name-row"><strong>{displayName}</strong><span className="fam-live-badge">{presenceLabel}</span></div>
          <small>{liveTitle || username}</small>
        </div>
      </div>
      <div className="fam-header-meta">
        <span className="fam-viewer-chip" aria-label={`${viewerCount} viewers`}><span aria-hidden="true">◉</span> {viewerCount}</span>
        <button type="button" className="fam-end-live" onClick={startLive}>End</button>
      </div>
    </div>
  )
}

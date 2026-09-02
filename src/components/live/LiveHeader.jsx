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
  currentUserId,
  onOpenIdentity,
}) {
  if (!isLive) return null

  const identityEnabled = Boolean(currentUserId && onOpenIdentity)

  return (
    <div className="fam-live-header" data-presence-state={presenceState || 'unknown'}>
      <button
        type="button"
        className="fam-live-creator-identity"
        disabled={!identityEnabled}
        onClick={() => identityEnabled && onOpenIdentity(currentUserId)}
        aria-label={identityEnabled ? `Open ${displayName} profile` : undefined}
      >
        <div className="fam-avatar-orbit is-live"><div className="avatar owner live-avatar">{initial}</div></div>
        <div className="fam-creator-copy">
          <div className="fam-creator-name-row"><strong>{displayName}</strong><span className="fam-live-badge">LIVE</span></div>
          <small>{liveTitle || username}</small>
        </div>
      </button>
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

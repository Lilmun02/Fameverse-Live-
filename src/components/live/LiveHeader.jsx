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
  onOpenViewers,
}) {
  if (!isLive) return null

  const identityEnabled = Boolean(currentUserId && onOpenIdentity)

  return (
    <div className="fvx-live-header" data-presence-state={presenceState || 'unknown'}>
      <button
        type="button"
        className="fvx-creator"
        disabled={!identityEnabled}
        onClick={() => identityEnabled && onOpenIdentity(currentUserId)}
        aria-label={identityEnabled ? `Open ${displayName} profile` : undefined}
        title={displayName}
      >
        <span className="fvx-avatar-wrap" aria-hidden="true"><span className="fvx-avatar">{initial}</span></span>
        <span className="fvx-creator-copy">
          <span className="fvx-creator-row"><strong>{displayName}</strong><span className="fvx-live-badge">LIVE</span></span>
          <small>{liveTitle || username}</small>
        </span>
      </button>

      <div className="fvx-header-meta">
        <span className="fvx-viewer-chip" aria-label={`${viewerCount} viewers and ${tapCount} Fame Taps`}>
          <button type="button" onClick={onOpenViewers} aria-label={`Open ${viewerCount} live viewers`}>
            <span aria-hidden="true">👥</span> {viewerCount}
          </button>
          <i aria-hidden="true" />
          <span className="fvx-header-fame" aria-hidden="true">F</span> {tapCount}
        </span>
        <button type="button" className="fvx-end-live" onClick={startLive}>End</button>
      </div>
    </div>
  )
}

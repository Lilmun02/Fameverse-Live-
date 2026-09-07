import { useState } from 'react'

function stopLiveTap(event) {
  event.stopPropagation()
}

function identityInitial(person) {
  return String(person?.displayName || 'F').trim().charAt(0).toUpperCase() || 'F'
}

function CohostAvatar({ person }) {
  if (person?.avatarUrl) return <img className="fam-live-cohost-avatar" src={person.avatarUrl} alt="" />
  return <span className="fam-live-cohost-avatar">{identityInitial(person)}</span>
}

export default function LiveActions({
  premiumRepeat,
  cohost,
  micMuted,
  toggleMic,
  cameraOff,
  toggleCamera,
  flipCamera,
  isStartingLive,
  shareRoom,
}) {
  const [menuOpen, setMenuOpen] = useState(false)

  if (premiumRepeat) return null

  const runAction = (action) => {
    setMenuOpen(false)
    action?.()
  }

  const activeCohost = cohost?.activeCohost || null
  const pendingInvite = cohost?.pendingInvite || null
  const requests = cohost?.requests || []
  const requestViewerIds = new Set(requests.map((request) => request?.viewerId).filter(Boolean))
  const availableViewers = (cohost?.viewers || []).filter(
    (viewer) => viewer?.userId && !requestViewerIds.has(viewer.viewerId),
  )

  return (
    <div className="fam-live-more" onPointerDown={stopLiveTap}>
      {menuOpen && (
        <div className="fam-live-control-menu has-cohost-controls" role="menu" aria-label="Host Live controls">
          <div className="fam-live-control-section-label">CO-HOST</div>

          {activeCohost && (
            <div className="fam-live-cohost-row is-active">
              <CohostAvatar person={activeCohost} />
              <div>
                <strong>{activeCohost.displayName || 'Co-host'}</strong>
                <small>{activeCohost.status === 'live' ? 'Live with you now' : 'Connecting camera…'}</small>
              </div>
              <button type="button" className="is-danger" onClick={() => runAction(cohost?.endCohost)}>Remove</button>
            </div>
          )}

          {!activeCohost && pendingInvite && (
            <div className="fam-live-cohost-row is-pending">
              <CohostAvatar person={pendingInvite} />
              <div>
                <strong>{pendingInvite.displayName || 'Viewer'}</strong>
                <small>Invitation sent</small>
              </div>
              <button type="button" className="is-danger" onClick={() => runAction(cohost?.cancelInvite)}>Cancel</button>
            </div>
          )}

          {!activeCohost && !pendingInvite && requests.length > 0 && (
            <div className="fam-live-cohost-list" aria-label="Co-host requests">
              {requests.map((request) => (
                <div className="fam-live-cohost-row" key={`request-${request.viewerId}`}>
                  <CohostAvatar person={request} />
                  <div>
                    <strong>{request.displayName || 'Viewer'}</strong>
                    <small>Wants to co-host</small>
                  </div>
                  <div className="fam-live-cohost-actions">
                    <button type="button" onClick={() => runAction(() => cohost?.declineRequest?.(request))}>Decline</button>
                    <button type="button" className="is-primary" onClick={() => runAction(() => cohost?.acceptRequest?.(request))}>Accept</button>
                  </div>
                </div>
              ))}
            </div>
          )}

          {!activeCohost && !pendingInvite && availableViewers.length > 0 && (
            <div className="fam-live-cohost-list" aria-label="Viewers available to co-host">
              {availableViewers.map((viewer) => (
                <div className="fam-live-cohost-row" key={`viewer-${viewer.viewerId}`}>
                  <CohostAvatar person={viewer} />
                  <div>
                    <strong>{viewer.displayName || 'Viewer'}</strong>
                    <small>Watching your Live</small>
                  </div>
                  <button type="button" className="is-primary" onClick={() => runAction(() => cohost?.inviteViewer?.(viewer))}>Invite</button>
                </div>
              ))}
            </div>
          )}

          {!activeCohost && !pendingInvite && requests.length === 0 && availableViewers.length === 0 && (
            <div className="fam-live-cohost-empty">No eligible viewers are inside this Live yet.</div>
          )}

          <div className="fam-live-control-divider" />
          <div className="fam-live-control-section-label">LIVE CONTROLS</div>

          <button type="button" role="menuitem" onClick={() => runAction(toggleMic)}>
            <span aria-hidden="true">{micMuted ? '🔇' : '🎙️'}</span><b>{micMuted ? 'Unmute' : 'Mute'}</b>
          </button>
          <button type="button" role="menuitem" onClick={() => runAction(toggleCamera)}>
            <span aria-hidden="true">{cameraOff ? '◉' : '📷'}</span><b>{cameraOff ? 'Camera on' : 'Camera off'}</b>
          </button>
          <button
            type="button"
            role="menuitem"
            disabled={isStartingLive || cameraOff}
            onClick={() => runAction(flipCamera)}
          >
            <span aria-hidden="true">↻</span><b>Flip camera</b>
          </button>
          <button type="button" role="menuitem" onClick={() => runAction(shareRoom)}>
            <span aria-hidden="true">↗</span><b>Share Live</b>
          </button>
        </div>
      )}
      <button
        type="button"
        className="fam-live-f-menu"
        aria-label="Open host Live controls"
        aria-expanded={menuOpen}
        onPointerDown={stopLiveTap}
        onClick={() => setMenuOpen((open) => !open)}
      >
        F
      </button>
    </div>
  )
}

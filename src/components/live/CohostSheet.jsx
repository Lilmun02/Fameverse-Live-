function requestInitial(request) {
  return String(request?.displayName || 'F').trim().charAt(0).toUpperCase() || 'F'
}

function ViewerAvatar({ viewer }) {
  if (viewer.avatarUrl) return <img className="fv-cohost-request-avatar" src={viewer.avatarUrl} alt="" />
  return <span className="fv-cohost-request-avatar">{requestInitial(viewer)}</span>
}

export default function CohostSheet({
  open,
  onClose,
  shareRoom,
  viewers = [],
  requests = [],
  pendingInvite = null,
  activeCohost = null,
  onInvite,
  onCancelInvite,
  onAccept,
  onDecline,
  onEndCohost,
}) {
  if (!open) return null

  const availableViewers = viewers.filter((viewer) => viewer?.userId)
  const heading = activeCohost
    ? 'Co-host connected'
    : pendingInvite
      ? 'Invitation sent'
      : `${availableViewers.length} viewer${availableViewers.length === 1 ? '' : 's'} in this Live`

  return (
    <div className="live-sheet-backdrop" onClick={onClose}>
      <div className="live-sheet fv-cohost-sheet" onClick={(event) => event.stopPropagation()}>
        <div className="sheet-handle" />
        <div className="sheet-heading">
          <div>
            <span>CO-HOST</span>
            <strong>{heading}</strong>
          </div>
          <button type="button" onClick={onClose}>Close</button>
        </div>

        {activeCohost && (
          <div className="fv-cohost-active-card">
            <ViewerAvatar viewer={activeCohost} />
            <div>
              <strong>{activeCohost.displayName}</strong>
              <small>{activeCohost.status === 'live' ? 'Live with you now' : 'Connecting camera…'}</small>
            </div>
            <button type="button" className="is-danger" onClick={onEndCohost}>Remove</button>
          </div>
        )}

        {!activeCohost && pendingInvite && (
          <div className="fv-cohost-active-card">
            <ViewerAvatar viewer={pendingInvite} />
            <div>
              <strong>{pendingInvite.displayName}</strong>
              <small>Waiting for them to accept your invite</small>
            </div>
            <button type="button" className="is-danger" onClick={onCancelInvite}>Cancel</button>
          </div>
        )}

        {!activeCohost && !pendingInvite && (
          <>
            <div className="fv-cohost-section-title">VIEWERS IN THIS LIVE</div>
            {availableViewers.length > 0 ? (
              <div className="fv-cohost-request-list">
                {availableViewers.map((viewer) => (
                  <div className="fv-cohost-request-card" key={viewer.viewerId}>
                    <ViewerAvatar viewer={viewer} />
                    <div>
                      <strong>{viewer.displayName}</strong>
                      <small>Watching your Live now</small>
                    </div>
                    <div className="fv-cohost-request-actions">
                      <button type="button" className="is-accept" onClick={() => onInvite?.(viewer)}>Invite</button>
                    </div>
                  </div>
                ))}
              </div>
            ) : (
              <p>No eligible viewers are inside your Live yet. Once someone joins, their account will appear here.</p>
            )}
          </>
        )}

        {!activeCohost && !pendingInvite && requests.length > 0 && (
          <>
            <div className="fv-cohost-section-title">REQUESTS</div>
            <div className="fv-cohost-request-list">
              {requests.map((request) => (
                <div className="fv-cohost-request-card" key={request.viewerId}>
                  <ViewerAvatar viewer={request} />
                  <div>
                    <strong>{request.displayName}</strong>
                    <small>Wants to join your Live</small>
                  </div>
                  <div className="fv-cohost-request-actions">
                    <button type="button" onClick={() => onDecline?.(request)}>Decline</button>
                    <button type="button" className="is-accept" onClick={() => onAccept?.(request)}>Accept</button>
                  </div>
                </div>
              ))}
            </div>
          </>
        )}

        {!activeCohost && !pendingInvite && availableViewers.length === 0 && (
          <button type="button" className="sheet-primary-action" onClick={shareRoom}>Share Live</button>
        )}
      </div>
    </div>
  )
}

function requestInitial(request) {
  return String(request?.displayName || 'F').trim().charAt(0).toUpperCase() || 'F'
}

export default function CohostSheet({
  open,
  onClose,
  shareRoom,
  requests = [],
  activeCohost = null,
  onAccept,
  onDecline,
  onEndCohost,
}) {
  if (!open) return null

  return (
    <div className="live-sheet-backdrop" onClick={onClose}>
      <div className="live-sheet fv-cohost-sheet" onClick={(event) => event.stopPropagation()}>
        <div className="sheet-handle" />
        <div className="sheet-heading">
          <div>
            <span>CO-HOST</span>
            <strong>{activeCohost ? 'Co-host connected' : requests.length ? `${requests.length} request${requests.length === 1 ? '' : 's'}` : 'No requests yet'}</strong>
          </div>
        </div>

        {activeCohost && (
          <div className="fv-cohost-active-card">
            <span className="fv-cohost-request-avatar">{requestInitial(activeCohost)}</span>
            <div>
              <strong>{activeCohost.displayName}</strong>
              <small>{activeCohost.status === 'live' ? 'Live with you now' : 'Connecting camera…'}</small>
            </div>
            <button type="button" className="is-danger" onClick={onEndCohost}>Remove</button>
          </div>
        )}

        {!activeCohost && requests.length > 0 && (
          <div className="fv-cohost-request-list">
            {requests.map((request) => (
              <div className="fv-cohost-request-card" key={request.viewerId}>
                {request.avatarUrl ? (
                  <img className="fv-cohost-request-avatar" src={request.avatarUrl} alt="" />
                ) : (
                  <span className="fv-cohost-request-avatar">{requestInitial(request)}</span>
                )}
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
        )}

        {!activeCohost && requests.length === 0 && (
          <>
            <p>When a real viewer requests to co-host, their account appears here for you to accept or decline.</p>
            <button type="button" className="sheet-primary-action" onClick={shareRoom}>Share live link</button>
          </>
        )}
      </div>
    </div>
  )
}

function statusLabel(status) {
  return String(status || 'unknown').replaceAll('_', ' ')
}

export default function OwnerVerificationQueue({
  verifications,
  busy,
  onAction,
}) {
  return (
    <section className="owner-panel owner-panel-wide">
      <div className="owner-panel-heading">
        <div><span>CREATOR TRUST</span><h2>Verification Queue</h2></div>
        <b>{verifications.length}</b>
      </div>
      <p className="owner-panel-copy">
        Review creator verification on the web. The native app only shows creators their own verification progress and result.
      </p>
      <div className="owner-table-wrap">
        <table className="owner-table">
          <thead>
            <tr><th>Creator</th><th>Status</th><th>Requested</th><th>Action</th></tr>
          </thead>
          <tbody>
            {verifications.length === 0 ? (
              <tr>
                <td colSpan="4" className="owner-empty">No creator verification requests waiting.</td>
              </tr>
            ) : verifications.map((request) => (
              <tr key={request.user_id}>
                <td>
                  <b>{request.display_name || request.username || 'Creator'}</b>
                  <small>{request.username ? `@${request.username}` : ''}</small>
                </td>
                <td>
                  <span className={`owner-pill status-${request.status}`}>
                    {statusLabel(request.status)}
                  </span>
                </td>
                <td>
                  {request.requested_at
                    ? new Date(request.requested_at).toLocaleString()
                    : '—'}
                </td>
                <td>
                  <div className="owner-button-row tight">
                    <button
                      type="button"
                      className="owner-control-primary small"
                      onClick={() => onAction(request, 'verified')}
                      disabled={busy}
                    >
                      Approve
                    </button>
                    <button
                      type="button"
                      className="owner-control-secondary small"
                      onClick={() => onAction(request, 'needs_info')}
                      disabled={busy}
                    >
                      Needs info
                    </button>
                    <button
                      type="button"
                      className="owner-control-danger small"
                      onClick={() => onAction(request, 'rejected')}
                      disabled={busy}
                    >
                      Reject
                    </button>
                  </div>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </section>
  )
}

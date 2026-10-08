import { useState } from 'react'
import { decideBadgeTransfer, getBadgeProofUrl } from '../../services/badgeTransfers.js'

const STATUS_NAMES = Object.freeze({
  pending: 'Waiting for review',
  needs_info: 'More proof requested',
  rejected: 'Denied',
})

export default function OwnerBadgeTransfers({ claims, queueError, onReviewed }) {
  const [drafts, setDrafts] = useState({})
  const [busy, setBusy] = useState('')
  const [error, setError] = useState('')

  function updateDraft(id, key, value) {
    setDrafts((current) => ({
      ...current,
      [id]: { ...current[id], [key]: value },
    }))
  }

  async function watchProof(claim) {
    setError('')
    setBusy(claim.id)
    try {
      const url = await getBadgeProofUrl(claim.evidence_path)
      if (!url) throw new Error('The recording is unavailable.')
      window.open(url, '_blank', 'noopener,noreferrer')
    } catch (err) {
      setError(err?.message || 'Could not open the private recording.')
    } finally {
      setBusy('')
    }
  }

  async function review(claim, decision) {
    if (busy) return
    const approvedLevel = drafts[claim.id]?.level || ''
    const note = drafts[claim.id]?.note || ''
    if (decision === 'approved' && !Number.isInteger(Number(approvedLevel))) {
      setError('Enter a whole-number Fameverse badge level before approving.')
      return
    }
    if (decision === 'approved' && (
      Number(approvedLevel) < 1 || Number(approvedLevel) > 99
    )) {
      setError('Badge levels must be from 1 to 99.')
      return
    }
    const decisionMessage = decision === 'approved'
      ? 'Approve this evidence and automatically assign Fameverse level ' +
        approvedLevel + '? This does not add Fame Coins or unlock spending-based gifts.'
      : decision === 'rejected'
        ? 'Reject this badge-transfer claim?'
        : 'Request additional evidence from this applicant?'
    if (!window.confirm(decisionMessage)) return

    setBusy(claim.id)
    setError('')
    try {
      await decideBadgeTransfer({
        claimId: claim.id,
        decision,
        approvedLevel,
        note,
      })
      await onReviewed()
    } catch (err) {
      setError(err?.message || 'Could not update badge review.')
    } finally {
      setBusy('')
    }
  }

  return (
    <section className="owner-panel owner-panel-wide" aria-label="Badge transfer moderation">
      <div className="owner-panel-heading">
        <div><span>MEMBER VERIFICATION</span><h2>Badge transfers</h2></div>
      </div>
      <p className="owner-panel-copy">
        App submissions only. Check the source username and badge number in the original
        screen recording before deciding. Supported sources: TikTok, Favorited and EPIC.
        No automatic AI approval; you make the final decision.
      </p>
      {queueError && (
        <div className="owner-control-warning" role="alert">
          Transfer submissions cannot load yet: {queueError}
        </div>
      )}
      {error && <div className="owner-control-error" role="alert">{error}</div>}
      {!queueError && claims.length === 0 && (
        <div className="owner-empty">No badge transfers waiting for review.</div>
      )}
      <div className="owner-list">
        {claims.map((claim) => (
          <div key={claim.id} className="owner-list-item" style={{ alignItems: 'flex-start', gap: 12 }}>
            <div style={{ flex: 1, minWidth: 0 }}>
              <strong>{claim.applicant?.display_name || claim.applicant?.username || claim.user_id}</strong>
              <div>Source: {claim.source_platform.toUpperCase()} ·
                @{claim.source_username} · claimed Lv. {claim.source_level}</div>
              <div>{STATUS_NAMES[claim.status] || claim.status}</div>
              <div>{new Date(claim.submitted_at).toLocaleString()}</div>
              <button
                type="button"
                className="owner-control-secondary small"
                onClick={() => watchProof(claim)}
                disabled={Boolean(busy)}
              >
                Watch source-app recording
              </button>
              {claim.status === 'pending' && (
                <div style={{ marginTop: 10, display: 'grid', gap: 9 }}>
                  <label>
                    Approved Fameverse level (not coins spent)
                    <input
                      type="number" min="1" max="99" step="1" inputMode="numeric"
                      value={drafts[claim.id]?.level || ''}
                      onChange={(event) => updateDraft(claim.id, 'level', event.target.value)}
                      placeholder="Enter approved level"
                    />
                  </label>
                  <label>
                    Moderation note (optional)
                    <textarea
                      rows="2"
                      value={drafts[claim.id]?.note || ''}
                      onChange={(event) => updateDraft(claim.id, 'note', event.target.value)}
                    />
                  </label>
                  <div className="owner-button-row">
                    <button className="owner-control-primary small" type="button"
                      disabled={Boolean(busy)}
                      onClick={() => review(claim, 'approved')}>Approve and assign level</button>
                    <button className="owner-control-secondary small" type="button"
                      disabled={Boolean(busy)}
                      onClick={() => review(claim, 'needs_info')}>Need more proof</button>
                    <button className="owner-control-danger small" type="button"
                      disabled={Boolean(busy)}
                      onClick={() => review(claim, 'rejected')}>Deny</button>
                  </div>
                </div>
              )}
            </div>
          </div>
        ))}
      </div>
    </section>
  )
}

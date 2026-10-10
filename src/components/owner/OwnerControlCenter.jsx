import { useCallback, useEffect, useMemo, useState } from 'react'
import {
  allocateRewardReserve,
  listActiveLives,
  listOwnerOperators,
  listPayoutQueue,
  listVerificationQueue,
  loadMyCashRewardPermission,
  loadOwnerRewardSummary,
  publishUpdateNotice,
  releasePayout,
  reviewPayout,
  reviewVerification,
  setStaffCashRewardPermission,
  syncPayout,
} from '../../services/ownerControl.js'
import OwnerVerificationQueue from './OwnerVerificationQueue.jsx'
import OwnerBadgeTransfers from './OwnerBadgeTransfers.jsx'
import { loadOwnerBadgeTransferQueue } from '../../services/badgeTransfers.js'
import '../../styles/owner/control-center.css'
const money = (cents = 0) => `$${(Number(cents || 0) / 100).toFixed(2)}`
const percent = (bps = 0) => `${(Number(bps || 0) / 100).toFixed(0)}%`
function statusLabel(status) {
  return String(status || 'unknown').replaceAll('_', ' ')
}
export default function OwnerControlCenter({ userId, displayName, onExit }) {
  const [loading, setLoading] = useState(true)
  const [busyKey, setBusyKey] = useState('')
  const [error, setError] = useState('')
  const [toast, setToast] = useState('')
  const [summary, setSummary] = useState(null)
  const [myPermission, setMyPermission] = useState(null)
  const [operators, setOperators] = useState([])
  const [payouts, setPayouts] = useState([])
  const [verifications, setVerifications] = useState([])
  const [badgeClaims, setBadgeClaims] = useState([])
  const [badgeQueueError, setBadgeQueueError] = useState('')
  const [lives, setLives] = useState([])
  const [reserveAmount, setReserveAmount] = useState('10.00')
  const [reserveNote, setReserveNote] = useState('')
  const [fundedConfirmed, setFundedConfirmed] = useState(false)
  const [myCap, setMyCap] = useState('1.00')
  const [paypalEnvironment, setPaypalEnvironment] = useState('sandbox')
  const [announcement, setAnnouncement] = useState({
    updateType: 'feature',
    title: '',
    summary: '',
    changelog: '',
    requiresAcknowledgement: true,
  })
  const refresh = useCallback(async () => {
    setError('')
    try {
      const [rewardSummary, permission, operatorRows, payoutRows, verificationRows, liveRows, transferQueue] = await Promise.all([
        loadOwnerRewardSummary(),
        loadMyCashRewardPermission(),
        listOwnerOperators(),
        listPayoutQueue(),
        listVerificationQueue(),
        listActiveLives(),
        loadOwnerBadgeTransferQueue(),
      ])
      setSummary(rewardSummary)
      setMyPermission(permission)
      setMyCap((Number(permission?.max_gross_cents_per_gift || 100) / 100).toFixed(2))
      setOperators(operatorRows)
      setPayouts(payoutRows)
      setVerifications(verificationRows)
      setBadgeClaims(transferQueue.claims)
      setBadgeQueueError(transferQueue.error || '')
      setLives(liveRows)
    } catch (refreshError) {
      setError(refreshError?.message || 'Owner controls could not refresh.')
    } finally {
      setLoading(false)
    }
  }, [])
  useEffect(() => {
    refresh()
  }, [refresh])
  useEffect(() => {
    if (!toast) return undefined
    const timer = window.setTimeout(() => setToast(''), 3200)
    return () => window.clearTimeout(timer)
  }, [toast])
  const creatorShareExample = useMemo(() => {
    const creatorBps = Number(summary?.creator_share_bps || 7000)
    return Math.round(100 * creatorBps / 10000)
  }, [summary])
  async function run(key, action, successMessage) {
    if (busyKey) return
    setBusyKey(key)
    setError('')
    try {
      await action()
      if (successMessage) setToast(successMessage)
      await refresh()
    } catch (actionError) {
      setError(actionError?.message || 'That owner action failed.')
    } finally {
      setBusyKey('')
    }
  }
  function allocateReserve(event) {
    event.preventDefault()
    const cents = Math.round(Number(reserveAmount) * 100)
    if (!Number.isFinite(cents) || cents <= 0) {
      setError('Enter a reward reserve amount greater than $0.00.')
      return
    }
    if (!fundedConfirmed) {
      setError('Confirm that the matching money is already funded in the Fameverse PayPal Business balance.')
      return
    }
    run(
      'reserve',
      () => allocateRewardReserve(cents, reserveNote.trim()),
      `${money(cents)} added to the Fameverse reward reserve cap.`,
    ).then(() => {
      setReserveNote('')
      setFundedConfirmed(false)
    })
  }
  function toggleMyCashRewards() {
    const maxCents = Math.round(Number(myCap) * 100)
    if (!Number.isFinite(maxCents) || maxCents < 1) {
      setError('Your per-gift cash reward cap must be at least $0.01.')
      return
    }
    run(
      'my-reward-mode',
      () => setStaffCashRewardPermission({
        userId,
        enabled: !myPermission?.cash_rewards_enabled,
        maxGrossCentsPerGift: maxCents,
      }),
      myPermission?.cash_rewards_enabled
        ? 'Your gifts are back in test-only mode.'
        : 'Cash-backed reward mode is ON for your account.',
    )
  }
  function saveMyCap() {
    const maxCents = Math.round(Number(myCap) * 100)
    if (!Number.isFinite(maxCents) || maxCents < 1) {
      setError('Your per-gift cash reward cap must be at least $0.01.')
      return
    }
    run(
      'my-cap',
      () => setStaffCashRewardPermission({
        userId,
        enabled: Boolean(myPermission?.cash_rewards_enabled),
        maxGrossCentsPerGift: maxCents,
      }),
      `Your cash-backed gift cap is now ${money(maxCents)}.`,
    )
  }
  function setOperator(operator, enabled) {
    const currentCap = Number(operator.permission?.max_gross_cents_per_gift || 100)
    run(
      `operator-${operator.user_id}`,
      () => setStaffCashRewardPermission({
        userId: operator.user_id,
        enabled,
        maxGrossCentsPerGift: currentCap,
      }),
      `${operator.profile?.display_name || operator.role} cash rewards ${enabled ? 'enabled' : 'disabled'}.`,
    )
  }
  function payoutAction(payout, action) {
    if (action === 'approve') {
      return run(
        `payout-${payout.payout_id}`,
        () => reviewPayout({ payoutId: payout.payout_id, status: 'approved' }),
        `${money(payout.amount_cents)} payout approved. Release is still required.`,
      )
    }
    if (action === 'reject') {
      return run(
        `payout-${payout.payout_id}`,
        () => reviewPayout({ payoutId: payout.payout_id, status: 'rejected', note: 'Rejected by Fameverse owner review.' }),
        'Payout request rejected.',
      )
    }
    if (action === 'release' || action === 'recover') {
      return run(
        `payout-${payout.payout_id}`,
        () => releasePayout({ payoutId: payout.payout_id, expectedEnvironment: paypalEnvironment }),
        action === 'recover'
          ? 'PayPal recovery submitted. Creator funds remain reserved until the provider result is confirmed.'
          : 'Payout submitted to PayPal. Fameverse will keep the request in processing until PayPal confirms it.',
      )
    }
    return run(
      `payout-${payout.payout_id}`,
      () => syncPayout({ payoutId: payout.payout_id, expectedEnvironment: paypalEnvironment }),
      'PayPal payout status refreshed.',
    )
  }
  function verificationAction(request, status) {
    const note = status === 'verified'
      ? 'Creator verification approved by Fameverse review.'
      : status === 'needs_info'
        ? 'More information is required before verification can be approved.'
        : 'Verification request was not approved.'
    return run(
      `verification-${request.user_id}`,
      () => reviewVerification({ userId: request.user_id, status, publicNote: note }),
      `Verification updated to ${status.replaceAll('_', ' ')}.`,
    )
  }
  function publishAnnouncement(event) {
    event.preventDefault()
    const title = announcement.title.trim()
    if (!title) {
      setError('Give the Fameverse announcement a title.')
      return
    }
    const changelog = announcement.changelog
      .split('\n')
      .map((item) => item.trim())
      .filter(Boolean)
    run(
      'announcement',
      () => publishUpdateNotice({
        updateType: announcement.updateType,
        title,
        summary: announcement.summary.trim(),
        changelog,
        requiresAcknowledgement: announcement.requiresAcknowledgement,
      }),
      'Fameverse startup announcement published.',
    ).then(() => {
      setAnnouncement((current) => ({ ...current, title: '', summary: '', changelog: '' }))
    })
  }
  return (
    <div className="owner-control-shell">
      {toast && <div className="owner-control-toast">{toast}</div>}
      <header className="owner-control-header">
        <div>
          <div className="owner-control-eyebrow">FAMEVERSE OWNER</div>
          <h1>Control Center</h1>
          <p>{displayName || 'Owner'} · money, payouts, Live operations and announcements</p>
        </div>
        <div className="owner-control-header-actions">
          <button type="button" className="owner-control-secondary" onClick={refresh} disabled={Boolean(busyKey)}>
            Refresh
          </button>
          <button type="button" className="owner-control-secondary" onClick={onExit}>
            Exit controls
          </button>
        </div>
      </header>
      {error && <div className="owner-control-error">{error}</div>}
      {loading ? (
        <div className="owner-control-loading">Loading Fameverse owner controls…</div>
      ) : (
        <main className="owner-control-grid">
          <section className="owner-panel owner-panel-wide">
            <div className="owner-panel-heading">
              <div>
                <span>REWARD MONEY</span>
                <h2>Cash Reward Reserve</h2>
              </div>
              <strong>{money(summary?.reserve_gross_cents)}</strong>
            </div>
            <div className="owner-metric-row">
              <div><small>Gift value</small><b>{summary?.coins_per_usd || 100} coins = $1</b></div>
              <div><small>Creator</small><b>{percent(summary?.creator_share_bps || 7000)}</b></div>
              <div><small>Fameverse</small><b>{percent(summary?.platform_share_bps || 3000)}</b></div>
              <div><small>Lifetime reserved</small><b>{money(summary?.lifetime_allocated_gross_cents)}</b></div>
            </div>
            <div className="owner-control-warning">
              This reserve is a Fameverse safety cap — it does not move money. Fund the Fameverse PayPal Business balance first, then allocate the matching amount here. A $1 cash-backed gift creates about ${(creatorShareExample / 100).toFixed(2)} in creator earnings and $0.30 in Fameverse share.
            </div>
            <form className="owner-control-form" onSubmit={allocateReserve}>
              <label>
                Add funded reward budget
                <div className="owner-control-money-input"><span>$</span><input value={reserveAmount} onChange={(event) => setReserveAmount(event.target.value)} inputMode="decimal" /></div>
              </label>
              <label>
                Note
                <input value={reserveNote} onChange={(event) => setReserveNote(event.target.value)} placeholder="Example: Friday creator rewards" />
              </label>
              <label className="owner-control-check">
                <input type="checkbox" checked={fundedConfirmed} onChange={(event) => setFundedConfirmed(event.target.checked)} />
                I already funded at least this amount in Fameverse PayPal Business.
              </label>
              <button type="submit" className="owner-control-primary" disabled={busyKey === 'reserve'}>Allocate reserve</button>
            </form>
          </section>
          <section className="owner-panel">
            <div className="owner-panel-heading compact">
              <div><span>YOUR ACCOUNT</span><h2>Cash-backed Gift Mode</h2></div>
              <div className={`owner-status-dot ${myPermission?.cash_rewards_enabled ? 'on' : ''}`} />
            </div>
            <p className="owner-panel-copy">
              OFF = unlimited test behavior within your Fame Coin balance and no creator cash liability. ON = eligible gifts consume Reward Reserve and credit the creator at 70%.
            </p>
            <label>
              Maximum gross value per cash-backed gift
              <div className="owner-control-money-input"><span>$</span><input value={myCap} onChange={(event) => setMyCap(event.target.value)} inputMode="decimal" /></div>
            </label>
            <div className="owner-button-row">
              <button type="button" className="owner-control-secondary" onClick={saveMyCap} disabled={Boolean(busyKey)}>Save cap</button>
              <button type="button" className={myPermission?.cash_rewards_enabled ? 'owner-control-danger' : 'owner-control-primary'} onClick={toggleMyCashRewards} disabled={Boolean(busyKey)}>
                {myPermission?.cash_rewards_enabled ? 'Turn cash rewards OFF' : 'Turn cash rewards ON'}
              </button>
            </div>
          </section>
          <section className="owner-panel">
            <div className="owner-panel-heading compact">
              <div><span>OWNER + ADMIN</span><h2>Reward Permissions</h2></div>
            </div>
            <div className="owner-list">
              {operators.map((operator) => (
                <div className="owner-list-item" key={operator.user_id}>
                  <div>
                    <b>{operator.profile?.display_name || operator.profile?.username || operator.role}</b>
                    <small>{operator.role} · cap {money(operator.permission?.max_gross_cents_per_gift || 100)}</small>
                  </div>
                  <button
                    type="button"
                    className={operator.permission?.cash_rewards_enabled ? 'owner-control-danger small' : 'owner-control-secondary small'}
                    onClick={() => setOperator(operator, !operator.permission?.cash_rewards_enabled)}
                    disabled={Boolean(busyKey)}
                  >
                    {operator.permission?.cash_rewards_enabled ? 'Disable cash' : 'Enable cash'}
                  </button>
                </div>
              ))}
            </div>
          </section>
          <section className="owner-panel owner-panel-wide">
            <div className="owner-panel-heading">
              <div><span>CREATOR MONEY</span><h2>Payout Queue</h2></div>
              <label className="owner-control-inline-select">
                PayPal
                <select value={paypalEnvironment} onChange={(event) => setPaypalEnvironment(event.target.value)}>
                  <option value="sandbox">Sandbox</option>
                  <option value="live">Live</option>
                </select>
              </label>
            </div>
            <p className="owner-panel-copy">Approve first. Release separately. Release is the action that actually submits the approved payout to PayPal.</p>
            <div className="owner-table-wrap">
              <table className="owner-table">
                <thead><tr><th>Creator</th><th>Amount</th><th>Status</th><th>Requested</th><th>Action</th></tr></thead>
                <tbody>
                  {payouts.length === 0 ? (
                    <tr><td colSpan="5" className="owner-empty">No creator payout requests waiting.</td></tr>
                  ) : payouts.map((payout) => (
                    <tr key={payout.payout_id}>
                      <td><b>{payout.display_name || payout.username || 'Creator'}</b><small>{payout.username ? `@${payout.username}` : ''}</small></td>
                      <td>{money(payout.amount_cents)}</td>
                      <td><span className={`owner-pill status-${payout.status}`}>{statusLabel(payout.status)}</span></td>
                      <td>{payout.requested_at ? new Date(payout.requested_at).toLocaleString() : '—'}</td>
                      <td>
                        <div className="owner-button-row tight">
                          {payout.status === 'pending_review' && <>
                            <button type="button" className="owner-control-primary small" onClick={() => payoutAction(payout, 'approve')} disabled={Boolean(busyKey)}>Approve</button>
                            <button type="button" className="owner-control-danger small" onClick={() => payoutAction(payout, 'reject')} disabled={Boolean(busyKey)}>Reject</button>
                          </>}
                          {payout.status === 'approved' && <button type="button" className="owner-control-primary small" onClick={() => payoutAction(payout, 'release')} disabled={Boolean(busyKey)}>Release to PayPal</button>}
                          {payout.status === 'processing' && !payout.provider_batch_id && ['SUBMISSION_UNKNOWN', 'SUBMITTING'].includes(payout.provider_status) && (
                            <button type="button" className="owner-control-primary small" onClick={() => payoutAction(payout, 'recover')} disabled={Boolean(busyKey)}>Recover PayPal submission</button>
                          )}
                          {['processing', 'held'].includes(payout.status) && !(!payout.provider_batch_id && ['SUBMISSION_UNKNOWN', 'SUBMITTING'].includes(payout.provider_status)) && (
                            <button type="button" className="owner-control-secondary small" onClick={() => payoutAction(payout, 'sync')} disabled={Boolean(busyKey)}>Sync PayPal</button>
                          )}
                        </div>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </section>
          <OwnerVerificationQueue
            verifications={verifications}
            busy={Boolean(busyKey)}
            onAction={verificationAction}
          />
          <OwnerBadgeTransfers
            claims={badgeClaims}
            queueError={badgeQueueError}
            onReviewed={refresh}
          />
          <section className="owner-panel">
            <div className="owner-panel-heading compact">
              <div><span>LIVE OPERATIONS</span><h2>Active Live Sessions</h2></div>
              <b>{lives.length}</b>
            </div>
            <div className="owner-list">
              {lives.length === 0 ? <div className="owner-empty">Nobody is Live right now.</div> : lives.map((room) => (
                <div className="owner-list-item live" key={room.id}>
                  <div>
                    <b>{room.host?.display_name || room.host?.username || 'Fameverse creator'}</b>
                    <small>{room.title || 'Untitled Live'} · {room.started_at ? new Date(room.started_at).toLocaleTimeString() : 'Live'}</small>
                  </div>
                  <span className="owner-pill live-pill">LIVE</span>
                </div>
              ))}
            </div>
            <p className="owner-panel-footnote">This first control-center pass monitors native Live sessions from Supabase. Desktop video monitoring needs the Stream Video web client wired to the same native calls; this panel does not fake a video preview.</p>
          </section>
          <section className="owner-panel">
            <div className="owner-panel-heading compact">
              <div><span>PLATFORM VOICE</span><h2>Announcements</h2></div>
            </div>
            <form className="owner-control-form" onSubmit={publishAnnouncement}>
              <label>
                Type
                <select value={announcement.updateType} onChange={(event) => setAnnouncement((current) => ({ ...current, updateType: event.target.value }))}>
                  <option value="feature">What’s new</option>
                  <option value="backend">Backend update</option>
                  <option value="maintenance">Service update</option>
                  <option value="app">App update</option>
                </select>
              </label>
              <label>Title<input value={announcement.title} onChange={(event) => setAnnouncement((current) => ({ ...current, title: event.target.value }))} placeholder="Fameverse update incoming" /></label>
              <label>Summary<textarea value={announcement.summary} onChange={(event) => setAnnouncement((current) => ({ ...current, summary: event.target.value }))} rows="3" /></label>
              <label>Changelog · one line each<textarea value={announcement.changelog} onChange={(event) => setAnnouncement((current) => ({ ...current, changelog: event.target.value }))} rows="4" /></label>
              <label className="owner-control-check"><input type="checkbox" checked={announcement.requiresAcknowledgement} onChange={(event) => setAnnouncement((current) => ({ ...current, requiresAcknowledgement: event.target.checked }))} />Require acknowledgement on startup</label>
              <button type="submit" className="owner-control-primary" disabled={busyKey === 'announcement'}>Publish announcement</button>
            </form>
            <p className="owner-panel-footnote">This publishes through Fameverse’s backend updater/startup notice system. A future “Fameverse Broadcast” mode can add a countdown and gracefully end active Lives before a major announcement.</p>
          </section>
        </main>
      )}
    </div>
  )
}

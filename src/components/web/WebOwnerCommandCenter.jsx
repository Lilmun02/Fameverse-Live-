import { useEffect, useState } from 'react'
import '../../styles/web/platform-owner.css'

function formatMoney(value) {
  if (value === null || value === undefined || !Number.isFinite(Number(value))) return '—'
  return new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD' }).format(Number(value) / 100)
}

function formatCoins(value) {
  if (value === null || value === undefined || !Number.isFinite(Number(value))) return '—'
  return Number(value).toLocaleString('en-US')
}

export default function WebOwnerCommandCenter({ account }) {
  const [code, setCode] = useState('')
  const [busy, setBusy] = useState(false)
  const [summary, setSummary] = useState(null)
  const [notice, setNotice] = useState('')
  const owner = account.session?.user?.id && account.profile?.account_role === 'owner'

  useEffect(() => {
    setCode('')
    setSummary(null)
    setNotice('')
  }, [account.session?.user?.id])

  if (!owner) return <section className="fv-owner-denied" role="alert">
    <span className="fv-web-eyebrow">RESTRICTED WEB AREA</span>
    <h1>Access denied</h1>
    <p>This page is available only to the verified Fameverse owner.</p>
    <a href="/">Return to Home</a>
  </section>

  const submit = async (event) => {
    event.preventDefault()
    if (busy || code.length < 12 || !account.session?.access_token) return
    setBusy(true)
    setNotice('')
    setSummary(null)
    try {
      const response = await fetch('/api/owner/control', {
        method: 'POST',
        credentials: 'omit',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${account.session.access_token}`,
        },
        body: JSON.stringify({ action: 'summary', code }),
      })
      const payload = await response.json()
      if (!response.ok || !payload?.authorized || !payload?.summary) {
        setNotice(response.status === 503
          ? 'Owner access is not configured or the summary is unavailable.'
          : 'Access denied. Verify your account, access code and approved network.')
        return
      }
      setSummary(payload.summary)
    } catch {
      setNotice('Unable to reach the secure owner service. No data was loaded.')
    } finally {
      setCode('')
      setBusy(false)
    }
  }

  return <section className="fv-owner-page" aria-labelledby="fv-owner-title">
    <header className="fv-owner-heading">
      <div><span className="fv-web-eyebrow">OWNER ACCESS · WEB ONLY</span><h1 id="fv-owner-title">Owner Command Center</h1>
        <p>Protected operational overview. Every access request checks your signed-in owner account, security code and approved IP address.</p>
      </div>
      <span className="fv-owner-readonly">READ-ONLY</span>
    </header>

    {!summary ? <form className="fv-owner-lock" onSubmit={submit}>
      <div className="fv-owner-lock-symbol" aria-hidden="true">◇</div>
      <h2>Security verification required</h2>
      <p>This dashboard remains locked until the server confirms all three access checks. No privileged data is loaded beforehand.</p>
      <label htmlFor="fv-owner-code">Owner security code</label>
      <input id="fv-owner-code" type="password" autoComplete="off" minLength={12} maxLength={128} value={code}
        onChange={(event) => setCode(event.target.value)} disabled={busy} required />
      <button type="submit" disabled={busy || code.length < 12}>{busy ? 'Verifying…' : 'Verify owner access'}</button>
      {notice && <p role="alert" className="fv-owner-alert">{notice}</p>}
    </form> : <>
      <div className="fv-owner-toolbar"><span>Owner access verified for this request. Figures are read-only.</span>
        <button type="button" onClick={() => { setSummary(null); setNotice('') }}>Lock command center</button>
      </div>
      <div className="fv-owner-metrics">
        <article><span>Available reward reserve</span><strong>{formatMoney(summary.reward_reserve_cents)}</strong></article>
        <article><span>Cash-backed coins outstanding</span><strong>{formatCoins(summary.cash_backed_coins_outstanding)}</strong></article>
        <article><span>Creator unpaid earnings</span><strong>{formatMoney(summary.creator_earnings_unpaid_cents)}</strong></article>
        <article><span>Platform share earned</span><strong>{formatMoney(summary.platform_share_earned_cents)}</strong></article>
      </div>
      <p className="fv-owner-footnote">No transfers, refunds, bans, payouts or account changes can be made from this overview. Moderation tools belong to the next approved task.</p>
    </>}
  </section>
}

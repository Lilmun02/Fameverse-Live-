import { useEffect, useState } from 'react'
import '../../styles/web/platform-owner.css'

function formatMoney(cents) {
  return Number.isFinite(Number(cents)) ? new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD' }).format(Number(cents) / 100) : '—'
}
function formatCoins(value) {
  return Number.isFinite(Number(value)) ? Number(value).toLocaleString('en-US') : '—'
}

export default function WebOwnerCommandCenter({ account }) {
  const userId = account.session?.user?.id || null
  const token = account.session?.access_token || null
  const [status, setStatus] = useState(null)
  const [busy, setBusy] = useState(false)
  const [message, setMessage] = useState('')
  const [summary, setSummary] = useState(null)
  const [recheck, setRecheck] = useState(0)
  const owner = Boolean(userId && account.profile?.account_role === 'owner')

  useEffect(() => {
    setSummary(null)
    setMessage('')
  }, [userId])

  // Only call the owner API after the normal Fameverse account profile has loaded.
  useEffect(() => {
    if (!owner || !token) { setStatus(null); return undefined }
    const controller = new AbortController()
    setStatus(null)
    fetch('/api/owner/control', {
      method: 'POST',
      credentials: 'same-origin',
      cache: 'no-store',
      signal: controller.signal,
      headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${token}` },
      body: JSON.stringify({ action: 'status' }),
    }).then(async (response) => {
      const contentType = String(response.headers.get('content-type') || '')
      if (!contentType.includes('application/json')) {
        throw new Error('The preview access session could not be verified. Refresh this page and sign in through Vercel if prompted.')
      }
      const data = await response.json()
      if (!response.ok) throw new Error(data?.error || 'Owner verification was rejected.')
      if (!data?.verifiedAccount) throw new Error('Owner identity verification was incomplete.')
      setStatus(data)
    }).catch((error) => {
      if (error.name !== 'AbortError') {
        setMessage(error.message || 'The secure owner check could not be completed. Access remains locked.')
        setStatus({ unavailable: true })
      }
    })
    return () => controller.abort()
  }, [owner, token, recheck])

  useEffect(() => {
    if (!summary) return undefined
    const expiry = window.setTimeout(() => setSummary(null), 5 * 60 * 1000)
    const onHidden = () => { if (document.visibilityState === 'hidden') setSummary(null) }
    document.addEventListener('visibilitychange', onHidden)
    return () => { window.clearTimeout(expiry); document.removeEventListener('visibilitychange', onHidden) }
  }, [summary])

  const loadSummary = async () => {
    if (!status?.ipApproved || !status?.emailVerifiedRecently || !token || busy) return
    setBusy(true)
    setSummary(null)
    setMessage('')
    try {
      const response = await fetch('/api/owner/control', {
        method: 'POST', credentials: 'same-origin', cache: 'no-store',
        headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${token}` },
        body: JSON.stringify({ action: 'summary' }),
      })
      const data = await response.json()
      if (!response.ok || !data?.authorized) { setMessage('Owner verification expired or access denied.'); return }
      setSummary(data.summary)
    } catch {
      setMessage('Unable to load the Owner Command Center.')
    } finally { setBusy(false) }
  }

  if (!userId) return <section className="fv-owner-denied">
    <h1>Sign in to Fameverse</h1>
    <p>Use your existing Fameverse email and password in the account sign-in above. No new account or extra security password is required.</p>
  </section>

  if (!account.profile) return <section className="fv-owner-denied" role="status">
    <h1>Checking your account…</h1><p>Verifying your Fameverse owner permissions.</p>
  </section>

  if (!owner) return <section className="fv-owner-denied" role="alert">
    <h1>Owner access denied</h1><p>This account does not have verified Fameverse owner permissions.</p>
    <a href="/">Return to Home</a>
  </section>

  return <section className="fv-owner-page" aria-labelledby="fv-owner-title">
    <header className="fv-owner-heading"><div>
      <span className="fv-web-eyebrow">FAMEVERSE · WEB ONLY</span>
      <h1 id="fv-owner-title">Owner Command Center</h1>
      <p>Protected by your Fameverse account, email verification, and your approved IP address. No separate security code.</p>
    </div><span className="fv-owner-readonly">OWNER ONLY</span></header>
    {!status ? <div className="fv-owner-lock" role="status"><h2>Checking secure access…</h2><p>Verifying your account and network.</p></div> :
    status.unavailable ? <div className="fv-owner-lock"><h2>Access unavailable</h2><p>The security check failed. Your information is protected.</p><button type="button" onClick={() => setRecheck((v) => v + 1)}>Retry verification</button></div> :
    !status.emailVerifiedRecently ? <div className="fv-owner-lock" role="status">
      <h2>Email-code verification is not set up yet</h2>
      <p>Your Fameverse account may already have a confirmed email, but the extra owner verification needs a real one-time code.</p>
      <p>The previous button sent a Supabase magic sign-in link. That link redirected to the regular Fameverse website instead of completing verification on this preview, so we've disabled it rather than keep sending the wrong email.</p>
      <p className="fv-owner-note">The shared Supabase email template must be configured to provide a numeric code, then the code login and server verification must be tested. Until then, owner-only data stays locked.</p>
      <button type="button" onClick={() => setRecheck((v) => v + 1)}>Recheck owner verification</button>
    </div> :
    !status.ipApproved ? <div className="fv-owner-lock">
      <h2>IP approval required</h2>
      <p>Your dashboard is locked until your network IP has been approved. A signed-in account alone cannot bypass the IP restriction.</p>
      {status.observedIP && <p className="fv-owner-ip"><strong>IP observed by the secure server:</strong> <code>{status.observedIP}</code></p>}
      <p className="fv-owner-note">This IP is shown only after owner sign-in. Approve it before adding it to the preview allowlist; no IP is approved automatically.</p>
      <button type="button" onClick={() => setRecheck((v) => v + 1)}>Check IP again</button>
    </div> :
    <div className="fv-owner-lock">
      <h2>Email and IP verified</h2>
      <p>Your owner account, recent email verification, and allowed IP have passed the server checks.</p>
      {!summary && <button type="button" onClick={loadSummary} disabled={busy}>{busy ? 'Opening…' : 'Open Owner Command Center'}</button>}
      {summary && <div className="fv-owner-metrics">
        <article><span>Available reward reserve</span><strong>{formatMoney(summary.reward_reserve_cents)}</strong></article>
        <article><span>Cash-backed coins outstanding</span><strong>{formatCoins(summary.cash_backed_coins_outstanding)}</strong></article>
        <article><span>Creator unpaid earnings</span><strong>{formatMoney(summary.creator_earnings_unpaid_cents)}</strong></article>
        <article><span>Platform share earned</span><strong>{formatMoney(summary.platform_share_earned_cents)}</strong></article>
        <button type="button" onClick={() => setSummary(null)}>Lock dashboard</button>
      </div>}
    </div>}
    {message && <p className="fv-owner-setup-message" role="status">{message}</p>}
  </section>
}

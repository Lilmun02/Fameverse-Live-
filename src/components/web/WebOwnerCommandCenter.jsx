import { useEffect, useState } from 'react'
import { supabase } from '../../services/supabase.js'
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
  const [emailBusy, setEmailBusy] = useState(false)
  const [code, setCode] = useState('')
  const [emailSent, setEmailSent] = useState(false)
  const [message, setMessage] = useState('')
  const [summary, setSummary] = useState(null)
  const [recheck, setRecheck] = useState(0)
  const owner = Boolean(userId && account.profile?.account_role === 'owner')

  useEffect(() => {
    setSummary(null)
    setEmailSent(false)
    setCode('')
    setMessage('')
  }, [userId])

  // Only call the owner API after the normal Fameverse account profile has loaded.
  useEffect(() => {
    if (!owner || !token) { setStatus(null); return undefined }
    const controller = new AbortController()
    setStatus(null)
    fetch('/api/owner/control', {
      method: 'POST',
      credentials: 'omit',
      cache: 'no-store',
      signal: controller.signal,
      headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${token}` },
      body: JSON.stringify({ action: 'status' }),
    }).then(async (response) => {
      const data = await response.json()
      if (!response.ok) throw new Error(data?.error || 'Owner access unavailable')
      setStatus(data)
    }).catch((error) => {
      if (error.name !== 'AbortError') {
        setMessage('The secure owner check could not be completed. Access remains locked.')
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

  const sendEmailVerification = async () => {
    if (!status?.ipApproved || !account.session?.user?.email || emailBusy) return
    setEmailBusy(true)
    setMessage('')
    try {
      const { error } = await supabase.auth.signInWithOtp({
        email: account.session.user.email,
        options: { shouldCreateUser: false, emailRedirectTo: window.location.origin + '/owner' },
      })
      if (error) { setMessage('Verification email could not be sent. Check your email settings or try again later.'); return }
      setEmailSent(true)
      setMessage('Check your account email. Follow its one-time sign-in link, or enter the code if your email contains one.')
    } catch {
      setMessage('Could not request email verification. Please try again.')
    } finally { setEmailBusy(false) }
  }

  const verifyEmailCode = async (event) => {
    event.preventDefault()
    if (!/^\d{6,8}$/.test(code) || emailBusy || !account.session?.user?.email) return
    setEmailBusy(true)
    setMessage('')
    try {
      const { error } = await supabase.auth.verifyOtp({
        email: account.session.user.email, token: code, type: 'email',
      })
      if (error) { setMessage('Invalid or expired email code. Request a new verification email.'); return }
      setCode('')
      setRecheck((v) => v + 1)
    } catch {
      setMessage('Email verification failed. Please try again.')
    } finally { setEmailBusy(false) }
  }

  const loadSummary = async () => {
    if (!status?.ipApproved || !status?.emailVerifiedRecently || !token || busy) return
    setBusy(true)
    setSummary(null)
    setMessage('')
    try {
      const response = await fetch('/api/owner/control', {
        method: 'POST', credentials: 'omit', cache: 'no-store',
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
    !status.ipApproved ? <div className="fv-owner-lock">
      <h2>IP approval required</h2>
      <p>Your dashboard is locked until your network IP has been approved. A signed-in account alone cannot bypass the IP restriction.</p>
      {status.observedIP && <p className="fv-owner-ip"><strong>IP observed by the secure server:</strong> <code>{status.observedIP}</code></p>}
      <p className="fv-owner-note">This IP is shown only after owner sign-in. Approve it before adding it to the preview allowlist; no IP is approved automatically.</p>
      <button type="button" onClick={() => setRecheck((v) => v + 1)}>Check IP again</button>
    </div> :
    !status.emailVerifiedRecently ? <div className="fv-owner-lock">
      <h2>Verify your email</h2>
      <p>We'll send a one-time verification message to the email on your signed-in Fameverse owner account. The code or link is only valid for a short period.</p>
      <button type="button" onClick={sendEmailVerification} disabled={emailBusy}>{emailBusy ? 'Sending…' : 'Send verification email'}</button>
      {emailSent && <form onSubmit={verifyEmailCode} className="fv-owner-email-form">
        <label htmlFor="fv-owner-email-otp">Email verification code (if provided)</label>
        <input id="fv-owner-email-otp" inputMode="numeric" autoComplete="one-time-code" value={code}
          onChange={(e) => setCode(e.target.value.replace(/\D/g, '').slice(0, 8))} placeholder="6-digit code" />
        <button type="submit" disabled={emailBusy || code.length < 6}>Verify email code</button>
        <p>If you received a verification link instead, open it to return here.</p>
      </form>}
      <button type="button" className="fv-owner-text-button" onClick={() => setRecheck((v) => v + 1)}>Check verification status</button>
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

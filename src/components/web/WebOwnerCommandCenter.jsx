import { useEffect, useRef, useState } from 'react'
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
  const [emailSent, setEmailSent] = useState(false)
  const [emailCode, setEmailCode] = useState('')
  const passwordProof = useRef(null)
  const [message, setMessage] = useState('')
  const [summary, setSummary] = useState(null)
  const [recheck, setRecheck] = useState(0)
  const owner = Boolean(userId && account.profile?.account_role === 'owner')

  useEffect(() => {
    setSummary(null)
    setMessage('')
    setEmailCode('')
    setEmailSent(false)
    passwordProof.current = null
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
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${token}`,
        ...(passwordProof.current ? { 'X-Owner-Password-Proof': `Bearer ${passwordProof.current}` } : {}),
      },
      body: JSON.stringify({ action: 'status' }),
    }).then(async (response) => {
      const contentType = String(response.headers.get('content-type') || '')
      if (!contentType.includes('application/json')) {
        throw new Error('The preview access session could not be verified. Refresh this page and sign in through Vercel if prompted.')
      }
      const data = await response.json()
      if (!response.ok) throw new Error(data?.error || 'Owner verification was rejected.')
      if (!data?.verifiedAccount) throw new Error('Owner identity verification was incomplete.')
      if (data.passwordVerifiedRecently && !passwordProof.current) passwordProof.current = token
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

  const sendEmailCode = async () => {
    // This is deliberately inaccessible until the preview server confirms
    // that the shared email template actually sends a six-digit code.
    if (!status?.emailOtpReady || !status?.passwordVerifiedRecently || emailBusy) return
    if (!account.session?.user?.email) return
    setEmailBusy(true)
    setMessage('')
    try {
      const { error } = await supabase.auth.signInWithOtp({
        email: account.session.user.email,
        options: { shouldCreateUser: false, emailRedirectTo: window.location.origin + '/owner' },
      })
      if (error) { setMessage('Unable to send an email code.'); return }
      setEmailSent(true)
      setMessage('Verification code requested for your Fameverse email.')
    } catch {
      setMessage('Could not send verification code.')
    } finally { setEmailBusy(false) }
  }

  const verifyEmailCode = async (event) => {
    event.preventDefault()
    if (!status?.emailOtpReady || emailBusy || !/^[0-9]{6}$/.test(emailCode)) return
    const originalId = userId
    setEmailBusy(true)
    setMessage('')
    try {
      const { data, error } = await supabase.auth.verifyOtp({
        email: account.session.user.email, token: emailCode, type: 'email',
      })
      if (error || !data?.session?.access_token || data?.user?.id !== originalId) {
        setMessage('Invalid code or account mismatch. Access remains locked.')
        return
      }
      setEmailCode('')
      setEmailSent(false)
      setRecheck((i) => i + 1)
    } catch {
      setMessage('Unable to verify this code. Access remains locked.')
    } finally { setEmailBusy(false) }
  }

  const loadSummary = async () => {
    if (!status?.ipApproved || !status?.emailVerifiedRecently || !token || busy) return
    setBusy(true)
    setSummary(null)
    setMessage('')
    try {
      const response = await fetch('/api/owner/control', {
        method: 'POST', credentials: 'same-origin', cache: 'no-store',
        headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${token}`,
        ...(passwordProof.current ? { 'X-Owner-Password-Proof': `Bearer ${passwordProof.current}` } : {}),
      },
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
    !status.emailOtpReady ? <div className="fv-owner-lock" role="status">
      <h2>Owner email-code verification pending</h2>
      <p>Your Fameverse account is recognized, but the extra email-code step is not activated yet. We disabled the previous button because it sent a regular website sign-in link.</p>
      <p className="fv-owner-note">The email-code screen will only activate after the mail template is confirmed to send actual numeric codes. No changes were made to shared Supabase authentication.</p>
      <h3>Network approval</h3>
      <p>{status.ipApproved ? 'Your current network is approved.' : 'Your current network is not approved yet.'}</p>
      {status.observedIP && <p className="fv-owner-ip"><strong>IP detected by the secure server:</strong> <code>{status.observedIP}</code></p>}
      <p>This IP cannot approve itself. Owner access remains locked.</p>
      <button type="button" onClick={() => setRecheck((i) => i + 1)}>Recheck owner access</button>
    </div> :
    !status.passwordVerifiedRecently ? <div className="fv-owner-lock">
      <h2>Refresh your Fameverse password sign-in</h2>
      <p>Use the existing account sign-in at the top of the page before entering an owner email code.</p>
      <button type="button" onClick={() => setRecheck((i) => i + 1)}>Check password sign-in</button>
    </div> :
    !status.emailVerifiedRecently ? <div className="fv-owner-lock">
      <h2>Verify your email</h2>
      <p>Enter a six-digit code from your existing Fameverse email. This is not a new account or separate password.</p>
      <button type="button" onClick={sendEmailCode} disabled={emailBusy}>{emailBusy ? 'Sending…' : 'Send email code'}</button>
      {emailSent && <form className="fv-owner-email-form" onSubmit={verifyEmailCode}>
        <label htmlFor="fv-owner-email-code">Six-digit email code</label>
        <input id="fv-owner-email-code" type="text" inputMode="numeric" maxLength={6}
          autoComplete="one-time-code" value={emailCode}
          onChange={(e) => setEmailCode(e.target.value.replace(/[^0-9]/g, '').slice(0, 6))} />
        <button type="submit" disabled={emailBusy || emailCode.length !== 6}>Verify email code</button>
      </form>}
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

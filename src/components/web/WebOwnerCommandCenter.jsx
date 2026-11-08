import { useEffect, useState } from 'react'
import '../../styles/web/platform-owner.css'

const VERCEL_SETTINGS_URL = 'https://vercel.com/aiw-core/fameverse-live/settings/environment-variables'
const OWNER_BRANCH = 'feature/web-owner-command-center-gate-20261107'

function formatMoney(value) {
  if (value === null || value === undefined || !Number.isFinite(Number(value))) return '—'
  return new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD' }).format(Number(value) / 100)
}

function formatCoins(value) {
  if (value === null || value === undefined || !Number.isFinite(Number(value))) return '—'
  return Number(value).toLocaleString('en-US')
}

function OwnerSetup({ account, onRecheck }) {
  const [code, setCode] = useState('')
  const [confirm, setConfirm] = useState('')
  const [prepared, setPrepared] = useState(null)
  const [busy, setBusy] = useState(false)
  const [message, setMessage] = useState('')

  const prepare = async (event) => {
    event.preventDefault()
    if (busy) return
    if (code.length < 16 || code.length > 128) {
      setMessage('Choose a unique code at least 16 characters long.')
      return
    }
    if (code !== confirm) {
      setMessage('Both security code entries must match.')
      return
    }
    setBusy(true)
    setMessage('')
    setPrepared(null)
    try {
      const response = await fetch('/api/owner/control', {
        method: 'POST',
        credentials: 'omit',
        cache: 'no-store',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${account.session.access_token}`,
        },
        body: JSON.stringify({ action: 'prepare', code }),
      })
      const payload = await response.json()
      if (!response.ok || !payload?.prepared || !payload?.allowedIP || !payload?.salt || !payload?.hash) {
        setMessage(payload?.error || 'Setup could not be prepared. No code was saved.')
        return
      }
      setPrepared(payload)
      setMessage('Setup values generated. No code is active yet.')
    } catch {
      setMessage('Unable to connect. No security code has been created.')
    } finally {
      setCode('')
      setConfirm('')
      setBusy(false)
    }
  }

  const copy = async (value, label) => {
    try {
      await navigator.clipboard.writeText(value)
      setMessage(`${label} copied. Paste it only into the matching Vercel preview environment variable.`)
    } catch {
      setMessage('Copy was blocked. Select the value and copy it manually.')
    }
  }

  return <section className="fv-owner-setup" aria-labelledby="fv-owner-setup-title">
    <span className="fv-web-eyebrow">OWNER COMMAND CENTER · PREVIEW SETUP</span>
    <h1 id="fv-owner-setup-title">Set up your Owner Command Center</h1>
    <p className="fv-owner-lede">You're already using your Fameverse account. This is the one-time setup for an extra security code and an approved network—not a second account or a new password.</p>
    <div className="fv-owner-setup-step">
      <span className="fv-owner-step-number">1</span>
      <div>
        <h2>Choose your private security code</h2>
        <p>Choose a unique code of at least 16 characters and save it in a password manager. Do not use your Fameverse password. Never paste your code into chat.</p>
        {!prepared ? <form className="fv-owner-setup-form" onSubmit={prepare}>
          <label htmlFor="fv-owner-setup-code">New owner security code</label>
          <input id="fv-owner-setup-code" type="password" minLength={16} maxLength={128} autoComplete="new-password" value={code} onChange={(event) => setCode(event.target.value)} required disabled={busy} />
          <label htmlFor="fv-owner-setup-confirm">Confirm your code</label>
          <input id="fv-owner-setup-confirm" type="password" minLength={16} maxLength={128} autoComplete="new-password" value={confirm} onChange={(event) => setConfirm(event.target.value)} required disabled={busy} />
          <button type="submit" disabled={busy || code.length < 16 || code !== confirm}>{busy ? 'Preparing…' : 'Prepare secure setup'}</button>
        </form> : <p className="fv-owner-notice" role="status">Your code was processed securely for this request, not saved. Keep your original code safely—you'll need it after activation.</p>}
      </div>
    </div>
    <div className="fv-owner-setup-step">
      <span className="fv-owner-step-number">2</span>
      <div>
        <h2>Save the setup values in Vercel</h2>
        <p>Open your Fameverse Vercel project, go to <strong>Settings → Environment Variables</strong>, and create these three variables. Select <strong>Preview</strong> and restrict them to the branch below. Do not select Production.</p>
        <p className="fv-owner-branch"><strong>Preview branch:</strong> <code>{OWNER_BRANCH}</code></p>
        {prepared ? <div className="fv-owner-setup-values">
          {[
            ['OWNER_ALLOWED_IPS', prepared.allowedIP],
            ['OWNER_ACCESS_CODE_SALT', prepared.salt],
            ['OWNER_ACCESS_CODE_SCRYPT_HASH', prepared.hash],
          ].map(([name, value]) => <div className="fv-owner-setup-value" key={name}>
            <label>{name}</label>
            <code>{value}</code>
            <button type="button" onClick={() => copy(value, name)}>Copy value</button>
          </div>)}
        </div> : <p className="fv-owner-note">Generate your setup in Step 1 to see the exact IP, salt and security-code hash that must be saved. Your real security code will not appear here.</p>}
        <a className="fv-owner-setup-link" href={VERCEL_SETTINGS_URL} target="_blank" rel="noopener noreferrer">Open Fameverse environment settings</a>
      </div>
    </div>
    <div className="fv-owner-setup-step">
      <span className="fv-owner-step-number">3</span>
      <div>
        <h2>Redeploy the preview and unlock</h2>
        <p>After saving those three variables, go to your Vercel Deployments and <strong>redeploy this preview branch</strong>. Environment changes only apply to new deployments. Then reopen this page and check setup.</p>
        <button className="fv-owner-refresh" type="button" onClick={onRecheck}>Check setup again</button>
        <p className="fv-owner-note">If your network's public IP changes, the IP allowlist must be updated privately in Vercel. Never enter credentials on an unrecognized website.</p>
      </div>
    </div>
    {message && <p className="fv-owner-setup-message" role="status">{message}</p>}
  </section>
}

export default function WebOwnerCommandCenter({ account }) {
  const [code, setCode] = useState('')
  const [busy, setBusy] = useState(false)
  const [summary, setSummary] = useState(null)
  const [notice, setNotice] = useState('')
  const [gateStatus, setGateStatus] = useState('checking')
  const [recheck, setRecheck] = useState(0)
  const owner = Boolean(account.session?.user?.id && account.profile?.account_role === 'owner')

  useEffect(() => {
    setCode('')
    setSummary(null)
    setNotice('')
  }, [account.session?.user?.id, account.session?.access_token])

  useEffect(() => {
    const controller = new AbortController()
    setGateStatus('checking')
    fetch('/api/owner/control', { method: 'GET', credentials: 'omit', cache: 'no-store', signal: controller.signal })
      .then(async (response) => {
        if (!response.ok) throw new Error('Status unavailable')
        const result = await response.json()
        setGateStatus(result.configured === true ? 'ready' : 'unconfigured')
      })
      .catch((error) => {
        if (error.name !== 'AbortError') setGateStatus('unavailable')
      })
    return () => controller.abort()
  }, [recheck])

  useEffect(() => {
    if (!summary) return undefined
    const expiry = window.setTimeout(() => setSummary(null), 5 * 60 * 1000)
    const lockWhenHidden = () => { if (document.visibilityState === 'hidden') setSummary(null) }
    document.addEventListener('visibilitychange', lockWhenHidden)
    return () => { window.clearTimeout(expiry); document.removeEventListener('visibilitychange', lockWhenHidden) }
  }, [summary])

  if (gateStatus === 'checking') return <section className="fv-owner-denied" role="status"><h1>Checking owner setup…</h1><p>Checking that your security settings are ready.</p></section>

  if (!account.session?.user?.id) return <section className="fv-owner-denied" role="status">
    <h1>Sign in with your Fameverse account</h1>
    <p>Use your normal Fameverse sign-in from the top of the page. You do not need to create a second account.</p>
    <a href="/">Return to Fameverse</a>
  </section>

  if (!account.profile) return <section className="fv-owner-denied" role="status">
    <h1>Checking your owner account…</h1>
    <p>Waiting for the signed-in account profile and owner permissions to load.</p>
  </section>

  if (!owner) return <section className="fv-owner-denied" role="alert">
    <h1>Owner account required</h1>
    <p>This Fameverse account has not been verified as an owner. A security code cannot grant owner permissions.</p>
    <a href="/">Return to Home</a>
  </section>

  if (gateStatus === 'unconfigured') return <OwnerSetup account={account} onRecheck={() => setRecheck((n) => n + 1)} />

  if (gateStatus !== 'ready') return <section className="fv-owner-denied" role="alert">
    <h1>Owner setup could not be checked</h1>
    <p>The security service did not respond correctly. Your dashboard is locked until setup can be verified.</p>
    <button type="button" onClick={() => setRecheck((n) => n + 1)}>Retry connection</button>
  </section>

  const submit = async (event) => {
    event.preventDefault()
    if (busy || code.length < 12 || !account.session?.access_token) return
    setBusy(true)
    setNotice('')
    setSummary(null)
    try {
      const response = await fetch('/api/owner/control', {
        method: 'POST', credentials: 'omit',
        headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${account.session.access_token}` },
        body: JSON.stringify({ action: 'summary', code }),
      })
      const payload = await response.json()
      if (!response.ok || !payload?.authorized || !payload?.summary) {
        setNotice(response.status === 503 ? 'Owner access is not configured or the summary is unavailable.' : 'Access denied. Check your code and approved network.')
        return
      }
      setSummary(payload.summary)
    } catch {
      setNotice('Unable to reach the secure owner service. No data was loaded.')
    } finally { setCode(''); setBusy(false) }
  }

  return <section className="fv-owner-page" aria-labelledby="fv-owner-title">
    <header className="fv-owner-heading">
      <div><span className="fv-web-eyebrow">OWNER ACCESS · WEB ONLY</span><h1 id="fv-owner-title">Owner Command Center</h1>
        <p>Read-only overview protected by your Fameverse owner account, your security code and your approved IP address.</p>
      </div><span className="fv-owner-readonly">READ-ONLY</span>
    </header>
    {!summary ? <form className="fv-owner-lock" onSubmit={submit}>
      <div className="fv-owner-lock-symbol" aria-hidden="true">◇</div>
      <h2>Enter your owner security code</h2>
      <p>This is the code you set up privately in Vercel, not your Fameverse password.</p>
      <label htmlFor="fv-owner-code">Owner security code</label>
      <input id="fv-owner-code" type="password" autoComplete="off" minLength={12} maxLength={128} value={code} onChange={(event) => setCode(event.target.value)} disabled={busy} required />
      <button type="submit" disabled={busy || code.length < 12}>{busy ? 'Verifying…' : 'Unlock Owner Command Center'}</button>
      {notice && <p role="alert" className="fv-owner-alert">{notice}</p>}
    </form> : <>
      <div className="fv-owner-toolbar"><span>Owner access verified. Figures are read-only.</span><button type="button" onClick={() => { setSummary(null); setNotice('') }}>Lock command center</button></div>
      <div className="fv-owner-metrics">
        <article><span>Available reward reserve</span><strong>{formatMoney(summary.reward_reserve_cents)}</strong></article>
        <article><span>Cash-backed coins outstanding</span><strong>{formatCoins(summary.cash_backed_coins_outstanding)}</strong></article>
        <article><span>Creator unpaid earnings</span><strong>{formatMoney(summary.creator_earnings_unpaid_cents)}</strong></article>
        <article><span>Platform share earned</span><strong>{formatMoney(summary.platform_share_earned_cents)}</strong></article>
      </div>
      <p className="fv-owner-footnote">No refunds, payouts, bans or account changes are available from this overview.</p>
    </>}
  </section>
}

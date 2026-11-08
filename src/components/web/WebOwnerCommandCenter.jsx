import { useEffect, useState } from 'react'
import '../../styles/web/platform-owner.css'
import OwnerConsoleWorkspace from './OwnerConsoleWorkspace.jsx'

export default function WebOwnerCommandCenter({ account }) {
  const userId = account.session?.user?.id || null
  const token = account.session?.access_token || null
  const owner = Boolean(userId && account.profile?.account_role === 'owner')
  const sessionKey = userId && token ? `${userId}:${token}` : null
  const [attempt, setAttempt] = useState(0)
  const [result, setResult] = useState({ key: null, state: 'checking', summary: null, message: '' })

  // Account sign-in and IP verification run automatically. No new code or
  // Vercel setup form is ever shown to an authenticated owner.
  useEffect(() => {
    if (!owner || !token || !sessionKey) return undefined
    const controller = new AbortController()
    let active = true
    setResult({ key: sessionKey, state: 'checking', summary: null, message: '' })

    fetch('/api/owner/control', {
      method: 'POST',
      credentials: 'same-origin',
      cache: 'no-store',
      signal: controller.signal,
      headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${token}` },
      body: JSON.stringify({ action: 'summary' }),
    }).then(async (response) => {
      const type = String(response.headers.get('content-type') || '')
      if (!type.includes('application/json')) throw new Error('The protected preview session could not be verified.')
      const data = await response.json()
      if (!active) return
      if (response.status === 403 && data?.code === 'NETWORK_DENIED') {
        setResult({ key: sessionKey, state: 'network', summary: null, message: '' })
      } else if (!response.ok || !data?.authorized || data?.mode !== 'read-only' || !data?.summary) {
        setResult({ key: sessionKey, state: 'denied', summary: null, message: data?.error || 'Owner access was denied.' })
      } else {
        setResult({ key: sessionKey, state: 'ready', summary: data.summary, message: '' })
      }
    }).catch((error) => {
      if (active && error.name !== 'AbortError') {
        setResult({ key: sessionKey, state: 'unavailable', summary: null, message: 'The secure owner check could not be completed.' })
      }
    })

    return () => { active = false; controller.abort() }
  }, [owner, token, sessionKey, attempt])

  // Prevent sensitive figures remaining on screen unattended. A retry requires
  // fresh authentication and IP checks on the server.
  useEffect(() => {
    if (result.state !== 'ready') return undefined
    const expiry = window.setTimeout(() => setResult(prev => ({ ...prev, state: 'locked', summary: null })), 5 * 60 * 1000)
    const whenHidden = () => {
      if (document.visibilityState === 'hidden') {
        setResult(prev => ({ ...prev, state: 'locked', summary: null }))
      }
    }
    document.addEventListener('visibilitychange', whenHidden)
    return () => { window.clearTimeout(expiry); document.removeEventListener('visibilitychange', whenHidden) }
  }, [result.state])

  if (!userId) return <section className="fv-owner-denied">
    <h1>Sign in to Fameverse</h1>
    <p>Use your existing Fameverse account in the sign-in menu above. No extra code or separate account is required.</p>
  </section>
  if (!account.profile) return <section className="fv-owner-denied" role="status">
    <h1>Checking your Fameverse account…</h1>
    <p>Verifying your account permissions.</p>
  </section>
  if (!owner) return <section className="fv-owner-denied" role="alert">
    <h1>Owner account required</h1>
    <p>This account doesn't have verified Fameverse owner permissions.</p>
    <a href="/">Return to Home</a>
  </section>

  const current = result.key === sessionKey ? result : { state: 'checking', summary: null, message: '' }
  return <section className="fv-owner-page fv-owner-full" aria-labelledby="fv-owner-title">
    <header className="fv-owner-heading">
      <div><span className="fv-web-eyebrow">FAMEVERSE · WEB ONLY</span>
        <h1 id="fv-owner-title">Owner Command Center</h1>
        <p>Protected by your Fameverse account and one approved network IP. No additional sign-in code.</p>
      </div>
      <span className="fv-owner-readonly">OWNER ONLY</span>
    </header>
    {current.state === 'ready' && current.summary ?
      <OwnerConsoleWorkspace token={token} overview={current.summary}
        onLock={() => setResult(prev => ({...prev,state:'locked',summary:null}))} />
     : <div className="fv-owner-lock" role="status">
      <h2>{current.state === 'checking' ? 'Checking account and IP…' :
        current.state === 'network' ? 'Network blocked' :
        current.state === 'locked' ? 'Owner dashboard locked' :
        current.state === 'denied' ? 'Access denied' : 'Access unavailable'}</h2>
      <p>{current.state === 'checking' ? 'Verifying your existing Fameverse session and approved network.' :
        current.state === 'network' ? 'This IP address is not approved for the Owner Command Center. No owner data was loaded.' :
        current.state === 'locked' ? 'Your private overview is locked. Reopen it with fresh account and network checks.' :
        current.message || 'Your owner information remains protected.'}</p>
      {current.state !== 'checking' && <button type="button" onClick={() => setAttempt(n => n + 1)}>Retry secure access</button>}
    </div>}
  </section>
}

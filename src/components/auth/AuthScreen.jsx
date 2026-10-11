import { useState } from 'react'
import { supabase } from '../../services/supabase.js'

export default function AuthScreen({ authMode, setAuthMode, authForm, setAuthForm, authMessage, setAuthMessage, submitAuth }) {
  const [recoveryBusy, setRecoveryBusy] = useState(false)
  const requestRecovery = async () => {
    const email = authForm.email.trim()
    if (!email) { setAuthMessage('Enter your email address first.'); return }
    setRecoveryBusy(true)
    try {
      const { error } = await supabase.auth.resetPasswordForEmail(email, {
        redirectTo: 'https://fameverse-live.vercel.app/reset-password.html',
      })
      setAuthMessage(error ? error.message : 'If this account exists, check your email for a password-reset link.')
    } catch (_) {
      setAuthMessage('Could not request a reset. Please try again.')
    } finally { setRecoveryBusy(false) }
  }

  return (
    <div className="auth-shell">
      <div className="auth-brand"><span>FAMEVERSE</span> LIVE <b>BETA 0.2</b></div>
      <section className="auth-card">
        <div>
          <span className="eyebrow">ACCOUNT</span>
          <h1>{authMode === 'signup' ? 'Create your Fameverse account' : 'Welcome back'}</h1>
          <p>Sign in to your Fameverse beta account.</p>
        </div>
        <form className="auth-form" onSubmit={submitAuth}>
          {authMode === 'signup' && (
            <label>
              Display name
              <input
                value={authForm.displayName}
                onChange={(event) => setAuthForm({ ...authForm, displayName: event.target.value })}
                maxLength={40}
                placeholder="Your name"
              />
            </label>
          )}
          <label>
            Email
            <input
              type="email"
              autoComplete="email"
              value={authForm.email}
              onChange={(event) => setAuthForm({ ...authForm, email: event.target.value })}
              placeholder="you@example.com"
            />
          </label>
          <label>
            Password
            <input
              type="password"
              autoComplete={authMode === 'signup' ? 'new-password' : 'current-password'}
              value={authForm.password}
              onChange={(event) => setAuthForm({ ...authForm, password: event.target.value })}
              minLength={6}
              placeholder="6+ characters"
            />
          </label>
          {authMessage && <div className="auth-message">{authMessage}</div>}
          <button className="auth-primary" type="submit">{authMode === 'signup' ? 'Create account' : 'Sign in'}</button>
        </form>
        {authMode === 'signin' && (
          <button type="button" className="auth-switch" disabled={recoveryBusy} onClick={requestRecovery}>
            {recoveryBusy ? 'Sending reset email…' : 'Forgot password?'}
          </button>
        )}
        <button
          className="auth-switch"
          onClick={() => {
            setAuthMode(authMode === 'signup' ? 'signin' : 'signup')
            setAuthMessage('')
          }}
        >
          {authMode === 'signup' ? 'Already have an account? Sign in' : 'New to Fameverse? Create account'}
        </button>
      </section>
    </div>
  )
}

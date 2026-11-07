import { useState } from 'react'
import { supabase } from '../../services/supabase.js'

export default function WebSettingsPage({ account }) {
  const user = account.session?.user
  const [busy, setBusy] = useState(false)
  const [notice, setNotice] = useState('')
  const [passwordBusy, setPasswordBusy] = useState(false)

  const sendReset = async () => {
    if (!user?.email || passwordBusy) return
    setPasswordBusy(true)
    setNotice('')
    try {
      const { error } = await supabase.auth.resetPasswordForEmail(user.email, {
        redirectTo: 'https://fameverse.app/reset-password',
      })
      setNotice(error ? 'Unable to send a password reset email right now. Try again later.' : 'Password reset email requested. Check your inbox and spam folder.')
    } catch {
      setNotice('Could not reach account security. Try again later.')
    } finally { setPasswordBusy(false) }
  }

  const save = async (event) => {
    event.preventDefault()
    if (busy) return
    setBusy(true)
    setNotice('')
    try {
      const success = await account.saveProfile(event)
      setNotice(success ? 'Your profile settings were saved.' : 'Profile could not be saved. Check your entries and try again.')
    } finally { setBusy(false) }
  }

  return <main className="fv-settings-page">
    <header><span className="fv-web-eyebrow">ACCOUNT CENTER</span><h1>Settings</h1><p>Manage the Fameverse account you are signed in to.</p></header>
    <section className="fv-settings-section">
      <h2>Account identity</h2>
      <p>Signed in as <strong>{account.profile?.display_name || user?.email || 'Fameverse member'}</strong></p>
      <label>Email address<input value={user?.email || ''} readOnly aria-label="Account email address" /></label>
      <p className="fv-settings-hint">Email changes are not available here. Your accounts remain separate.</p>
    </section>
    <section className="fv-settings-section">
      <h2>Public profile</h2>
      <form onSubmit={save}>
        <label>Display name<input required maxLength={60} value={account.profileDraft.display_name} onChange={(e) => account.setProfileDraft((d) => ({ ...d, display_name: e.target.value }))} /></label>
        <label>Username<input minLength={3} maxLength={30} value={account.profileDraft.username} onChange={(e) => account.setProfileDraft((d) => ({ ...d, username: e.target.value }))} /></label>
        <label>Bio<textarea rows={4} maxLength={160} value={account.profileDraft.bio} onChange={(e) => account.setProfileDraft((d) => ({ ...d, bio: e.target.value }))} /></label>
        <button type="submit" disabled={busy || account.profileBusy}>{busy || account.profileBusy ? 'Saving…' : 'Save profile'}</button>
      </form>
    </section>
    <section className="fv-settings-section">
      <h2>Security</h2>
      <p>Reset your password through the official Fameverse website.</p>
      <button type="button" onClick={sendReset} disabled={passwordBusy}>{passwordBusy ? 'Sending…' : 'Email me a password reset link'}</button>
    </section>
    {notice && <p role="status" className="fv-settings-notice">{notice}</p>}
  </main>
}

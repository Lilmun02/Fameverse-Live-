import { useEffect, useState } from 'react'
import { supabase } from '../../services/supabase.js'

const POLICY_ENABLED = import.meta.env.VITE_FAMEVERSE_POLICY_GATE_ENABLED === 'true'

export default function PolicyAgreementGate({ userId, children }) {
  const [policy, setPolicy] = useState(null)
  const [checking, setChecking] = useState(true)
  const [checked, setChecked] = useState(false)
  const [saving, setSaving] = useState(false)
  const [approved, setApproved] = useState(false)
  const [error, setError] = useState('')

  useEffect(() => {
    if (!POLICY_ENABLED || !userId) return
    let active = true
    setChecking(true)
    setApproved(false)
    setChecked(false)
    setPolicy(null)
    setError('')
    supabase.rpc('fv_get_policy_requirement')
      .then(({ data, error: serverError }) => {
        if (!active) return
        if (serverError || !data?.version) throw new Error('Policy unavailable')
        setPolicy(data)
        setApproved(data.accepted === true)
      })
      .catch(() => {
        if (active) setError('Could not verify your policy agreement. Please retry.')
      })
      .finally(() => { if (active) setChecking(false) })
    return () => { active = false }
  }, [userId])

  if (!POLICY_ENABLED || !userId || approved) return children

  const accept = async () => {
    if (!checked || saving || !policy?.version) return
    setSaving(true)
    setError('')
    try {
      const { data, error: saveError } = await supabase.rpc('fv_accept_current_policy')
      if (saveError || !data?.accepted || data.version !== policy.version) {
        throw new Error('Save failed')
      }
      const { data: confirmation, error: confirmError } =
        await supabase.rpc('fv_get_policy_requirement')
      if (confirmError || !confirmation?.accepted ||
          confirmation.version !== policy.version) throw new Error('Not confirmed')
      setApproved(true)
    } catch (_) {
      setChecked(false)
      setError('Agreement was not confirmed by Fameverse. Please retry.')
    } finally {
      setSaving(false)
    }
  }

  const documents = [
    ['Terms of Service', policy?.terms],
    ['Community Standards', policy?.community],
    ['Financial Protection Policy', policy?.financial],
    ['Privacy Notice', policy?.privacy],
  ]

  return (
    <main className="auth-shell" aria-label="Fameverse policy agreement">
      <section className="auth-card">
        <h1>Fameverse policies</h1>
        <p>Review our updated terms before continuing. Up to two accounts
          per person; dishonest chargebacks, payment fraud, and gift or payout
          manipulation are prohibited. Good-faith billing disputes remain protected.</p>
        {checking && <p role="status">Checking your policy agreement…</p>}
        {policy && !checking && (
          <>
            <p>Version: {policy.version}</p>
            {documents.map(([title, body]) => (
              <details key={title}>
                <summary>{title}</summary>
                <p>{body}</p>
              </details>
            ))}
            <label>
              <input type="checkbox" checked={checked}
                onChange={event => setChecked(event.target.checked)} disabled={saving} />
              I have read and agree to the Terms of Service, Community Standards
              and Financial Protection Policy, and acknowledge the Privacy Notice.
            </label>
            <button type="button" className="auth-primary"
              disabled={!checked || saving} onClick={accept}>
              {saving ? 'Saving agreement…' : 'Accept & continue'}
            </button>
          </>
        )}
        {error && <p role="alert">{error}</p>}
        {!checking && error && (
          <button type="button" onClick={() => window.location.reload()}>
            Retry agreement check
          </button>
        )}
        <button type="button" className="auth-switch"
          onClick={() => supabase.auth.signOut()}>Sign out</button>
      </section>
    </main>
  )
}

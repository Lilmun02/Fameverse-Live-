import { useEffect, useRef, useState } from 'react'
import { supabase } from '../../services/supabase.js'
import WebIcon from './WebIcon.jsx'

export default function WebSupportMessenger({ userId, onSignIn }) {
  const [open, setOpen] = useState(false)
  const [subject, setSubject] = useState('Account help')
  const [message, setMessage] = useState('')
  const [busy, setBusy] = useState(false)
  const [status, setStatus] = useState('')
  const [sent, setSent] = useState(false)
  const dialog = useRef(null)

  useEffect(() => {
    if (open && dialog.current && !dialog.current.open) dialog.current.showModal()
  }, [open])

  const close = () => {
    if (busy) return
    dialog.current?.close()
    setOpen(false)
    setStatus('')
    setSent(false)
  }

  const submit = async (event) => {
    event.preventDefault()
    if (busy) return
    const text = message.trim()
    if (text.length < 3) { setStatus('Please describe how we can help.'); return }
    if (!userId) { setStatus('Sign in before sending a support message.'); return }
    setBusy(true)
    setStatus('')
    const category = subject === 'Report a bug' ? 'bug' : 'other'
    try {
      const { error } = await supabase.from('beta_feedback').insert({
        user_id: userId,
        category,
        message: `[Web support: ${subject}] ${text}`,
        app_version: 'web',
        current_screen: 'web_support',
        live_active: false,
        device_info: { source: 'fameverse_web_support' },
      })
      if (error) { setStatus('We could not send your message. Please try again.'); return }
      setMessage('')
      setSent(true)
      setStatus('Your message was submitted to Fameverse support.')
    } catch {
      setStatus('Connection failed. Your message was not sent.')
    } finally { setBusy(false) }
  }

  return <>
    <button type="button" className="fv-support-launcher" aria-label="Message Fameverse support" aria-haspopup="dialog" aria-expanded={open} onClick={() => { setOpen(true); setStatus(''); setSent(false) }}>
      <WebIcon name="message" size={23} /><span>Support</span>
    </button>
    {open && <dialog className="fv-support-dialog" ref={dialog} onClose={() => { setOpen(false); setSent(false) }} aria-labelledby="fv-support-title">
      <div className="fv-support-heading"><div><span className="fv-web-eyebrow">FAMEVERSE HELP</span><h2 id="fv-support-title">Message support</h2></div><button type="button" aria-label="Close support" onClick={close}><WebIcon name="close" size={20} /></button></div>
      <p>Send us a support message. This is not a live chat; replies are not guaranteed instantly.</p>
      {!userId ? <div className="fv-support-guest"><p>Sign in with your Fameverse account so we can associate the request with you.</p><button type="button" onClick={() => { close(); onSignIn() }}>Sign in to message support</button></div> :
        sent ? <div className="fv-support-success"><p role="status">{status}</p><button type="button" onClick={close}>Done</button><button type="button" onClick={() => { setSent(false); setStatus('') }}>Send another</button></div> :
        <form className="fv-support-form" onSubmit={submit}>
          <label>What do you need help with?
            <select value={subject} onChange={(event) => setSubject(event.target.value)} disabled={busy}>
              <option>Account help</option><option>Coins or purchases</option><option>Report a bug</option><option>Other</option>
            </select>
          </label>
          <label>Message
            <textarea required minLength={3} maxLength={1800} rows={5} value={message} onChange={(event) => setMessage(event.target.value)} placeholder="Tell us what happened or what you need help with…" disabled={busy} />
          </label>
          <small>Do not include passwords or payment card details.</small>
          {status && <p role="alert">{status}</p>}
          <button type="submit" disabled={busy || message.trim().length < 3}>{busy ? 'Sending…' : 'Send support message'}</button>
        </form>}
    </dialog>}
  </>
}

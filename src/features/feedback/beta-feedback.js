import { supabase } from './supabase.js'

const VERSION = 'beta-0.2'

if (typeof window !== 'undefined') {
  let session = null
  let open = false

  const root = document.createElement('div')
  root.id = 'fameverse-beta-feedback'
  root.innerHTML = `
    <button class="beta-feedback-launcher" type="button" aria-label="Send beta feedback">BETA FEEDBACK</button>
    <div class="beta-feedback-backdrop" hidden>
      <section class="beta-feedback-modal" role="dialog" aria-modal="true" aria-labelledby="beta-feedback-title">
        <div class="beta-feedback-handle"></div>
        <div class="beta-feedback-heading">
          <div><span>PRIVATE BETA</span><strong id="beta-feedback-title">Report a problem</strong></div>
          <button class="beta-feedback-close" type="button" aria-label="Close feedback">×</button>
        </div>
        <p class="beta-feedback-copy">Tell us what happened. Fameverse adds basic device and app-state details so iPhone and Android bugs can be separated.</p>
        <label>Type
          <select class="beta-feedback-category">
            <option value="bug">Bug / glitch</option>
            <option value="camera_audio">Camera / microphone</option>
            <option value="performance">Crash / performance</option>
            <option value="ui_ux">Layout / usability</option>
            <option value="feature">Feature suggestion</option>
            <option value="other">Other</option>
          </select>
        </label>
        <label>What happened?
          <textarea class="beta-feedback-message" maxlength="2000" rows="6" placeholder="Example: I flipped to the back camera and the live screen turned purple..."></textarea>
        </label>
        <label class="beta-feedback-device-row"><input class="beta-feedback-device" type="checkbox" checked /> Include device/browser details</label>
        <div class="beta-feedback-status" aria-live="polite"></div>
        <button class="beta-feedback-submit" type="button">Send feedback</button>
      </section>
    </div>
  `

  const mount = () => {
    if (!document.body || document.getElementById(root.id)) return
    document.body.appendChild(root)
  }

  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', mount, { once: true })
  else mount()

  const launcher = root.querySelector('.beta-feedback-launcher')
  const backdrop = root.querySelector('.beta-feedback-backdrop')
  const modal = root.querySelector('.beta-feedback-modal')
  const closeButton = root.querySelector('.beta-feedback-close')
  const submitButton = root.querySelector('.beta-feedback-submit')
  const message = root.querySelector('.beta-feedback-message')
  const category = root.querySelector('.beta-feedback-category')
  const includeDevice = root.querySelector('.beta-feedback-device')
  const status = root.querySelector('.beta-feedback-status')

  function setVisible(visible) {
    open = visible
    backdrop.hidden = !visible
    launcher.hidden = visible || !session
    if (visible) setTimeout(() => message.focus(), 80)
  }

  function currentScreen() {
    const profile = document.querySelector('.profile-panel, .settings-home, .creator-studio-page, .account-panel')
    if (profile) return 'profile'
    if (document.querySelector('.discover-empty-panel')) return 'discover'
    if (document.querySelector('.mobile-live-shell.is-live')) return 'live'
    if (document.querySelector('.mobile-live-shell')) return 'live_setup'
    return 'unknown'
  }

  function deviceInfo() {
    const standalone = window.matchMedia?.('(display-mode: standalone)').matches || navigator.standalone === true
    return {
      userAgent: navigator.userAgent,
      platform: navigator.platform || null,
      language: navigator.language || null,
      standalone,
      viewport: `${window.innerWidth}x${window.innerHeight}`,
      screen: `${window.screen?.width || 0}x${window.screen?.height || 0}`,
      pixelRatio: window.devicePixelRatio || 1,
      touchPoints: navigator.maxTouchPoints || 0,
      online: navigator.onLine,
    }
  }

  async function refreshSession() {
    const { data } = await supabase.auth.getSession()
    session = data.session
    launcher.hidden = open || !session
  }

  launcher.addEventListener('click', () => {
    status.textContent = ''
    setVisible(true)
  })
  closeButton.addEventListener('click', () => setVisible(false))
  backdrop.addEventListener('click', (event) => {
    if (event.target === backdrop) setVisible(false)
  })
  modal.addEventListener('click', (event) => event.stopPropagation())

  submitButton.addEventListener('click', async () => {
    const text = message.value.trim()
    if (text.length < 3) {
      status.textContent = 'Add a little more detail before sending.'
      return
    }

    if (!session?.user?.id) await refreshSession()
    if (!session?.user?.id) {
      status.textContent = 'Sign in again before sending feedback.'
      return
    }

    submitButton.disabled = true
    submitButton.textContent = 'Sending…'
    status.textContent = ''

    const liveActive = Boolean(document.querySelector('.mobile-live-shell.is-live'))
    const { error } = await supabase.from('beta_feedback').insert({
      user_id: session.user.id,
      category: category.value,
      message: text,
      app_version: VERSION,
      current_screen: currentScreen(),
      live_active: liveActive,
      device_info: includeDevice.checked ? deviceInfo() : {},
    })

    submitButton.disabled = false
    submitButton.textContent = 'Send feedback'

    if (error) {
      status.textContent = 'Could not send feedback. Try again in a moment.'
      return
    }

    status.textContent = 'Feedback sent. Thank you for testing Fameverse.'
    message.value = ''
    setTimeout(() => setVisible(false), 1100)
  })

  supabase.auth.onAuthStateChange((_event, nextSession) => {
    session = nextSession
    launcher.hidden = open || !session
  })

  refreshSession()
}

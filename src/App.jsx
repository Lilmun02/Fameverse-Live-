import { useEffect, useMemo, useRef, useState } from 'react'
import { supabase } from './supabase.js'

const gifts = [
  { id: 'rose', emoji: '🌹', label: 'Rose', cost: 1 },
  { id: 'heart', emoji: '💜', label: 'Heart', cost: 5 },
  { id: 'fire', emoji: '🔥', label: 'Fire', cost: 10 },
  { id: 'star', emoji: '⭐', label: 'Star', cost: 20 },
  { id: 'crown', emoji: '👑', label: 'Crown', cost: 50 },
  { id: 'dragon', emoji: '🐉', label: 'Dragon', cost: 100 },
]

const legalPages = {
  terms: {
    eyebrow: 'TERMS OF SERVICE',
    title: 'Fameverse beta terms',
    intro: 'These beta terms set the ground rules for using Fameverse while the platform is being tested.',
    sections: [
      ['Use Fameverse lawfully', 'Do not use Fameverse to commit crimes, facilitate fraud, distribute illegal content, evade platform enforcement, or interfere with the service.'],
      ['Your account', 'You are responsible for activity on your account and for keeping your sign-in information private. Do not impersonate another person or misrepresent your identity to deceive others.'],
      ['Live content', 'Creators are responsible for what they stream, post, say, display, or send through Fameverse. Content may be removed or accounts restricted when platform rules are violated.'],
      ['Beta services', 'Features may change, fail, be limited, or be removed during beta. Test coins and test gifts have no cash value and are not purchases, earnings, or payouts.'],
    ],
  },
  privacy: {
    eyebrow: 'PRIVACY POLICY',
    title: 'Privacy in the current beta',
    intro: 'This beta notice describes what Fameverse currently stores and what remains on your device.',
    sections: [
      ['Account data', 'Fameverse currently stores account email and profile information needed to create and manage your beta account.'],
      ['Camera and microphone', 'Fameverse requests camera and microphone access only when you start the local live preview. Remote broadcasting is not enabled yet.'],
      ['Local test systems', 'Test gift balance, gift activity, and live comments are currently local test systems and are not a production creator wallet or realtime chat service.'],
      ['Before public launch', 'Privacy controls, retention rules, support contact details, and final production policies still require completion and legal review before a broad public or monetary launch.'],
    ],
  },
  use: {
    eyebrow: 'TERMS OF USE',
    title: 'Using Fameverse responsibly',
    intro: 'Fameverse is being built for live entertainment, community, creativity, and legitimate creator interaction.',
    sections: [
      ['Be authentic', 'Do not impersonate people, run scams, manipulate users, or intentionally misrepresent gifts, earnings, rankings, partnerships, or platform status.'],
      ['Respect consent and privacy', 'Do not expose private personal information, secretly record private communications, or pressure people into sharing personal or intimate material.'],
      ['Protect the platform', 'Do not probe, exploit, overload, scrape, automate abuse, bypass security, or attempt to access accounts, data, or systems without authorization.'],
      ['Age and safety', 'Age requirements and youth protections will be finalized before public launch. Beta testers must not use Fameverse to expose minors to unsafe, exploitative, or age-inappropriate interactions.'],
    ],
  },
  community: {
    eyebrow: 'COMMUNITY GUIDELINES',
    title: 'What Fameverse will and will not tolerate',
    intro: 'These beta rules apply to live streams, profiles, comments, gifts, usernames, and other community activity.',
    sections: [
      ['No harassment or threats', 'Targeted harassment, credible threats, stalking, bullying, coordinated abuse, or encouraging others to attack someone is not tolerated.'],
      ['No hateful or exploitative conduct', 'Do not promote hatred against protected groups, sexual exploitation, non-consensual intimate material, or abuse involving minors.'],
      ['No scams or dangerous deception', 'Fraud, phishing, fake giveaways, payment scams, impersonation for gain, and deceptive schemes are prohibited.'],
      ['No doxxing', 'Do not reveal another person’s private address, phone number, financial information, credentials, or other sensitive personal data without permission.'],
      ['Moderation', 'Fameverse may remove content, limit features, suspend accounts, or permanently remove accounts when behavior creates safety, legal, or platform-integrity risks.'],
    ],
  },
}

const creatorContent = {
  clips: ['Clips', 'Short highlights from your lives will appear here.'],
  replays: ['Replays', 'Saved live replays will appear here when cloud rooms are connected.'],
  gifts: ['Gifts', 'Public gift history will appear here after the production wallet is built.'],
}

function loadCoins() {
  const saved = Number(localStorage.getItem('fameverse-owner-test-coins'))
  return Number.isFinite(saved) && saved >= 0 ? saved : 10000
}

function isRunningStandalone() {
  return window.matchMedia?.('(display-mode: standalone)').matches || window.navigator.standalone === true
}

function cleanUsername(value = '') {
  return value.toLowerCase().replace(/^@/, '').replace(/[^a-z0-9_]/g, '').slice(0, 24)
}

function LegalPage({ page, onBack }) {
  return (
    <section className="panel full-panel account-panel policy-panel">
      <button className="account-back" onClick={onBack}>← Settings</button>
      <span className="eyebrow">{page.eyebrow}</span>
      <h2>{page.title}</h2>
      <p className="policy-intro">{page.intro}</p>
      <div className="policy-sections">
        {page.sections.map(([title, copy]) => (
          <article key={title}><strong>{title}</strong><p>{copy}</p></article>
        ))}
      </div>
      <div className="policy-beta-note">Beta draft · final legal review and production policies are required before a monetary or broad public launch.</div>
    </section>
  )
}

function SettingsDetail({ type, email, onBack }) {
  const content = {
    account: {
      eyebrow: 'ACCOUNT',
      title: 'Account details',
      body: 'Your Fameverse beta account is active and connected to the Fameverse backend.',
      rows: [['Email', email], ['Account status', 'Active beta account'], ['Password & security', 'Security controls expand before public testing']],
    },
    privacyControls: {
      eyebrow: 'PRIVACY',
      title: 'Privacy controls',
      body: 'These controls are intentionally limited during the private beta. The production privacy center will add audience, discoverability, blocking, and data controls.',
      rows: [['Profile visibility', 'Private beta default'], ['Live visibility', 'Local preview only'], ['Direct messages', 'Not enabled']],
    },
    notifications: {
      eyebrow: 'NOTIFICATIONS',
      title: 'Notifications',
      body: 'Push notifications are not enabled in this beta yet. We will add granular creator, live, follow, gift, and safety notification controls.',
      rows: [['Live alerts', 'Coming soon'], ['Creator activity', 'Coming soon'], ['Safety notices', 'Coming soon']],
    },
  }[type]

  return (
    <section className="panel full-panel account-panel">
      <button className="account-back" onClick={onBack}>← Settings</button>
      <span className="eyebrow">{content.eyebrow}</span>
      <h2>{content.title}</h2>
      <p className="settings-detail-copy">{content.body}</p>
      <div className="settings-list">
        {content.rows.map(([label, value]) => <div key={label}><span>{label}</span><strong>{value}</strong></div>)}
      </div>
    </section>
  )
}

export default function App() {
  const [authReady, setAuthReady] = useState(false)
  const [session, setSession] = useState(null)
  const [profile, setProfile] = useState(null)
  const [profileBusy, setProfileBusy] = useState(false)
  const [authMode, setAuthMode] = useState('signin')
  const [authForm, setAuthForm] = useState({ email: '', password: '', displayName: '' })
  const [authMessage, setAuthMessage] = useState('')
  const [tab, setTab] = useState('live')
  const [profileMode, setProfileMode] = useState('view')
  const [policyPage, setPolicyPage] = useState(null)
  const [settingsDetail, setSettingsDetail] = useState(null)
  const [creatorTab, setCreatorTab] = useState('clips')
  const [isLive, setIsLive] = useState(false)
  const [isStartingLive, setIsStartingLive] = useState(false)
  const [coins, setCoins] = useState(loadCoins)
  const [chat, setChat] = useState([])
  const [commentText, setCommentText] = useState('')
  const [toast, setToast] = useState('')
  const [installPrompt, setInstallPrompt] = useState(null)
  const [giftOverlay, setGiftOverlay] = useState(null)
  const [mediaStream, setMediaStream] = useState(null)
  const [micMuted, setMicMuted] = useState(false)
  const [cameraOff, setCameraOff] = useState(false)
  const [facingMode, setFacingMode] = useState('user')
  const [standalone, setStandalone] = useState(isRunningStandalone)
  const [giftTrayOpen, setGiftTrayOpen] = useState(false)
  const [cohostTrayOpen, setCohostTrayOpen] = useState(false)
  const [profileDraft, setProfileDraft] = useState({ display_name: '', username: '', bio: '' })

  const giftTimerRef = useRef(null)
  const videoRef = useRef(null)
  const streamRef = useRef(null)
  const wakeLockRef = useRef(null)
  const coinsRef = useRef(coins)

  const viewerCount = useMemo(() => 0, [])
  const displayName = profile?.display_name || session?.user?.email?.split('@')[0] || 'Fameverse User'
  const username = profile?.username ? `@${profile.username}` : '@newuser'
  const initial = displayName.trim().charAt(0).toUpperCase() || 'F'
  const joinedLabel = profile?.created_at
    ? new Intl.DateTimeFormat('en-US', { month: 'short', year: 'numeric' }).format(new Date(profile.created_at))
    : 'Beta 2026'

  useEffect(() => {
    let mounted = true
    supabase.auth.getSession().then(({ data }) => {
      if (!mounted) return
      setSession(data.session)
      setAuthReady(true)
    }).catch(() => setAuthReady(true))

    const { data: authListener } = supabase.auth.onAuthStateChange((_event, nextSession) => {
      setSession(nextSession)
      setAuthReady(true)
    })

    return () => {
      mounted = false
      authListener.subscription.unsubscribe()
    }
  }, [])

  useEffect(() => {
    if (!session?.user?.id) {
      setProfile(null)
      return
    }

    let active = true
    const loadProfile = async () => {
      const { data, error } = await supabase
        .from('profiles')
        .select('id, username, display_name, bio, avatar_url, created_at, updated_at')
        .eq('id', session.user.id)
        .single()

      if (!active) return
      if (error) {
        setToast('Signed in · profile is still initializing')
        return
      }

      setProfile(data)
      setProfileDraft({
        display_name: data.display_name || '',
        username: data.username || '',
        bio: data.bio || '',
      })
    }

    loadProfile()
    return () => { active = false }
  }, [session?.user?.id])

  useEffect(() => {
    coinsRef.current = coins
    localStorage.setItem('fameverse-owner-test-coins', String(coins))
  }, [coins])

  useEffect(() => {
    const handler = (event) => {
      event.preventDefault()
      setInstallPrompt(event)
    }
    const displayMode = window.matchMedia?.('(display-mode: standalone)')
    const updateStandalone = () => setStandalone(isRunningStandalone())
    window.addEventListener('beforeinstallprompt', handler)
    displayMode?.addEventListener?.('change', updateStandalone)
    return () => {
      window.removeEventListener('beforeinstallprompt', handler)
      displayMode?.removeEventListener?.('change', updateStandalone)
    }
  }, [])

  useEffect(() => {
    if (!toast) return
    const timer = setTimeout(() => setToast(''), 2400)
    return () => clearTimeout(timer)
  }, [toast])

  useEffect(() => {
    if (!videoRef.current || !mediaStream || cameraOff) return
    videoRef.current.muted = true
    videoRef.current.defaultMuted = true
    videoRef.current.volume = 0
    videoRef.current.srcObject = mediaStream
    videoRef.current.play().catch(() => {})
  }, [mediaStream, tab, cameraOff, facingMode])

  useEffect(() => () => {
    clearTimeout(giftTimerRef.current)
    streamRef.current?.getTracks().forEach((track) => track.stop())
    wakeLockRef.current?.release?.().catch?.(() => {})
  }, [])

  useEffect(() => {
    setGiftTrayOpen(false)
    setCohostTrayOpen(false)
    if (tab !== 'profile') {
      setProfileMode('view')
      setPolicyPage(null)
      setSettingsDetail(null)
    }
  }, [tab])

  useEffect(() => {
    const reacquire = () => {
      if (document.visibilityState === 'visible' && isLive) acquireWakeLock()
    }
    document.addEventListener('visibilitychange', reacquire)
    return () => document.removeEventListener('visibilitychange', reacquire)
  }, [isLive])

  const submitAuth = async (event) => {
    event.preventDefault()
    setAuthMessage('')
    if (!authForm.email || !authForm.password) {
      setAuthMessage('Email and password are required.')
      return
    }

    if (authMode === 'signup') {
      const { data, error } = await supabase.auth.signUp({
        email: authForm.email.trim(),
        password: authForm.password,
        options: { data: { display_name: authForm.displayName.trim() || 'Fameverse User' } },
      })
      if (error) {
        setAuthMessage(error.message)
        return
      }
      setAuthMessage(data.session ? 'Account created.' : 'Account created. Sign in to continue.')
      return
    }

    const { error } = await supabase.auth.signInWithPassword({
      email: authForm.email.trim(),
      password: authForm.password,
    })
    if (error) setAuthMessage(error.message)
  }

  const saveProfile = async (event) => {
    event.preventDefault()
    if (!session?.user?.id) return

    const nextUsername = cleanUsername(profileDraft.username)
    if (profileDraft.username && nextUsername.length < 3) {
      setToast('Username must be at least 3 characters')
      return
    }

    setProfileBusy(true)
    const { data, error } = await supabase
      .from('profiles')
      .update({
        display_name: profileDraft.display_name.trim() || 'Fameverse User',
        username: nextUsername || null,
        bio: profileDraft.bio.trim().slice(0, 160),
      })
      .eq('id', session.user.id)
      .select('id, username, display_name, bio, avatar_url, created_at, updated_at')
      .single()
    setProfileBusy(false)

    if (error) {
      setToast(error.code === '23505' ? 'That username is already taken' : 'Could not save profile')
      return
    }

    setProfile(data)
    setProfileDraft({ display_name: data.display_name || '', username: data.username || '', bio: data.bio || '' })
    setProfileMode('view')
    setToast('Profile saved')
  }

  const acquireWakeLock = async () => {
    if (!navigator.wakeLock?.request || document.visibilityState !== 'visible' || !isLive) return
    if (wakeLockRef.current && !wakeLockRef.current.released) return
    try {
      wakeLockRef.current = await navigator.wakeLock.request('screen')
      wakeLockRef.current.addEventListener?.('release', () => { wakeLockRef.current = null })
    } catch {
      // Best effort only. iOS can reject Wake Lock after backgrounding.
    }
  }

  const releaseWakeLock = async () => {
    const lock = wakeLockRef.current
    wakeLockRef.current = null
    if (!lock || lock.released) return
    try { await lock.release() } catch {}
  }

  const stopMedia = () => {
    streamRef.current?.getTracks().forEach((track) => track.stop())
    streamRef.current = null
    setMediaStream(null)
    setCameraOff(false)
    if (videoRef.current) videoRef.current.srcObject = null
    releaseWakeLock()
  }

  const signOut = async () => {
    stopMedia()
    setIsLive(false)
    await supabase.auth.signOut()
    setTab('live')
    setProfileMode('view')
    setPolicyPage(null)
    setSettingsDetail(null)
  }

  const videoConstraints = (nextFacing = facingMode) => ({
    facingMode: { ideal: nextFacing },
    width: { ideal: 1280 },
    height: { ideal: 720 },
  })

  const requestMedia = async (nextFacing = facingMode) => {
    if (!navigator.mediaDevices?.getUserMedia) throw new Error('unsupported')
    return navigator.mediaDevices.getUserMedia({
      video: videoConstraints(nextFacing),
      audio: { echoCancellation: true, noiseSuppression: true, autoGainControl: true },
    })
  }

  const requestVideo = async (nextFacing = facingMode) => {
    if (!navigator.mediaDevices?.getUserMedia) throw new Error('unsupported')
    return navigator.mediaDevices.getUserMedia({ video: videoConstraints(nextFacing), audio: false })
  }

  const startLive = async () => {
    if (isLive) {
      stopMedia()
      setIsLive(false)
      setMicMuted(false)
      setCameraOff(false)
      setGiftTrayOpen(false)
      setCohostTrayOpen(false)
      setToast('Live ended · camera and mic released')
      return
    }

    setIsStartingLive(true)
    try {
      const stream = await requestMedia(facingMode)
      streamRef.current = stream
      setMediaStream(stream)
      setMicMuted(false)
      setCameraOff(false)
      setIsLive(true)
      setTimeout(() => acquireWakeLock(), 0)
      setToast('Camera + microphone ready')
    } catch (error) {
      const denied = error?.name === 'NotAllowedError' || error?.name === 'PermissionDeniedError'
      const unavailable = error?.name === 'NotFoundError' || error?.name === 'DevicesNotFoundError'
      if (denied) setToast('Allow Camera + Microphone for Fameverse in iPhone settings')
      else if (unavailable) setToast('No camera or microphone was found')
      else if (error?.message === 'unsupported') setToast('This browser does not support live camera access')
      else setToast('Could not start camera · try reopening the PWA')
    } finally {
      setIsStartingLive(false)
    }
  }

  const toggleMic = () => {
    const audioTracks = streamRef.current?.getAudioTracks() || []
    if (!audioTracks.length) return
    const nextMuted = !micMuted
    audioTracks.forEach((track) => { track.enabled = !nextMuted })
    setMicMuted(nextMuted)
  }

  const toggleCamera = () => {
    const videoTracks = streamRef.current?.getVideoTracks() || []
    if (!videoTracks.length) return
    const nextOff = !cameraOff
    videoTracks.forEach((track) => { track.enabled = !nextOff })
    setCameraOff(nextOff)
  }

  const flipCamera = async () => {
    if (!isLive || cameraOff || isStartingLive) return

    const currentStream = streamRef.current
    if (!currentStream) return

    const previousFacing = facingMode
    const nextFacing = previousFacing === 'user' ? 'environment' : 'user'
    const audioTracks = currentStream.getAudioTracks()
    const oldVideoTracks = currentStream.getVideoTracks()

    setIsStartingLive(true)
    oldVideoTracks.forEach((track) => {
      try { currentStream.removeTrack(track) } catch {}
      try { track.stop() } catch {}
    })

    try {
      const cameraStream = await requestVideo(nextFacing)
      const nextVideoTrack = cameraStream.getVideoTracks()[0]
      if (!nextVideoTrack) throw new Error('camera-track-missing')

      const nextStream = new MediaStream([...audioTracks, nextVideoTrack])
      streamRef.current = nextStream
      setFacingMode(nextFacing)
      setMediaStream(nextStream)
    } catch {
      try {
        const restoreStream = await requestVideo(previousFacing)
        const restoredVideoTrack = restoreStream.getVideoTracks()[0]
        if (restoredVideoTrack) {
          const restoredStream = new MediaStream([...audioTracks, restoredVideoTrack])
          streamRef.current = restoredStream
          setMediaStream(restoredStream)
        } else {
          setCameraOff(true)
        }
      } catch {
        setCameraOff(true)
      }
      setToast('Could not switch cameras')
    } finally {
      setIsStartingLive(false)
    }
  }

  const addTestCoins = (amount = 10000) => {
    const next = coinsRef.current + amount
    coinsRef.current = next
    setCoins(next)
    setToast(`+${amount.toLocaleString()} beta test coins`)
  }

  const showGift = (gift) => {
    clearTimeout(giftTimerRef.current)
    const now = Date.now()
    setGiftOverlay((previous) => {
      const sameCombo = previous?.id === gift.id && now - (previous.lastSentAt || 0) < 2200
      return {
        ...gift,
        sender: displayName,
        duration: 1800,
        count: sameCombo ? (previous.count || 1) + 1 : 1,
        lastSentAt: now,
      }
    })
    giftTimerRef.current = setTimeout(() => setGiftOverlay(null), 1800)
  }

  const sendGift = (gift) => {
    if (coinsRef.current < gift.cost) {
      setToast('Test balance empty · tap refill')
      return
    }

    const nextBalance = coinsRef.current - gift.cost
    coinsRef.current = nextBalance
    setCoins(nextBalance)
    setChat((items) => [...items, { id: `${Date.now()}-${Math.random()}`, user: displayName, text: `${gift.emoji} sent ${gift.label}` }])
    showGift(gift)
  }

  const submitComment = (event) => {
    event.preventDefault()
    const text = commentText.trim()
    if (!text) return
    setChat((items) => [...items, { id: Date.now(), user: displayName, text }])
    setCommentText('')
  }

  const shareRoom = async () => {
    const shareData = {
      title: 'Fameverse Live Beta',
      text: `${displayName} is testing Fameverse Live.`,
      url: window.location.href,
    }
    try {
      if (navigator.share) await navigator.share(shareData)
      else {
        await navigator.clipboard.writeText(window.location.href)
        setToast('Beta link copied')
      }
    } catch {
      // User cancelled share sheet.
    }
  }

  const installPwa = async () => {
    if (!installPrompt) {
      setToast('Use Safari Share → Add to Home Screen on iPhone')
      return
    }
    await installPrompt.prompt()
    await installPrompt.userChoice
    setInstallPrompt(null)
  }

  const openProfileMode = (mode) => {
    setPolicyPage(null)
    setSettingsDetail(null)
    setProfileMode(mode)
  }

  if (!authReady) {
    return <div className="foundation-loading"><strong>FAMEVERSE <span>LIVE</span></strong><small>Opening your account…</small></div>
  }

  if (!session) {
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
              <label>Display name<input value={authForm.displayName} onChange={(event) => setAuthForm({ ...authForm, displayName: event.target.value })} maxLength={40} placeholder="Your name" /></label>
            )}
            <label>Email<input type="email" autoComplete="email" value={authForm.email} onChange={(event) => setAuthForm({ ...authForm, email: event.target.value })} placeholder="you@example.com" /></label>
            <label>Password<input type="password" autoComplete={authMode === 'signup' ? 'new-password' : 'current-password'} value={authForm.password} onChange={(event) => setAuthForm({ ...authForm, password: event.target.value })} minLength={6} placeholder="6+ characters" /></label>
            {authMessage && <div className="auth-message">{authMessage}</div>}
            <button className="auth-primary" type="submit">{authMode === 'signup' ? 'Create account' : 'Sign in'}</button>
          </form>
          <button className="auth-switch" onClick={() => { setAuthMode(authMode === 'signup' ? 'signin' : 'signup'); setAuthMessage('') }}>
            {authMode === 'signup' ? 'Already have an account? Sign in' : 'New to Fameverse? Create account'}
          </button>
        </section>
      </div>
    )
  }

  const liveMessages = chat.slice(-5)
  const [creatorSectionTitle, creatorSectionCopy] = creatorContent[creatorTab]

  return (
    <div className={`app-shell ${tab === 'live' ? 'live-app-shell' : ''}`}>
      {toast && <div className="toast">{toast}</div>}

      {giftOverlay && (
        <div className="gift-overlay-simple" role="status" aria-live="polite">
          <span className="gift-overlay-emoji">{giftOverlay.emoji}</span>
          <div>
            <strong>{giftOverlay.sender}</strong>
            <small>sent {giftOverlay.label}{giftOverlay.count > 1 ? ` ×${giftOverlay.count}` : ''}</small>
          </div>
        </div>
      )}

      {tab !== 'live' && (
        <header className="topbar">
          <div><div className="beta-chip">BETA 0.2</div><h1>FAMEVERSE <span>LIVE</span></h1></div>
          {!standalone && <button className="install-btn" onClick={installPwa}>Install PWA</button>}
        </header>
      )}

      <main>
        {tab === 'live' && (
          <section className={`mobile-live-shell ${isLive ? 'is-live' : 'is-preview'}`}>
            <div className="live-video-surface">
              {isLive && mediaStream && !cameraOff ? (
                <video ref={videoRef} className={`host-video immersive-video ${facingMode === 'user' ? 'mirror' : ''}`} autoPlay muted playsInline />
              ) : isLive && cameraOff ? (
                <div className="camera-off-placeholder">
                  <div className="preview-camera-icon">◉</div>
                  <strong>Camera off</strong>
                  <small>Your microphone can stay on while video is hidden.</small>
                </div>
              ) : (
                <div className="live-preview-placeholder">
                  <div className="preview-brand"><span>FAMEVERSE</span> LIVE</div>
                  <div className="preview-camera-icon">◉</div>
                  <strong>Ready to go live?</strong>
                  <small>Camera + microphone stay on this device during the current beta.</small>
                </div>
              )}
              <div className="live-vignette" />
            </div>

            <div className="live-floating-top">
              <div className="live-host-chip">
                <div className="avatar owner live-avatar">{initial}</div>
                <div><strong>{displayName}</strong><small>{username}</small></div>
              </div>
              <div className="live-status-cluster">
                {isLive ? (
                  <>
                    <span className="viewer-chip">👁 {viewerCount}</span>
                    <button className="top-end-live" onClick={startLive}>End</button>
                  </>
                ) : (
                  <><span className="live-pill">READY</span><span className="viewer-chip">👁 {viewerCount}</span></>
                )}
              </div>
            </div>

            {isLive && (
              <div className="live-action-rail">
                <button className="live-action" onClick={() => setGiftTrayOpen(true)}><span>🎁</span><small>Gift</small></button>
                <button className="live-action" onClick={() => setCohostTrayOpen(true)}><span>＋</span><small>Co-host</small></button>
                <button className="live-action" onClick={toggleMic}><span>{micMuted ? '🔇' : '🎙️'}</span><small>{micMuted ? 'Unmute' : 'Mute'}</small></button>
                <button className="live-action" onClick={toggleCamera}><span>{cameraOff ? '🚫' : '📷'}</span><small>{cameraOff ? 'Cam on' : 'Camera'}</small></button>
                <button className="live-action" onClick={flipCamera} disabled={isStartingLive || cameraOff}><span>↻</span><small>Flip</small></button>
                <button className="live-action" onClick={shareRoom}><span>↗</span><small>Share</small></button>
              </div>
            )}

            {isLive && liveMessages.length > 0 && (
              <div className="live-chat-overlay" aria-label="Live comments">
                {liveMessages.map((item) => <div className="live-chat-line" key={item.id}><strong>{item.user}</strong><span>{item.text}</span></div>)}
              </div>
            )}

            {!isLive ? (
              <div className="live-launch-controls">
                <button className="go-live-main" onClick={startLive} disabled={isStartingLive}>{isStartingLive ? 'Starting…' : 'Go Live'}</button>
                <button className="preview-tool" onClick={flipCamera}>↻ Camera</button>
                <button className="preview-tool" onClick={() => setGiftTrayOpen(true)}>🎁 Test Gifts</button>
              </div>
            ) : (
              <form className="live-comment-composer" onSubmit={submitComment}>
                <input value={commentText} onChange={(event) => setCommentText(event.target.value)} maxLength={160} placeholder="Add comment…" aria-label="Add comment" />
                <button type="submit" aria-label="Send comment" disabled={!commentText.trim()}>↑</button>
              </form>
            )}

            {giftTrayOpen && (
              <div className="live-sheet-backdrop" onClick={() => setGiftTrayOpen(false)}>
                <div className="live-sheet gift-test-sheet" onClick={(event) => event.stopPropagation()}>
                  <div className="sheet-handle" />
                  <div className="sheet-heading"><div><span>GIFTS · BETA TEST</span><strong>Send gifts</strong></div><div className="test-balance">🪙 {coins.toLocaleString()}</div></div>
                  <p>Tap repeatedly to send combos. Test currency only · no real purchase, earnings, or payout.</p>
                  <div className="live-gift-grid">
                    {gifts.map((gift) => (
                      <button className="live-gift-item" key={gift.id} onClick={() => sendGift(gift)}>
                        <span>{gift.emoji}</span><strong>{gift.label}</strong><small>{gift.cost} {gift.cost === 1 ? 'coin' : 'coins'}</small>
                      </button>
                    ))}
                  </div>
                  <div className="test-wallet-row"><small>Beta tester balance</small><button onClick={() => addTestCoins(10000)}>+10K test coins</button></div>
                </div>
              </div>
            )}

            {cohostTrayOpen && (
              <div className="live-sheet-backdrop" onClick={() => setCohostTrayOpen(false)}>
                <div className="live-sheet" onClick={(event) => event.stopPropagation()}>
                  <div className="sheet-handle" />
                  <div className="sheet-heading"><div><span>CO-HOST</span><strong>No requests yet</strong></div></div>
                  <p>Realtime co-host requests and remote video are still being connected. No fake users are shown.</p>
                  <button className="sheet-primary-action" onClick={shareRoom}>Share live link</button>
                </div>
              </div>
            )}
          </section>
        )}

        {tab === 'discover' && (
          <section className="panel full-panel discover-empty-panel">
            <span className="eyebrow">DISCOVER</span>
            <h2>Live creators</h2>
            <div className="honest-empty-state">
              <div>✦</div><strong>No public live rooms yet</strong><p>Real creators will appear here when realtime rooms and the Fameverse FYP are connected.</p>
            </div>
          </section>
        )}

        {tab === 'profile' && profileMode === 'view' && (
          <section className="panel full-panel profile-panel refined-profile">
            <div className="profile-toolbar">
              <span className="profile-brand">FAMEVERSE</span>
              <button aria-label="Settings" onClick={() => openProfileMode('settings')}>⚙</button>
            </div>

            <div className="profile-cover">
              <div className="avatar profile-avatar refined-avatar">{initial}</div>
            </div>

            <div className="profile-identity">
              <span className="creator-badge">BETA CREATOR</span>
              <h2>{displayName}</h2>
              <p>{username}</p>
              <p className="profile-bio">{profile?.bio || 'Add a bio so viewers know who you are.'}</p>
              <div className="profile-meta"><span>Joined {joinedLabel}</span><span>Live creator</span></div>
            </div>

            <div className="profile-stats refined-stats">
              <div><strong>0</strong><small>Followers</small></div>
              <div><strong>0</strong><small>Following</small></div>
              <div><strong>0</strong><small>Likes</small></div>
            </div>

            <div className="profile-actions refined-actions">
              <button className="primary-profile-action" onClick={() => openProfileMode('edit')}>Edit profile</button>
              <button onClick={shareRoom}>Share profile</button>
            </div>

            <button className="creator-hub-card creator-hub-button" onClick={() => openProfileMode('studio')}>
              <div><span>CREATOR HUB</span><strong>Creator Studio</strong><small>Manage your live setup, creator tools and beta status.</small></div>
              <b>→</b>
            </button>

            <div className="profile-content-tabs" role="tablist" aria-label="Creator content">
              {Object.keys(creatorContent).map((key) => (
                <button key={key} className={creatorTab === key ? 'active' : ''} onClick={() => setCreatorTab(key)}>{creatorContent[key][0]}</button>
              ))}
            </div>

            <div className="profile-empty-content">
              <span>{creatorTab === 'gifts' ? '🎁' : creatorTab === 'replays' ? '↻' : '✦'}</span>
              <strong>{creatorSectionTitle}</strong>
              <p>{creatorSectionCopy}</p>
            </div>

            <div className="compact-beta-note">Beta: test coins remain local and are not displayed as public creator earnings.</div>
          </section>
        )}

        {tab === 'profile' && profileMode === 'studio' && (
          <section className="panel full-panel account-panel creator-studio-page">
            <button className="account-back" onClick={() => openProfileMode('view')}>← Profile</button>
            <span className="eyebrow">CREATOR STUDIO · BETA</span>
            <h2>Creator Studio</h2>
            <p className="studio-intro">Your creator workspace stays inside Profile. Nothing here should throw you back into Live unless you choose to open the live setup.</p>

            <div className="studio-grid">
              <button onClick={() => setTab('live')}><span>●</span><strong>Open live setup</strong><small>Camera, microphone, gifts and live controls</small></button>
              <button onClick={() => { setCreatorTab('clips'); setProfileMode('view') }}><span>✦</span><strong>Clips</strong><small>Creator clips are being connected</small></button>
              <button onClick={() => { setCreatorTab('replays'); setProfileMode('view') }}><span>↻</span><strong>Replays</strong><small>Replay library arrives with real rooms</small></button>
              <button onClick={() => { setCreatorTab('gifts'); setProfileMode('view') }}><span>🎁</span><strong>Gift activity</strong><small>Test gifts now, production wallet later</small></button>
            </div>

            <div className="settings-info-card">
              <b>Creator status</b>
              <p>Account and profile are real backend data. Remote broadcasting, creator earnings, payouts, analytics and moderation dashboards are still under construction.</p>
            </div>
          </section>
        )}

        {tab === 'profile' && profileMode === 'edit' && (
          <section className="panel full-panel account-panel">
            <button className="account-back" onClick={() => openProfileMode('view')}>← Profile</button>
            <span className="eyebrow">EDIT PROFILE</span><h2>Make it yours</h2>
            <form className="profile-edit-form" onSubmit={saveProfile}>
              <label>Display name<input value={profileDraft.display_name} onChange={(event) => setProfileDraft({ ...profileDraft, display_name: event.target.value })} maxLength={40} /></label>
              <label>Username<div className="username-field"><span>@</span><input value={profileDraft.username} onChange={(event) => setProfileDraft({ ...profileDraft, username: cleanUsername(event.target.value) })} maxLength={24} placeholder="username" /></div></label>
              <label>Bio<textarea value={profileDraft.bio} onChange={(event) => setProfileDraft({ ...profileDraft, bio: event.target.value })} maxLength={160} rows={4} placeholder="Tell people about you" /></label>
              <button className="auth-primary" type="submit" disabled={profileBusy}>{profileBusy ? 'Saving…' : 'Save profile'}</button>
            </form>
          </section>
        )}

        {tab === 'profile' && profileMode === 'settings' && !policyPage && !settingsDetail && (
          <section className="panel full-panel account-panel settings-home">
            <button className="account-back" onClick={() => openProfileMode('view')}>← Profile</button>
            <span className="eyebrow">SETTINGS & SAFETY</span><h2>Settings</h2>

            <div className="settings-section">
              <strong className="settings-section-title">Account</strong>
              <button className="settings-row" onClick={() => setSettingsDetail('account')}><span><b>Account details</b><small>{session.user.email}</small></span><i>›</i></button>
              <button className="settings-row" onClick={() => openProfileMode('edit')}><span><b>Edit profile</b><small>Name, username and bio</small></span><i>›</i></button>
              <button className="settings-row" onClick={() => setSettingsDetail('privacyControls')}><span><b>Privacy</b><small>Beta privacy controls and status</small></span><i>›</i></button>
              <button className="settings-row" onClick={() => setSettingsDetail('notifications')}><span><b>Notifications</b><small>Live and creator alert status</small></span><i>›</i></button>
            </div>

            <div className="settings-section">
              <strong className="settings-section-title">Rules & legal</strong>
              <button className="settings-row" onClick={() => setPolicyPage('terms')}><span><b>Terms of Service</b><small>Platform and account rules</small></span><i>›</i></button>
              <button className="settings-row" onClick={() => setPolicyPage('privacy')}><span><b>Privacy Policy</b><small>What the beta stores and uses</small></span><i>›</i></button>
              <button className="settings-row" onClick={() => setPolicyPage('use')}><span><b>Terms of Use</b><small>Responsible platform use</small></span><i>›</i></button>
              <button className="settings-row" onClick={() => setPolicyPage('community')}><span><b>Community Guidelines</b><small>What Fameverse will and will not tolerate</small></span><i>›</i></button>
            </div>

            <div className="settings-section">
              <strong className="settings-section-title">Beta</strong>
              <div className="settings-info-card"><b>Current testing boundary</b><p>Accounts and profiles use the Fameverse backend. Camera preview, comments and gifts are still test systems while realtime rooms, moderation and creator money systems are built.</p></div>
            </div>

            <button className="signout-button" onClick={signOut}>Sign out</button>
          </section>
        )}

        {tab === 'profile' && profileMode === 'settings' && policyPage && (
          <LegalPage page={legalPages[policyPage]} onBack={() => setPolicyPage(null)} />
        )}

        {tab === 'profile' && profileMode === 'settings' && settingsDetail && (
          <SettingsDetail type={settingsDetail} email={session.user.email} onBack={() => setSettingsDetail(null)} />
        )}
      </main>

      <nav className={`bottom-nav ${tab === 'live' && isLive ? 'nav-hidden-live' : ''}`} aria-label="Primary">
        <button className={tab === 'discover' ? 'active' : ''} onClick={() => setTab('discover')}><span>✦</span>Discover</button>
        <button className={tab === 'live' ? 'active center' : 'center'} onClick={() => setTab('live')}><span>●</span>Live</button>
        <button className={tab === 'profile' ? 'active' : ''} onClick={() => setTab('profile')}><span>♙</span>Profile</button>
      </nav>
    </div>
  )
}

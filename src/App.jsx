import { useEffect, useMemo, useRef, useState } from 'react'
import { supabase } from './supabase.js'

const gifts = [
  { id: 'rose', emoji: '🌹', label: 'Rose', cost: 1 },
  { id: 'heart', emoji: '💜', label: 'Heart', cost: 5 },
  { id: 'fire', emoji: '🔥', label: 'Fire', cost: 10 },
  { id: 'star', emoji: '⭐', label: 'Star', cost: 20 },
  { id: 'crown', emoji: '👑', label: 'Crown', cost: 50 },
  { id: 'dragon', emoji: '🐉', label: 'Dragon', cost: 100, premium: true },
]

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
  const [facingMode, setFacingMode] = useState('user')
  const [standalone, setStandalone] = useState(isRunningStandalone)
  const [giftTrayOpen, setGiftTrayOpen] = useState(false)
  const [cohostTrayOpen, setCohostTrayOpen] = useState(false)
  const [commentTrayOpen, setCommentTrayOpen] = useState(false)
  const [profileDraft, setProfileDraft] = useState({ display_name: '', username: '', bio: '' })

  const giftTimerRef = useRef(null)
  const videoRef = useRef(null)
  const streamRef = useRef(null)

  const viewerCount = useMemo(() => 0, [])
  const displayName = profile?.display_name || session?.user?.email?.split('@')[0] || 'Fameverse User'
  const username = profile?.username ? `@${profile.username}` : '@newuser'
  const initial = displayName.trim().charAt(0).toUpperCase() || 'F'

  useEffect(() => {
    let mounted = true

    supabase.auth.getSession().then(({ data }) => {
      if (!mounted) return
      setSession(data.session)
      setAuthReady(true)
    })

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
    if (!videoRef.current || !mediaStream) return
    videoRef.current.srcObject = mediaStream
    videoRef.current.play().catch(() => {})
  }, [mediaStream, tab])

  useEffect(() => () => {
    clearTimeout(giftTimerRef.current)
    streamRef.current?.getTracks().forEach((track) => track.stop())
  }, [])

  useEffect(() => {
    setGiftTrayOpen(false)
    setCohostTrayOpen(false)
    setCommentTrayOpen(false)
    if (tab !== 'profile') setProfileMode('view')
  }, [tab])

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

      if (!data.session) setAuthMessage('Account created. Check your email to confirm, then sign in.')
      else setAuthMessage('Account created.')
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

  const signOut = async () => {
    stopMedia()
    setIsLive(false)
    await supabase.auth.signOut()
    setTab('live')
    setProfileMode('view')
  }

  const stopMedia = () => {
    streamRef.current?.getTracks().forEach((track) => track.stop())
    streamRef.current = null
    setMediaStream(null)
    if (videoRef.current) videoRef.current.srcObject = null
  }

  const requestMedia = async (nextFacing = facingMode) => {
    if (!navigator.mediaDevices?.getUserMedia) throw new Error('unsupported')

    return navigator.mediaDevices.getUserMedia({
      video: {
        facingMode: { ideal: nextFacing },
        width: { ideal: 1280 },
        height: { ideal: 720 },
      },
      audio: {
        echoCancellation: true,
        noiseSuppression: true,
        autoGainControl: true,
      },
    })
  }

  const startLive = async () => {
    if (isLive) {
      stopMedia()
      setIsLive(false)
      setMicMuted(false)
      setGiftTrayOpen(false)
      setCohostTrayOpen(false)
      setCommentTrayOpen(false)
      setToast('Live ended · camera and mic released')
      return
    }

    setIsStartingLive(true)
    try {
      const stream = await requestMedia(facingMode)
      streamRef.current = stream
      setMediaStream(stream)
      setMicMuted(false)
      setIsLive(true)
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
    setToast(nextMuted ? 'Microphone muted' : 'Microphone on')
  }

  const flipCamera = async () => {
    const previousFacing = facingMode
    const nextFacing = facingMode === 'user' ? 'environment' : 'user'
    setFacingMode(nextFacing)
    if (!isLive) return

    setIsStartingLive(true)
    try {
      const nextStream = await requestMedia(nextFacing)
      nextStream.getAudioTracks().forEach((track) => { track.enabled = !micMuted })
      stopMedia()
      streamRef.current = nextStream
      setMediaStream(nextStream)
      setToast(nextFacing === 'user' ? 'Front camera' : 'Back camera')
    } catch {
      setFacingMode(previousFacing)
      setToast('Could not switch cameras')
    } finally {
      setIsStartingLive(false)
    }
  }

  const addTestCoins = (amount = 10000) => {
    setCoins((value) => value + amount)
    setToast(`+${amount.toLocaleString()} beta test coins`)
  }

  const showGift = (gift) => {
    clearTimeout(giftTimerRef.current)
    const duration = gift.cost === 100 ? 6000 : 1800
    setGiftOverlay({ ...gift, sender: displayName, duration })
    giftTimerRef.current = setTimeout(() => setGiftOverlay(null), duration)
  }

  const sendGift = (gift) => {
    if (coins < gift.cost) {
      setToast('Test balance empty · tap refill')
      return
    }

    setCoins((value) => value - gift.cost)
    setChat((items) => [...items, { id: Date.now(), user: displayName, text: `${gift.emoji} sent ${gift.label}` }])
    setGiftTrayOpen(false)
    showGift(gift)
  }

  const submitComment = (event) => {
    event.preventDefault()
    const text = commentText.trim()
    if (!text) return
    setChat((items) => [...items, { id: Date.now(), user: displayName, text }])
    setCommentText('')
    setCommentTrayOpen(false)
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

  if (!authReady) {
    return <div className="foundation-loading"><strong>FAMEVERSE <span>LIVE</span></strong><small>Loading beta…</small></div>
  }

  if (!session) {
    return (
      <div className="auth-shell">
        <div className="auth-brand"><span>FAMEVERSE</span> LIVE <b>BETA 0.2</b></div>
        <section className="auth-card">
          <div>
            <span className="eyebrow">ACCOUNT FOUNDATION</span>
            <h1>{authMode === 'signup' ? 'Create your Fameverse account' : 'Welcome back'}</h1>
            <p>Real beta accounts are now connected to Fameverse's own backend.</p>
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

  const liveMessages = chat.slice(-4)

  return (
    <div className={`app-shell ${tab === 'live' ? 'live-app-shell' : ''}`}>
      {toast && <div className="toast">{toast}</div>}

      {giftOverlay && giftOverlay.cost < 100 && (
        <div className="gift-overlay-simple" role="status" aria-live="polite">
          <span className="gift-overlay-emoji">{giftOverlay.emoji}</span>
          <div><strong>{giftOverlay.sender}</strong><small>sent {giftOverlay.label} · {giftOverlay.cost} {giftOverlay.cost === 1 ? 'coin' : 'coins'}</small></div>
        </div>
      )}

      {giftOverlay && giftOverlay.cost === 100 && (
        <div className="gift-overlay-premium" role="status" aria-live="polite">
          <div className="premium-glow" />
          <div className="premium-gift-visual">{giftOverlay.emoji}</div>
          <div className="premium-gift-copy"><span>100 COIN GIFT</span><strong>{giftOverlay.sender}</strong><small>sent {giftOverlay.label}</small></div>
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
              {isLive && mediaStream ? (
                <video ref={videoRef} className={`host-video immersive-video ${facingMode === 'user' ? 'mirror' : ''}`} autoPlay muted playsInline />
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
                <span className={isLive ? 'live-pill active' : 'live-pill'}>{isLive ? 'LIVE' : 'READY'}</span>
                <span className="viewer-chip">👁 {viewerCount}</span>
              </div>
            </div>

            {isLive && (
              <div className="live-action-rail">
                <button className="live-action" onClick={() => setGiftTrayOpen(true)}><span>🎁</span><small>Gift</small></button>
                <button className="live-action" onClick={() => setCohostTrayOpen(true)}><span>＋</span><small>Co-host</small></button>
                <button className="live-action" onClick={() => setCommentTrayOpen(true)}><span>💬</span><small>Comment</small></button>
                <button className="live-action" onClick={toggleMic}><span>{micMuted ? '🔇' : '🎙️'}</span><small>{micMuted ? 'Unmute' : 'Mute'}</small></button>
                <button className="live-action" onClick={flipCamera} disabled={isStartingLive}><span>↻</span><small>Flip</small></button>
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
              <div className="live-end-controls"><button className="end-live-pill" onClick={startLive}>End Live</button><span>DEVICE CAMERA · BETA</span></div>
            )}

            {giftTrayOpen && (
              <div className="live-sheet-backdrop" onClick={() => setGiftTrayOpen(false)}>
                <div className="live-sheet gift-test-sheet" onClick={(event) => event.stopPropagation()}>
                  <div className="sheet-handle" />
                  <div className="sheet-heading"><div><span>TEST GIFTS</span><strong>Send a gift</strong></div><div className="test-balance">🪙 {coins.toLocaleString()}</div></div>
                  <p>Beta test currency only · no real purchase, earnings, or payout.</p>
                  <div className="live-gift-grid">
                    {gifts.map((gift) => (
                      <button className={`live-gift-item ${gift.cost === 100 ? 'premium-test-gift' : ''}`} key={gift.id} onClick={() => sendGift(gift)}>
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
                  <p>Fake co-host accounts are gone. Share this beta with a tester now; realtime co-host requests/video are the next room-backend milestone.</p>
                  <button className="sheet-primary-action" onClick={shareRoom}>Share beta link</button>
                </div>
              </div>
            )}

            {commentTrayOpen && (
              <div className="live-sheet-backdrop" onClick={() => setCommentTrayOpen(false)}>
                <form className="live-sheet comment-sheet" onSubmit={submitComment} onClick={(event) => event.stopPropagation()}>
                  <div className="sheet-handle" />
                  <div className="sheet-heading"><div><span>COMMENT TEST</span><strong>Add a comment</strong></div></div>
                  <input autoFocus value={commentText} onChange={(event) => setCommentText(event.target.value)} maxLength={160} placeholder="Say something…" />
                  <button className="sheet-primary-action" type="submit">Post comment</button>
                </form>
              </div>
            )}
          </section>
        )}

        {tab === 'discover' && (
          <section className="panel full-panel discover-empty-panel">
            <span className="eyebrow">DISCOVER</span>
            <h2>Live creators</h2>
            <div className="honest-empty-state">
              <div>✦</div><strong>No public live rooms yet</strong><p>Sample creators were removed. Real creators will appear here when realtime rooms and the FYP are connected.</p>
            </div>
          </section>
        )}

        {tab === 'profile' && profileMode === 'view' && (
          <section className="panel full-panel profile-panel">
            <div className="profile-hero">
              <div className="avatar profile-avatar">{initial}</div>
              <div><span className="eyebrow">BETA PROFILE</span><h2>{displayName}</h2><p>{username}</p></div>
            </div>
            {profile?.bio && <p className="profile-bio">{profile.bio}</p>}
            <div className="profile-stats">
              <div><strong>0</strong><small>Followers</small></div>
              <div><strong>0</strong><small>Following</small></div>
              <div><strong>{coins.toLocaleString()}</strong><small>Test coins</small></div>
            </div>
            <div className="profile-actions">
              <button onClick={() => setProfileMode('edit')}>Edit profile</button>
              <button onClick={() => setProfileMode('settings')}>Settings</button>
            </div>
            <div className="roadmap-note"><strong>Beta boundary</strong><p>Your account and profile are now real backend data. Camera preview, comments and gifts are still local test systems while realtime rooms are built.</p></div>
          </section>
        )}

        {tab === 'profile' && profileMode === 'edit' && (
          <section className="panel full-panel account-panel">
            <button className="account-back" onClick={() => setProfileMode('view')}>← Profile</button>
            <span className="eyebrow">EDIT PROFILE</span><h2>Make it yours</h2>
            <form className="profile-edit-form" onSubmit={saveProfile}>
              <label>Display name<input value={profileDraft.display_name} onChange={(event) => setProfileDraft({ ...profileDraft, display_name: event.target.value })} maxLength={40} /></label>
              <label>Username<div className="username-field"><span>@</span><input value={profileDraft.username} onChange={(event) => setProfileDraft({ ...profileDraft, username: cleanUsername(event.target.value) })} maxLength={24} placeholder="username" /></div></label>
              <label>Bio<textarea value={profileDraft.bio} onChange={(event) => setProfileDraft({ ...profileDraft, bio: event.target.value })} maxLength={160} rows={4} placeholder="Tell people about you" /></label>
              <button className="auth-primary" type="submit" disabled={profileBusy}>{profileBusy ? 'Saving…' : 'Save profile'}</button>
            </form>
          </section>
        )}

        {tab === 'profile' && profileMode === 'settings' && (
          <section className="panel full-panel account-panel">
            <button className="account-back" onClick={() => setProfileMode('view')}>← Profile</button>
            <span className="eyebrow">SETTINGS</span><h2>Account</h2>
            <div className="settings-list">
              <div><span>Email</span><strong>{session.user.email}</strong></div>
              <div><span>Privacy</span><strong>More controls tomorrow</strong></div>
              <div><span>Notifications</span><strong>Coming in account refinement</strong></div>
            </div>
            <button className="signout-button" onClick={signOut}>Sign out</button>
          </section>
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

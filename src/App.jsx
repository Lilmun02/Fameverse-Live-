import { useEffect, useMemo, useRef, useState } from 'react'

const creators = [
  { id: 1, name: 'Nova', handle: '@nova', viewers: 128, status: 'Live now' },
  { id: 2, name: 'Maya', handle: '@maya', viewers: 84, status: 'Live now' },
  { id: 3, name: 'Rico', handle: '@rico', viewers: 61, status: 'Starting soon' },
]

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
  return Number.isFinite(saved) && saved >= 0 ? saved : 5000
}

function isRunningStandalone() {
  return window.matchMedia?.('(display-mode: standalone)').matches || window.navigator.standalone === true
}

export default function App() {
  const [tab, setTab] = useState('live')
  const [isLive, setIsLive] = useState(false)
  const [isStartingLive, setIsStartingLive] = useState(false)
  const [coins, setCoins] = useState(loadCoins)
  const [cohost, setCohost] = useState(null)
  const [chat, setChat] = useState([
    { id: 1, user: 'Fameverse', text: 'Beta room ready.' },
    { id: 2, user: 'Nova', text: 'Testing the room 👀' },
  ])
  const [toast, setToast] = useState('')
  const [installPrompt, setInstallPrompt] = useState(null)
  const [giftOverlay, setGiftOverlay] = useState(null)
  const [mediaStream, setMediaStream] = useState(null)
  const [micMuted, setMicMuted] = useState(false)
  const [facingMode, setFacingMode] = useState('user')
  const [standalone, setStandalone] = useState(isRunningStandalone)
  const [giftTrayOpen, setGiftTrayOpen] = useState(false)
  const [cohostTrayOpen, setCohostTrayOpen] = useState(false)

  const giftTimerRef = useRef(null)
  const videoRef = useRef(null)
  const streamRef = useRef(null)

  const ownerMode = true // Local beta only. Replace with backend role check before production.

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
    const timer = setTimeout(() => setToast(''), 2200)
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
  }, [tab])

  const viewers = useMemo(() => 0, [])

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

  const addTestCoins = (amount) => {
    if (!ownerMode) return
    setCoins((value) => value + amount)
    setToast(`+${amount.toLocaleString()} test coins`)
  }

  const showGift = (gift) => {
    clearTimeout(giftTimerRef.current)
    const duration = gift.cost === 100 ? 6000 : 1800
    setGiftOverlay({ ...gift, sender: 'INFAMOUS', duration })
    giftTimerRef.current = setTimeout(() => setGiftOverlay(null), duration)
  }

  const sendGift = (gift) => {
    if (coins < gift.cost) {
      setToast('Not enough test coins')
      return
    }

    setCoins((value) => value - gift.cost)
    setChat((items) => [
      ...items,
      {
        id: Date.now(),
        user: 'INFAMOUS',
        text: `${gift.emoji} sent ${gift.label}`,
      },
    ])
    setGiftTrayOpen(false)
    showGift(gift)
  }

  const inviteCohost = (creator) => {
    if (!isLive) {
      setToast('Start your live before inviting a co-host')
      return
    }
    setCohost(creator)
    setCohostTrayOpen(false)
    setToast(`${creator.name} added to the beta co-host slot`)
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

  const liveMessages = chat.slice(-3)

  return (
    <div className={`app-shell ${tab === 'live' ? 'live-app-shell' : ''}`}>
      {toast && <div className="toast">{toast}</div>}

      {giftOverlay && giftOverlay.cost < 100 && (
        <div className="gift-overlay-simple" role="status" aria-live="polite">
          <span className="gift-overlay-emoji">{giftOverlay.emoji}</span>
          <div>
            <strong>{giftOverlay.sender}</strong>
            <small>sent {giftOverlay.label} · {giftOverlay.cost} {giftOverlay.cost === 1 ? 'coin' : 'coins'}</small>
          </div>
        </div>
      )}

      {giftOverlay && giftOverlay.cost === 100 && (
        <div className="gift-overlay-premium" role="status" aria-live="polite">
          <div className="premium-glow" />
          <div className="premium-gift-visual">{giftOverlay.emoji}</div>
          <div className="premium-gift-copy">
            <span>100 COIN GIFT</span>
            <strong>{giftOverlay.sender}</strong>
            <small>sent {giftOverlay.label}</small>
          </div>
        </div>
      )}

      {tab !== 'live' && (
        <header className="topbar">
          <div>
            <div className="eyebrow">BETA 0.1</div>
            <h1>FAMEVERSE <span>LIVE</span></h1>
          </div>
          {!standalone && <button className="install-btn" onClick={installPwa}>Install PWA</button>}
        </header>
      )}

      <main>
        {tab === 'live' && (
          <section className={`mobile-live-shell ${isLive ? 'is-live' : 'is-preview'}`}>
            <div className="live-video-surface">
              {isLive && mediaStream ? (
                <video
                  ref={videoRef}
                  className={`host-video immersive-video ${facingMode === 'user' ? 'mirror' : ''}`}
                  autoPlay
                  muted
                  playsInline
                />
              ) : (
                <div className="live-preview-placeholder">
                  <div className="preview-brand"><span>FAMEVERSE</span> LIVE</div>
                  <div className="preview-camera-icon">◉</div>
                  <strong>Ready to go live?</strong>
                  <small>Camera + microphone stay on this device during Beta 0.1.</small>
                </div>
              )}
              <div className="live-vignette" />
            </div>

            <div className="live-floating-top">
              <div className="live-host-chip">
                <div className="avatar owner live-avatar">I</div>
                <div>
                  <strong>INFAMOUS</strong>
                  <small>Host · Owner beta</small>
                </div>
              </div>
              <div className="live-status-cluster">
                <span className={isLive ? 'live-pill active' : 'live-pill'}>{isLive ? 'LIVE' : 'READY'}</span>
                <span className="viewer-chip">👁 {viewers}</span>
              </div>
            </div>

            {cohost && isLive && (
              <div className="cohost-floating-card">
                <div className="avatar">{cohost.name[0]}</div>
                <div><strong>{cohost.name}</strong><small>Co-host test slot</small></div>
                <button onClick={() => setCohost(null)} aria-label="Remove co-host">×</button>
              </div>
            )}

            {isLive && (
              <div className="live-action-rail">
                <button className="live-action" onClick={() => setGiftTrayOpen(true)}><span>🎁</span><small>Gift</small></button>
                <button className="live-action" onClick={() => setCohostTrayOpen(true)}><span>＋</span><small>Co-host</small></button>
                <button className="live-action" onClick={toggleMic}><span>{micMuted ? '🔇' : '🎙️'}</span><small>{micMuted ? 'Unmute' : 'Mute'}</small></button>
                <button className="live-action" onClick={flipCamera} disabled={isStartingLive}><span>↻</span><small>Flip</small></button>
              </div>
            )}

            {isLive && (
              <div className="live-chat-overlay" aria-label="Live chat preview">
                {liveMessages.map((item) => (
                  <div className="live-chat-line" key={item.id}>
                    <strong>{item.user}</strong><span>{item.text}</span>
                  </div>
                ))}
              </div>
            )}

            {!isLive ? (
              <div className="live-launch-controls">
                <button className="go-live-main" onClick={startLive} disabled={isStartingLive}>
                  {isStartingLive ? 'Starting…' : 'Go Live'}
                </button>
                <button className="preview-tool" onClick={flipCamera}>↻ Camera</button>
                <button className="preview-tool" onClick={() => setGiftTrayOpen(true)}>🎁 Test Gifts</button>
              </div>
            ) : (
              <div className="live-end-controls">
                <button className="end-live-pill" onClick={startLive}>End Live</button>
                <span>DEVICE CAMERA · BETA</span>
              </div>
            )}

            {giftTrayOpen && (
              <div className="live-sheet-backdrop" onClick={() => setGiftTrayOpen(false)}>
                <div className="live-sheet gift-test-sheet" onClick={(event) => event.stopPropagation()}>
                  <div className="sheet-handle" />
                  <div className="sheet-heading">
                    <div><span>TEST GIFTS</span><strong>Send a gift</strong></div>
                    <div className="test-balance">🪙 {coins.toLocaleString()}</div>
                  </div>
                  <p>Local beta only · no real purchase, earnings, or payout.</p>
                  <div className="live-gift-grid">
                    {gifts.map((gift) => (
                      <button className={`live-gift-item ${gift.cost === 100 ? 'premium-test-gift' : ''}`} key={gift.id} onClick={() => sendGift(gift)}>
                        <span>{gift.emoji}</span>
                        <strong>{gift.label}</strong>
                        <small>{gift.cost} {gift.cost === 1 ? 'coin' : 'coins'}</small>
                      </button>
                    ))}
                  </div>
                  <div className="test-wallet-row">
                    <small>Owner testing balance</small>
                    <button onClick={() => addTestCoins(1000)}>+1K test coins</button>
                  </div>
                </div>
              </div>
            )}

            {cohostTrayOpen && (
              <div className="live-sheet-backdrop" onClick={() => setCohostTrayOpen(false)}>
                <div className="live-sheet" onClick={(event) => event.stopPropagation()}>
                  <div className="sheet-handle" />
                  <div className="sheet-heading"><div><span>CO-HOST · BETA</span><strong>Invite a creator</strong></div></div>
                  <p>Visual test slot only until realtime remote video is connected.</p>
                  <div className="sheet-creator-list">
                    {creators.map((creator) => (
                      <button key={creator.id} className="sheet-creator" onClick={() => inviteCohost(creator)}>
                        <div className="avatar">{creator.name[0]}</div>
                        <div><strong>{creator.name}</strong><small>{creator.handle} · {creator.status}</small></div>
                        <span>{cohost?.id === creator.id ? 'Added' : 'Invite'}</span>
                      </button>
                    ))}
                  </div>
                </div>
              </div>
            )}
          </section>
        )}

        {tab === 'discover' && (
          <section className="panel full-panel">
            <span className="eyebrow">DISCOVER</span>
            <h2>Live creators</h2>
            <p className="muted">Discovery is still sample data in Beta 0.1.</p>
            <div className="discover-grid">
              {creators.map((creator) => (
                <article className="discover-card" key={creator.id}>
                  <div className="discover-preview"><div className="avatar big">{creator.name[0]}</div></div>
                  <strong>{creator.name}</strong>
                  <small>{creator.handle} · {creator.viewers} viewers</small>
                </article>
              ))}
            </div>
          </section>
        )}

        {tab === 'profile' && (
          <section className="panel full-panel profile-panel">
            <div className="profile-hero">
              <div className="avatar profile-avatar">I</div>
              <div>
                <span className="eyebrow">OWNER TEST PROFILE</span>
                <h2>INFAMOUS</h2>
                <p>@infamous · Fameverse Live beta</p>
              </div>
            </div>
            <div className="profile-stats">
              <div><strong>0</strong><small>Followers</small></div>
              <div><strong>0</strong><small>Following</small></div>
              <div><strong>{coins.toLocaleString()}</strong><small>Test coins</small></div>
            </div>
            <div className="roadmap-note">
              <strong>Beta boundary</strong>
              <p>Camera preview and gift interactions are test systems. Realtime remote broadcasting, purchases, creator earnings, payouts and production authentication are not enabled yet.</p>
            </div>
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

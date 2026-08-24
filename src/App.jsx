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

export default function App() {
  const [tab, setTab] = useState('live')
  const [isLive, setIsLive] = useState(false)
  const [coins, setCoins] = useState(loadCoins)
  const [cohost, setCohost] = useState(null)
  const [chat, setChat] = useState([
    { id: 1, user: 'Fameverse', text: 'Beta room ready. Start a live to test the host controls.' },
    { id: 2, user: 'Nova', text: 'This co-host layout is clean 👀' },
  ])
  const [toast, setToast] = useState('')
  const [installPrompt, setInstallPrompt] = useState(null)
  const [giftOverlay, setGiftOverlay] = useState(null)
  const giftTimerRef = useRef(null)

  const ownerMode = true // Local beta only. Replace with backend role check before production.

  useEffect(() => {
    localStorage.setItem('fameverse-owner-test-coins', String(coins))
  }, [coins])

  useEffect(() => {
    const handler = (event) => {
      event.preventDefault()
      setInstallPrompt(event)
    }
    window.addEventListener('beforeinstallprompt', handler)
    return () => window.removeEventListener('beforeinstallprompt', handler)
  }, [])

  useEffect(() => {
    if (!toast) return
    const t = setTimeout(() => setToast(''), 2200)
    return () => clearTimeout(t)
  }, [toast])

  useEffect(() => () => clearTimeout(giftTimerRef.current), [])

  const viewers = useMemo(() => (isLive ? 42 + (cohost ? 27 : 0) : 0), [isLive, cohost])

  const startLive = () => {
    setIsLive((value) => !value)
    setToast(isLive ? 'Live ended' : 'You are live — beta test mode')
  }

  const addTestCoins = (amount) => {
    if (!ownerMode) return
    setCoins((value) => value + amount)
    setToast(`+${amount.toLocaleString()} owner test coins`)
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
        text: `${gift.emoji} sent a ${gift.label} (${gift.cost} ${gift.cost === 1 ? 'coin' : 'coins'})`,
      },
    ])
    showGift(gift)
  }

  const inviteCohost = (creator) => {
    if (!isLive) {
      setToast('Start your live before inviting a co-host')
      return
    }
    setCohost(creator)
    setToast(`${creator.name} joined as co-host`)
  }

  const installPwa = async () => {
    if (!installPrompt) {
      setToast('Use your browser Add to Home Screen option on iPhone')
      return
    }
    await installPrompt.prompt()
    await installPrompt.userChoice
    setInstallPrompt(null)
  }

  return (
    <div className="app-shell">
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

      <header className="topbar">
        <div>
          <div className="eyebrow">BETA 0.1</div>
          <h1>FAMEVERSE <span>LIVE</span></h1>
        </div>
        <button className="install-btn" onClick={installPwa}>Install PWA</button>
      </header>

      <main>
        {tab === 'live' && (
          <>
            <section className="live-stage">
              <div className="stage-top">
                <div className="host-id">
                  <div className="avatar owner">I</div>
                  <div>
                    <strong>INFAMOUS</strong>
                    <small>Host · Owner beta</small>
                  </div>
                </div>
                <div className="live-metrics">
                  <span className={isLive ? 'live-pill active' : 'live-pill'}>{isLive ? 'LIVE' : 'OFFLINE'}</span>
                  <span>👁 {viewers}</span>
                </div>
              </div>

              <div className={`video-grid ${cohost ? 'split' : ''}`}>
                <div className="video-tile primary-tile">
                  <div className="camera-placeholder">
                    <div className="camera-ring">📷</div>
                    <strong>{isLive ? 'Camera preview' : 'Ready when you are'}</strong>
                    <small>Real video transport comes with the streaming backend phase.</small>
                  </div>
                  <div className="tile-label">HOST · INFAMOUS</div>
                </div>

                {cohost && (
                  <div className="video-tile cohost-tile">
                    <div className="camera-placeholder">
                      <div className="avatar cohost-avatar">{cohost.name[0]}</div>
                      <strong>{cohost.name}</strong>
                      <small>Co-host beta slot connected</small>
                    </div>
                    <div className="tile-label">CO-HOST · {cohost.handle}</div>
                  </div>
                )}
              </div>

              <div className="live-controls">
                <button className={isLive ? 'danger' : 'primary'} onClick={startLive}>
                  {isLive ? 'End Live' : 'Go Live'}
                </button>
                {cohost ? (
                  <button className="secondary" onClick={() => { setCohost(null); setToast('Co-host removed') }}>
                    Remove Co-host
                  </button>
                ) : (
                  <button className="secondary" onClick={() => document.getElementById('cohost-panel')?.scrollIntoView({ behavior: 'smooth' })}>
                    Add Co-host
                  </button>
                )}
                <button className="disabled" disabled>Battle · Soon</button>
              </div>
            </section>

            <section className="panel" id="cohost-panel">
              <div className="section-heading">
                <div>
                  <span className="eyebrow">LIVE TOOLS</span>
                  <h2>Co-host</h2>
                </div>
                <span className="beta-tag">BETA</span>
              </div>
              <p className="muted">Invite one creator into the split-screen beta room. Host and co-host roles stay clearly separated.</p>
              <div className="creator-list">
                {creators.map((creator) => (
                  <div className="creator-row" key={creator.id}>
                    <div className="host-id">
                      <div className="avatar">{creator.name[0]}</div>
                      <div>
                        <strong>{creator.name}</strong>
                        <small>{creator.handle} · {creator.status}</small>
                      </div>
                    </div>
                    <button
                      className="mini-btn"
                      disabled={cohost?.id === creator.id}
                      onClick={() => inviteCohost(creator)}
                    >
                      {cohost?.id === creator.id ? 'Joined' : 'Invite'}
                    </button>
                  </div>
                ))}
              </div>
            </section>

            <section className="panel wallet-panel">
              <div className="section-heading">
                <div>
                  <span className="eyebrow">OWNER TEST WALLET</span>
                  <h2>{coins.toLocaleString()} coins</h2>
                </div>
                <span className="owner-tag">LOCAL BETA</span>
              </div>
              <p className="muted">Starter gifts are capped at 100 coins. Gifts under 100 use a quick sender overlay; 100-coin gifts get the premium 5–7 second treatment.</p>
              <div className="coin-actions">
                <button className="secondary" onClick={() => addTestCoins(1000)}>+1K Test Coins</button>
                <button className="secondary" onClick={() => addTestCoins(10000)}>+10K Test Coins</button>
              </div>
              <div className="gift-grid">
                {gifts.map((gift) => (
                  <button className={`gift-card ${gift.cost === 100 ? 'premium-card' : ''}`} key={gift.id} onClick={() => sendGift(gift)}>
                    <span>{gift.emoji}</span>
                    <strong>{gift.label}</strong>
                    <small>{gift.cost} {gift.cost === 1 ? 'coin' : 'coins'}</small>
                  </button>
                ))}
              </div>
            </section>

            <section className="panel chat-panel">
              <div className="section-heading">
                <div>
                  <span className="eyebrow">ROOM</span>
                  <h2>Live chat</h2>
                </div>
              </div>
              <div className="chat-feed">
                {chat.slice(-6).map((item) => (
                  <div className="chat-line" key={item.id}>
                    <strong>{item.user}</strong>
                    <span>{item.text}</span>
                  </div>
                ))}
              </div>
            </section>
          </>
        )}

        {tab === 'discover' && (
          <section className="panel full-panel">
            <span className="eyebrow">DISCOVER</span>
            <h2>Live creators</h2>
            <p className="muted">The beta discovery shell is ready for real room data later.</p>
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
              <strong>Not public yet</strong>
              <p>Battles, events, real wallet accounting, real streaming transport, creator payouts and production authentication remain future beta phases.</p>
            </div>
          </section>
        )}
      </main>

      <nav className="bottom-nav" aria-label="Primary">
        <button className={tab === 'discover' ? 'active' : ''} onClick={() => setTab('discover')}><span>✦</span>Discover</button>
        <button className={tab === 'live' ? 'active center' : 'center'} onClick={() => setTab('live')}><span>●</span>Live</button>
        <button className={tab === 'profile' ? 'active' : ''} onClick={() => setTab('profile')}><span>♙</span>Profile</button>
      </nav>
    </div>
  )
}

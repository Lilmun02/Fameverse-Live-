export default function BottomNav({ tab, setTab, isLive }) {
  return (
    <nav className={`bottom-nav ${tab === 'live' && isLive ? 'nav-hidden-live' : ''}`} aria-label="Primary">
      <button className={tab === 'discover' ? 'active' : ''} onClick={() => setTab('discover')}><span>✦</span>Discover</button>
      <button className={tab === 'live' ? 'active center' : 'center'} onClick={() => setTab('live')}><span>●</span>Live</button>
      <button className={tab === 'profile' ? 'active' : ''} onClick={() => setTab('profile')}><span>♙</span>Profile</button>
    </nav>
  )
}

export default function BottomNav({ tab, setTab, isLive }) {
  return (
    <nav className={`bottom-nav fam-bottom-nav ${tab === 'live' && isLive ? 'nav-hidden-live' : ''}`} aria-label="Primary">
      <button className={tab === 'discover' ? 'active' : ''} onClick={() => setTab('discover')}>
        <span className="fam-nav-icon" aria-hidden="true">✦</span>
        <small>Discover</small>
      </button>
      <button className={tab === 'live' ? 'active center' : 'center'} onClick={() => setTab('live')}>
        <span className="fam-live-nav-orbit" aria-hidden="true"><i /></span>
        <small>Live</small>
      </button>
      <button className={tab === 'profile' ? 'active' : ''} onClick={() => setTab('profile')}>
        <span className="fam-nav-icon" aria-hidden="true">♙</span>
        <small>Profile</small>
      </button>
    </nav>
  )
}

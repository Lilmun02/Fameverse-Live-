export default function BottomNav({ tab, setTab, isLive }) {
  const items = [
    ['home', '⌂', 'Home'],
    ['discover', '✦', 'Discover'],
    ['live', '◉', 'Live'],
    ['profile', '♙', 'Profile'],
  ]

  return (
    <nav className={`bottom-nav fam-bottom-nav ${tab === 'live' && isLive ? 'nav-hidden-live' : ''}`} aria-label="Primary">
      {items.map(([key, icon, label]) => (
        <button
          type="button"
          key={key}
          className={`${tab === key ? 'active' : ''} ${key === 'live' ? 'center' : ''}`.trim()}
          onClick={() => setTab(key)}
        >
          <span className={key === 'live' ? 'fam-live-nav-orbit' : 'fam-nav-icon'} aria-hidden="true">
            {key === 'live' ? <i /> : icon}
          </span>
          <small>{label}</small>
        </button>
      ))}
    </nav>
  )
}

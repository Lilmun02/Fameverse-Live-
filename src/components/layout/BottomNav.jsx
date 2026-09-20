function NavIcon({ name }) {
  const paths = {
    home: <path d="M3 10.8 12 3l9 7.8v9.7a.5.5 0 0 1-.5.5H15v-6H9v6H3.5a.5.5 0 0 1-.5-.5z" />,
    discover: <path d="m12 2 2.2 7.8L22 12l-7.8 2.2L12 22l-2.2-7.8L2 12l7.8-2.2z" />,
    profile: <><circle cx="12" cy="8" r="4" /><path d="M4 21c.8-4.2 3.5-6.3 8-6.3s7.2 2.1 8 6.3" /></>,
  }

  return <svg viewBox="0 0 24 24" aria-hidden="true">{paths[name]}</svg>
}

export default function BottomNav({ tab, setTab }) {
  const items = [['home', 'Home'], ['discover', 'Discover'], ['profile', 'Profile']]
  return (
    <nav className="bottom-nav fv-bottom-nav" aria-label="Primary">
      {items.map(([key, label]) => (
        <button key={key} type="button" className={tab === key ? 'active' : ''} onClick={() => setTab(key)}>
          <NavIcon name={key} /><small>{label}</small>
        </button>
      ))}
    </nav>
  )
}

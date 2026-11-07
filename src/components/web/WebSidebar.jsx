import WebIcon from './WebIcon.jsx'

export default function WebSidebar() {
  const coinsPage = window.location.pathname === '/coins'
  const homePage = window.location.pathname === '/'
  return (
    <aside className="fv-platform-sidebar">
      <nav aria-label="Explore Fameverse">
        <span className="fv-platform-nav-label">DISCOVER</span>
        <a href="/" className={homePage ? 'is-active' : ''}><WebIcon name="home" />For you</a>
        <a href="/#discover-creators"><WebIcon name="people" />Creators</a>
        <a href="/coins#coin-packs" className={coinsPage ? 'is-active' : ''}><WebIcon name="coins" />Fame Coins</a>
      </nav>
    </aside>
  )
}

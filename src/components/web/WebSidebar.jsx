import WebIcon from './WebIcon.jsx'

export default function WebSidebar({ signedIn, onSignIn }) {
  const coinsPage = window.location.pathname === '/coins'
  return (
    <aside className="fv-platform-sidebar">
      <nav aria-label="Explore Fameverse">
        <span className="fv-platform-nav-label">DISCOVER</span>
        <a href="/" className={!coinsPage ? 'is-active' : ''}><WebIcon name="home" />For you</a>
        <a href="/#discover-creators"><WebIcon name="people" />Creators</a>
        <a href="/coins#coin-packs" className={coinsPage ? 'is-active' : ''}><WebIcon name="coins" />Fame Coins</a>
      </nav>
      <div className="fv-platform-sidebar-note">
        <span className="fv-platform-note-mark">F</span><h3>Your people.<br />Your Fameverse.</h3>
        <p>{signedIn ? 'One account for your community and creator support.' : 'Sign in to discover real creators and make the community yours.'}</p>
        {!signedIn && <button type="button" onClick={onSignIn}>Join the conversation<WebIcon name="arrow" size={17} /></button>}
      </div>
      <div className="fv-platform-sidebar-footer"><span className="fv-platform-small-dot" />FAMEVERSE WEB<p>Live connection. Real community.</p><a href="/reset-password">Account recovery</a></div>
    </aside>
  )
}

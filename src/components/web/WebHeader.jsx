import { useEffect, useRef, useState } from 'react'
import { webAccountIdentity } from '../../utils/webAccountIdentity.js'
import WebIcon from './WebIcon.jsx'

export default function WebHeader({ account, onSignIn, query = '', onQueryChange }) {
  const identity = webAccountIdentity(account)
  const menuRef = useRef(null)
  const [signingOut, setSigningOut] = useState(false)
  const [signOutError, setSignOutError] = useState('')

  useEffect(() => {
    if (menuRef.current) menuRef.current.open = false
  }, [account.session?.user?.id])

  useEffect(() => {
    const closeMenu = (event) => {
      if (menuRef.current && !menuRef.current.contains(event.target)) menuRef.current.open = false
    }
    document.addEventListener('pointerdown', closeMenu)
    return () => document.removeEventListener('pointerdown', closeMenu)
  }, [])

  const signOut = async () => {
    setSigningOut(true)
    setSignOutError('')
    try { await account.signOut() }
    catch { setSignOutError('Could not sign out. Please try again.') }
    finally { setSigningOut(false) }
  }

  return (
    <header className="fv-platform-header">
      <a className="fv-platform-brand" href="/" aria-label="Fameverse Live home">
        <span className="fv-web-mark">F</span><span>fameverse<span className="fv-platform-brand-live">LIVE</span></span>
      </a>
      <nav className="fv-platform-topnav" aria-label="Main navigation">
        <a href="/" aria-current={window.location.pathname === '/' && !window.location.search ? 'page' : undefined}>Home</a>
        <a href="/discover" aria-current={window.location.pathname === '/discover' ? 'page' : undefined}>Discover</a>
        {identity.state === 'signed-in' && account.profile?.account_role === 'owner' &&
          <a href="/owner" className="fv-owner-nav-link" aria-current={window.location.pathname.startsWith('/owner') ? 'page' : undefined}>Owner Center</a>}
      </nav>
      {onQueryChange && <form className="fv-platform-search" role="search" onSubmit={(event) => { event.preventDefault(); window.location.assign('/discover?q=' + encodeURIComponent(query.trim())) }}>
        <WebIcon name="search" size={18} /><input aria-label="Search Fameverse members" placeholder="Search members..." value={query} onChange={(event) => onQueryChange(event.target.value)} /><kbd>↵</kbd>
      </form>}
      <div className="fv-platform-auth-state" aria-live="polite">
        {identity.state === 'checking' && <span className="fv-platform-auth-checking">Checking account…</span>}
        {identity.state === 'guest' && <><span className="fv-platform-guest-label">Browsing as a guest</span><button className="fv-platform-signin" type="button" onClick={onSignIn}>Sign in</button></>}
        {identity.state === 'signed-in' && <details className="fv-platform-account" ref={menuRef} onKeyDown={(event) => { if (event.key === 'Escape') { event.currentTarget.open = false; event.currentTarget.querySelector('summary')?.focus() } }}>
          <summary aria-label={`Open your Fameverse account: ${identity.displayName}`}>
            <span className="fv-platform-avatar"><span>{identity.initial}</span>{identity.avatarUrl && <img key={identity.avatarUrl} src={identity.avatarUrl} alt="" onError={(event) => { event.currentTarget.hidden = true }} />}</span>
            <span className="fv-platform-account-copy"><strong>{identity.displayName}</strong><small><i />Signed in{identity.handle ? ` · ${identity.handle}` : ''}</small></span>
            <WebIcon name="chevron" size={16} />
          </summary>
          <div className="fv-platform-account-menu">
            <span className="fv-platform-menu-eyebrow">YOUR FAMEVERSE ACCOUNT</span><strong>{identity.displayName}</strong>
            {identity.handle && <span>{identity.handle}</span>}
            {identity.email && <span className="fv-platform-account-email">{identity.email}</span>}
            {identity.profileLoading && <small>Signed in. Your profile is still loading.</small>}
            <p>Coin purchases are attached to this account.</p>
            <a href={`/profile/${encodeURIComponent(account.session.user.id)}`}><WebIcon name="people" size={18} />My profile</a>
            <a href="/settings"><WebIcon name="people" size={18} />Settings</a>
            {account.profile?.account_role === 'owner' &&
              <a href="/owner"><WebIcon name="home" size={18} />Owner Command Center</a>}
            <button type="button" disabled={signingOut} onClick={signOut}><WebIcon name="logout" size={18} />{signingOut ? 'Signing out…' : 'Sign out'}</button>
            {signOutError && <small role="alert">{signOutError}</small>}
          </div>
        </details>}
      </div>
    </header>
  )
}

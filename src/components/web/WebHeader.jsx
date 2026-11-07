import { useEffect, useRef, useState } from 'react'
import { webAccountIdentity } from '../../utils/webAccountIdentity.js'
import WebIcon from './WebIcon.jsx'
import { supabase } from '../../services/supabase.js'

export default function WebHeader({ account, onSignIn, query = '', onQueryChange }) {
  const identity = webAccountIdentity(account)
  const menuRef = useRef(null)
  const [signingOut, setSigningOut] = useState(false)
  const [signOutError, setSignOutError] = useState('')
  const [coinBalance, setCoinBalance] = useState(null)
  const [balanceError, setBalanceError] = useState(false)
  const userId = account.session?.user?.id

  useEffect(() => {
    let active = true
    if (!userId) { setCoinBalance(null); setBalanceError(false); return undefined }
    const refreshBalance = async () => {
      const { data, error } = await supabase.rpc('get_my_coin_funding_breakdown')
      if (!active) return
      if (error) { setBalanceError(true); setCoinBalance(null); return }
      setBalanceError(false)
      setCoinBalance(Number((Array.isArray(data) ? data[0] : data)?.total_balance ?? 0))
    }
    refreshBalance()
    const onFocus = () => { refreshBalance() }
    window.addEventListener('focus', onFocus)
    const onVisibility = () => { if (document.visibilityState === 'visible') refreshBalance() }
    document.addEventListener('visibilitychange', onVisibility)
    return () => { active = false; window.removeEventListener('focus', onFocus); document.removeEventListener('visibilitychange', onVisibility) }
  }, [userId])

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
      {userId && <div className="fv-header-coin-balance" role="status" aria-label="Available Fame Coin balance" style={{ display: "flex", flexDirection: "column", alignItems: "center", gap: 2, padding: "6px 12px", border: "1px solid #76508f", borderRadius: 12, background: "#281432", color: "#f7effb", fontVariantNumeric: "tabular-nums" }}><small style={{ fontSize: 10, fontWeight: 700, letterSpacing: ".06em" }}>AVAILABLE FAME COINS</small><strong style={{ fontSize: 18 }}>{balanceError ? "Unavailable" : coinBalance === null ? "Loading…" : coinBalance.toLocaleString("en-US")}</strong></div>}
      <nav className="fv-platform-topnav" aria-label="Main navigation">
        <a href="/">Explore</a><a href="/#discover-creators">Creators</a><a href="/coins#coin-packs">Coins</a>
      </nav>
      {onQueryChange && <form className="fv-platform-search" role="search" onSubmit={(event) => { event.preventDefault(); document.getElementById('discover-creators')?.scrollIntoView({ behavior: 'smooth' }) }}>
        <WebIcon name="search" size={18} /><input aria-label="Search creators and live titles" placeholder="Search creators, live titles…" value={query} onChange={(event) => onQueryChange(event.target.value)} /><kbd>↵</kbd>
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
            <a href="/coins#coin-packs"><WebIcon name="coins" size={18} />Fame Coins</a>
            <button type="button" disabled={signingOut} onClick={signOut}><WebIcon name="logout" size={18} />{signingOut ? 'Signing out…' : 'Sign out'}</button>
            {signOutError && <small role="alert">{signOutError}</small>}
          </div>
        </details>}
      </div>
    </header>
  )
}

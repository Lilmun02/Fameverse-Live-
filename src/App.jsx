import { useEffect, useState } from 'react'
import AuthScreen from './components/auth/AuthScreen.jsx'
import DiscoverScreen from './components/discover/DiscoverScreen.jsx'
import HomeScreen from './components/home/HomeScreen.jsx'
import BottomNav from './components/layout/BottomNav.jsx'
import ProfileScreen from './components/profile/ProfileScreen.jsx'
import { useAccount } from './hooks/useAccount.js'
import { useCreatorDiscovery } from './hooks/useCreatorDiscovery.js'
import { useFollowNetwork } from './hooks/useFollowNetwork.js'
import { usePwaInstall } from './hooks/usePwaInstall.js'

const SPLASH_MINIMUM_MS = 1800

export default function App() {
  const [toast, setToast] = useState('')
  const [tab, setTab] = useState('home')
  const [profileMode, setProfileMode] = useState('view')
  const [policyPage, setPolicyPage] = useState(null)
  const [settingsDetail, setSettingsDetail] = useState(null)
  const [creatorTab, setCreatorTab] = useState('clips')
  const [splashMinimumElapsed, setSplashMinimumElapsed] = useState(false)

  const account = useAccount({ setToast })
  const actorId = account.session?.user?.id || null
  const creatorDiscovery = useCreatorDiscovery({ userId: actorId, enabled: Boolean(account.session) })
  const followNetwork = useFollowNetwork({ userId: actorId, setToast })
  const pwa = usePwaInstall(setToast)
  const displayName = account.profile?.display_name || account.session?.user?.email?.split('@')[0] || 'Fameverse User'
  const username = account.profile?.username ? `@${account.profile.username}` : '@newuser'
  const initial = displayName.trim().charAt(0).toUpperCase() || 'F'
  const joinedLabel = account.profile?.created_at
    ? new Intl.DateTimeFormat('en-US', { month: 'short', year: 'numeric' }).format(new Date(account.profile.created_at))
    : 'Beta 2026'

  useEffect(() => {
    const timer = window.setTimeout(() => setSplashMinimumElapsed(true), SPLASH_MINIMUM_MS)
    return () => window.clearTimeout(timer)
  }, [])

  useEffect(() => {
    if (!toast) return
    const timer = window.setTimeout(() => setToast(''), 2400)
    return () => window.clearTimeout(timer)
  }, [toast])

  useEffect(() => {
    if (tab !== 'profile') {
      setProfileMode('view')
      setPolicyPage(null)
      setSettingsDetail(null)
    }
  }, [tab])

  const signOut = async () => {
    await account.signOut()
    setTab('home')
    setProfileMode('view')
    setPolicyPage(null)
    setSettingsDetail(null)
  }

  if (!account.authReady || !splashMinimumElapsed) {
    return (
      <div className="boot-splash" aria-label="Opening Fameverse">
        <div>
          <div className="boot-mark">F</div>
          <strong>FAMEVERSE <span>LIVE</span></strong>
          <small>Opening your Fameverse…</small>
        </div>
      </div>
    )
  }

  if (account.recoveryMode) {
    return <div className="auth-shell"><section className="auth-card">
      <h1>Set a new password</h1>
      <form className="auth-form" onSubmit={account.completePasswordReset}>
        <label>New password<input type="password" autoComplete="new-password" minLength={8}
          value={account.recoveryPassword}
          onChange={(event) => account.setRecoveryPassword(event.target.value)} /></label>
        {account.authMessage && <div className="auth-message">{account.authMessage}</div>}
        <button className="auth-primary" type="submit">Update password</button>
      </form></section></div>
  }

  if (!account.session) {
    return <AuthScreen
      authMode={account.authMode}
      setAuthMode={account.setAuthMode}
      authForm={account.authForm}
      setAuthForm={account.setAuthForm}
      authMessage={account.authMessage}
      setAuthMessage={account.setAuthMessage}
      submitAuth={account.submitAuth}
      requestPasswordReset={account.requestPasswordReset}
      resetRequestBusy={account.resetRequestBusy}
    />
  }

  return (
    <div className="app-shell">
      {toast && <div className="toast">{toast}</div>}
      <main>
        {tab === 'home' && <HomeScreen
          displayName={displayName}
          username={username}
          initial={initial}
          followNetwork={followNetwork}
          setTab={setTab}
          standalone={pwa.standalone}
          installPwa={pwa.installPwa}
        />}
        {tab === 'discover' && <DiscoverScreen
          setTab={setTab}
          creatorDiscovery={creatorDiscovery}
          followNetwork={followNetwork}
          currentProfile={account.profile}
        />}
        {tab === 'profile' && <ProfileScreen
          profileMode={profileMode}
          setProfileMode={setProfileMode}
          policyPage={policyPage}
          setPolicyPage={setPolicyPage}
          settingsDetail={settingsDetail}
          setSettingsDetail={setSettingsDetail}
          creatorTab={creatorTab}
          setCreatorTab={setCreatorTab}
          session={account.session}
          profile={account.profile}
          displayName={displayName}
          username={username}
          initial={initial}
          joinedLabel={joinedLabel}
          profileDraft={account.profileDraft}
          setProfileDraft={account.setProfileDraft}
          saveProfile={account.saveProfile}
          profileBusy={account.profileBusy}
          signOut={signOut}
          setTab={setTab}
          followNetwork={followNetwork}
        />}
      </main>
      <BottomNav tab={tab} setTab={setTab} />
    </div>
  )
}

import { useEffect, useMemo, useState } from 'react'
import AuthScreen from './components/auth/AuthScreen.jsx'
import DiscoverScreen from './components/discover/DiscoverScreen.jsx'
import GiftOverlay from './components/gifts/GiftOverlay.jsx'
import HomeScreen from './components/home/HomeScreen.jsx'
import BottomNav from './components/layout/BottomNav.jsx'
import LiveScreen from './components/live/LiveScreen.jsx'
import ProfileScreen from './components/profile/ProfileScreen.jsx'
import { useAccount } from './hooks/useAccount.js'
import { useFollowNetwork } from './hooks/useFollowNetwork.js'
import { useGiftSystem } from './hooks/useGiftSystem.js'
import { useLiveMedia } from './hooks/useLiveMedia.js'
import { useLiveSessionSummary } from './hooks/useLiveSessionSummary.js'
import { useLiveSetup } from './hooks/useLiveSetup.js'
import { usePwaInstall } from './hooks/usePwaInstall.js'

const SPLASH_MINIMUM_MS = 900

export default function App() {
  const [toast, setToast] = useState('')
  const [tab, setTab] = useState('home')
  const [profileMode, setProfileMode] = useState('view')
  const [policyPage, setPolicyPage] = useState(null)
  const [settingsDetail, setSettingsDetail] = useState(null)
  const [creatorTab, setCreatorTab] = useState('clips')
  const [chat, setChat] = useState([])
  const [commentText, setCommentText] = useState('')
  const [cohostTrayOpen, setCohostTrayOpen] = useState(false)
  const [splashMinimumElapsed, setSplashMinimumElapsed] = useState(false)

  const live = useLiveMedia(setToast)
  const liveSetup = useLiveSetup(setToast)
  const sessionSummary = useLiveSessionSummary()
  const account = useAccount({
    setToast,
    onBeforeSignOut: () => {
      live.stopMedia()
      live.setIsLive(false)
    },
  })
  const followNetwork = useFollowNetwork({ userId: account.session?.user?.id, setToast })
  const displayName = account.profile?.display_name || account.session?.user?.email?.split('@')[0] || 'Fameverse User'
  const username = account.profile?.username ? `@${account.profile.username}` : '@newuser'
  const initial = displayName.trim().charAt(0).toUpperCase() || 'F'
  const joinedLabel = account.profile?.created_at
    ? new Intl.DateTimeFormat('en-US', { month: 'short', year: 'numeric' }).format(new Date(account.profile.created_at))
    : 'Beta 2026'

  const gifts = useGiftSystem({
    isLive: live.isLive,
    displayName,
    setToast,
    setChat,
    onGiftAccepted: sessionSummary.recordGift,
  })
  const pwa = usePwaInstall(setToast)
  const viewerCount = useMemo(() => 0, [])
  const liveMessages = chat

  useEffect(() => {
    const timer = window.setTimeout(() => setSplashMinimumElapsed(true), SPLASH_MINIMUM_MS)
    return () => window.clearTimeout(timer)
  }, [])

  useEffect(() => {
    if (!toast) return
    const timer = setTimeout(() => setToast(''), 2400)
    return () => clearTimeout(timer)
  }, [toast])

  useEffect(() => {
    gifts.setGiftTrayOpen(false)
    setCohostTrayOpen(false)
    if (tab !== 'profile') {
      setProfileMode('view')
      setPolicyPage(null)
      setSettingsDetail(null)
    }
  }, [tab])

  const startLive = async () => {
    const wasLive = live.isLive
    const roomTitle = liveSetup.active?.title || liveSetup.draft.title.trim() || 'Live session'
    const result = await live.startLive()

    if (wasLive) {
      sessionSummary.finishSession({ title: roomTitle, viewerCount })
      gifts.stopGiftPlayback()
      gifts.setGiftTrayOpen(false)
      setCohostTrayOpen(false)
      setChat([])
      setCommentText('')
      liveSetup.reset()
      return result
    }

    if (result) sessionSummary.beginSession({ title: roomTitle })
    return result
  }

  const submitComment = (event) => {
    event.preventDefault()
    const text = commentText.trim()
    if (!text) return
    setChat((items) => [...items, { id: Date.now(), user: displayName, text }])
    setCommentText('')
  }

  const shareRoom = async () => {
    const roomTitle = liveSetup.active?.title || 'Fameverse Live Beta'
    const shareData = {
      title: roomTitle,
      text: liveSetup.active?.title
        ? `${displayName} is live on Fameverse: ${liveSetup.active.title}`
        : `${displayName} is testing Fameverse Live.`,
      url: window.location.href,
    }
    try {
      if (navigator.share) await navigator.share(shareData)
      else {
        await navigator.clipboard.writeText(window.location.href)
        setToast('Beta link copied')
      }
    } catch {
      // User cancelled share sheet.
    }
  }

  const signOut = async () => {
    gifts.stopGiftPlayback()
    liveSetup.reset()
    sessionSummary.clear()
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

  if (!account.session) {
    return (
      <AuthScreen
        authMode={account.authMode}
        setAuthMode={account.setAuthMode}
        authForm={account.authForm}
        setAuthForm={account.setAuthForm}
        authMessage={account.authMessage}
        setAuthMessage={account.setAuthMessage}
        submitAuth={account.submitAuth}
      />
    )
  }

  return (
    <div className={`app-shell ${tab === 'live' && live.isLive ? 'live-app-shell' : ''}`}>
      {toast && <div className="toast">{toast}</div>}
      <GiftOverlay giftOverlay={gifts.giftOverlay} />

      <main>
        {tab === 'home' && (
          <HomeScreen
            displayName={displayName}
            username={username}
            initial={initial}
            followNetwork={followNetwork}
            setTab={setTab}
            standalone={pwa.standalone}
            installPwa={pwa.installPwa}
          />
        )}

        {tab === 'discover' && <DiscoverScreen setTab={setTab} />}

        {tab === 'live' && (
          <LiveScreen
            isLive={live.isLive}
            mediaStream={live.mediaStream}
            cameraOff={live.cameraOff}
            activeVideoSlot={live.activeVideoSlot}
            videoSlotFacing={live.videoSlotFacing}
            videoPrimaryRef={live.videoPrimaryRef}
            videoSecondaryRef={live.videoSecondaryRef}
            displayName={displayName}
            username={username}
            initial={initial}
            viewerCount={viewerCount}
            isStartingLive={live.isStartingLive}
            startLive={startLive}
            liveSetup={liveSetup}
            sessionSummary={sessionSummary}
            premiumRepeat={gifts.premiumRepeat}
            setGiftTrayOpen={gifts.setGiftTrayOpen}
            setCohostTrayOpen={setCohostTrayOpen}
            micMuted={live.micMuted}
            toggleMic={live.toggleMic}
            toggleCamera={live.toggleCamera}
            flipCamera={live.flipCamera}
            shareRoom={shareRoom}
            liveMessages={liveMessages}
            commentText={commentText}
            setCommentText={setCommentText}
            submitComment={submitComment}
            giftTrayOpen={gifts.giftTrayOpen}
            coins={gifts.coins}
            sendGift={gifts.sendGift}
            addTestCoins={gifts.addTestCoins}
            cohostTrayOpen={cohostTrayOpen}
          />
        )}

        {tab === 'profile' && (
          <ProfileScreen
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
            shareRoom={shareRoom}
            profileDraft={account.profileDraft}
            setProfileDraft={account.setProfileDraft}
            saveProfile={account.saveProfile}
            profileBusy={account.profileBusy}
            signOut={signOut}
            setTab={setTab}
            followNetwork={followNetwork}
          />
        )}
      </main>

      <BottomNav tab={tab} setTab={setTab} isLive={live.isLive} />
    </div>
  )
}

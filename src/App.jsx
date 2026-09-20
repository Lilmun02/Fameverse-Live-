import { useEffect, useRef, useState } from 'react'
import AuthScreen from './components/auth/AuthScreen.jsx'
import DiscoverScreen from './components/discover/DiscoverScreen.jsx'
import GiftOverlay from './components/gifts/GiftOverlay.jsx'
import HomeScreen from './components/home/HomeScreen.jsx'
import BottomNav from './components/layout/BottomNav.jsx'
import ViewerLiveScreen from './components/live/ViewerLiveScreen.jsx'
import ProfileScreen from './components/profile/ProfileScreen.jsx'
import { useAccount } from './hooks/useAccount.js'
import { useCreatorDiscovery } from './hooks/useCreatorDiscovery.js'
import { useFollowNetwork } from './hooks/useFollowNetwork.js'
import { useGiftSystem } from './hooks/useGiftSystem.js'
import { useGiftWallet } from './hooks/useGiftWallet.js'
import { useGifterLevel } from './hooks/useGifterLevel.js'
import { useLiveActivity } from './hooks/useLiveActivity.js'
import { useLiveDiscovery } from './hooks/useLiveDiscovery.js'
import { usePwaInstall } from './hooks/usePwaInstall.js'

const SPLASH_MINIMUM_MS = 1800

function liveRoomFromUrl() {
  return new URL(window.location.href).searchParams.get('live')
}

function buildLiveShareUrl(roomId) {
  const url = new URL(window.location.href)
  if (roomId) url.searchParams.set('live', roomId)
  else url.searchParams.delete('live')
  return url.toString()
}

export default function App() {
  const [toast, setToast] = useState('')
  const [tab, setTab] = useState('home')
  const [profileMode, setProfileMode] = useState('view')
  const [policyPage, setPolicyPage] = useState(null)
  const [settingsDetail, setSettingsDetail] = useState(null)
  const [creatorTab, setCreatorTab] = useState('clips')
  const [chat, setChat] = useState([])
  const [commentText, setCommentText] = useState('')
  const [viewingRoom, setViewingRoom] = useState(null)
  const [splashMinimumElapsed, setSplashMinimumElapsed] = useState(false)
  const deepLinkHandledRef = useRef(false)
  const activityRef = useRef(null)

  const account = useAccount({ setToast })
  const actorId = account.session?.user?.id || null
  const liveDiscovery = useLiveDiscovery({
    userId: actorId,
    enabled: Boolean(account.session),
  })
  const creatorDiscovery = useCreatorDiscovery({
    userId: actorId,
    enabled: Boolean(account.session),
  })
  const followNetwork = useFollowNetwork({ userId: actorId, setToast })
  const displayName = account.profile?.display_name || account.session?.user?.email?.split('@')[0] || 'Fameverse User'
  const username = account.profile?.username ? `@${account.profile.username}` : '@newuser'
  const initial = displayName.trim().charAt(0).toUpperCase() || 'F'
  const joinedLabel = account.profile?.created_at
    ? new Intl.DateTimeFormat('en-US', { month: 'short', year: 'numeric' }).format(new Date(account.profile.created_at))
    : 'Beta 2026'
  const activeActivityRoomId = viewingRoom?.id || null
  const wallet = useGiftWallet({ userId: actorId, setToast })
  const gifter = useGifterLevel({ userId: actorId, roomId: activeActivityRoomId })

  const gifts = useGiftSystem({
    isLive: Boolean(viewingRoom),
    displayName,
    actorId,
    gifterLevel: gifter.level,
    coins: wallet.balance,
    walletReady: wallet.ready,
    setWalletBalance: wallet.applyBalance,
    recordGifterGift: gifter.recordGift,
    addTestCoins: wallet.refill,
    setToast,
    setChat,
    onGiftAccepted: (giftEvent) => {
      activityRef.current?.sendGift?.(giftEvent)
    },
  })
  const activity = useLiveActivity({
    roomId: activeActivityRoomId,
    displayName,
    actorId,
    gifterLevel: gifter.level,
    enabled: Boolean(account.session && activeActivityRoomId),
    setMessages: setChat,
    onRemoteGift: gifts.receiveGift,
  })
  activityRef.current = activity

  const pwa = usePwaInstall(setToast)
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
    if (!account.session || deepLinkHandledRef.current || liveDiscovery.state === 'loading') return
    const targetRoomId = liveRoomFromUrl()
    if (!targetRoomId) {
      deepLinkHandledRef.current = true
      return
    }
    const room = liveDiscovery.rooms.find((item) => item.id === targetRoomId)
    if (!room) {
      if (liveDiscovery.state === 'ready') {
        deepLinkHandledRef.current = true
        setToast('That Live is no longer active')
      }
      return
    }
    deepLinkHandledRef.current = true
    setTab('discover')
    setViewingRoom(room)
  }, [account.session, liveDiscovery.rooms, liveDiscovery.state])

  useEffect(() => {
    gifts.setGiftTrayOpen(false)
    if (tab !== 'discover') setViewingRoom(null)
    if (tab !== 'profile') {
      setProfileMode('view')
      setPolicyPage(null)
      setSettingsDetail(null)
    }
  }, [tab])

  useEffect(() => {
    setChat([])
    setCommentText('')
    gifts.setGiftTrayOpen(false)
  }, [activeActivityRoomId])

  const submitComment = (event) => {
    event.preventDefault()
    const text = commentText.trim()
    if (!text) return
    if (!activity.sendComment(text)) {
      setToast('Live chat is reconnecting')
      return
    }
    setCommentText('')
  }

  const shareRoom = async (roomOverride = null) => {
    const room = roomOverride || viewingRoom
    const roomTitle = room?.title || 'Fameverse Live Beta'
    const creatorName = room?.host?.displayName || room?.host?.username || displayName
    const shareData = {
      title: roomTitle,
      text: `${creatorName} is live on Fameverse: ${roomTitle}`,
      url: buildLiveShareUrl(room?.id),
    }
    try {
      if (navigator.share) await navigator.share(shareData)
      else {
        await navigator.clipboard.writeText(shareData.url)
        setToast('Live link copied')
      }
    } catch {
      // User cancelled share sheet.
    }
  }

  const closeViewingRoom = () => {
    setViewingRoom(null)
    const url = new URL(window.location.href)
    url.searchParams.delete('live')
    window.history.replaceState({}, '', url)
  }

  const signOut = async () => {
    gifts.stopGiftPlayback()
    setViewingRoom(null)
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
    <div className="app-shell">
      {toast && <div className="toast">{toast}</div>}
      <GiftOverlay giftOverlay={gifts.giftOverlay} />

      {viewingRoom ? (
        <ViewerLiveScreen
          room={viewingRoom}
          onClose={closeViewingRoom}
          followNetwork={followNetwork}
          shareRoom={() => shareRoom(viewingRoom)}
          liveMessages={liveMessages}
          commentText={commentText}
          setCommentText={setCommentText}
          submitComment={submitComment}
          giftTrayOpen={gifts.giftTrayOpen}
          setGiftTrayOpen={gifts.setGiftTrayOpen}
          coins={gifts.coins}
          sendGift={gifts.sendGift}
          addTestCoins={gifts.addTestCoins}
          currentUserId={actorId}
          currentDisplayName={displayName}
          currentAvatarUrl={account.profile?.avatar_url || null}
          setToast={setToast}
        />
      ) : (
        <>
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

            {tab === 'discover' && (
              <DiscoverScreen
                setTab={setTab}
                liveDiscovery={liveDiscovery}
                creatorDiscovery={creatorDiscovery}
                followNetwork={followNetwork}
                currentProfile={account.profile}
                onOpenLiveRoom={setViewingRoom}
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

          <BottomNav tab={tab} setTab={setTab} />
        </>
      )}
    </div>
  )
}

import { useEffect, useRef, useState } from 'react'
import AuthScreen from './components/auth/AuthScreen.jsx'
import DiscoverScreen from './components/discover/DiscoverScreen.jsx'
import GiftOverlay from './components/gifts/GiftOverlay.jsx'
import HomeScreen from './components/home/HomeScreen.jsx'
import BottomNav from './components/layout/BottomNav.jsx'
import LiveScreen from './components/live/LiveScreen.jsx'
import ViewerLiveScreen from './components/live/ViewerLiveScreen.jsx'
import ProfileScreen from './components/profile/ProfileScreen.jsx'
import { useAccount } from './hooks/useAccount.js'
import { useCohostHost } from './hooks/useCohostHost.js'
import { useCreatorDiscovery } from './hooks/useCreatorDiscovery.js'
import { useFollowNetwork } from './hooks/useFollowNetwork.js'
import { useGiftSystem } from './hooks/useGiftSystem.js'
import { useGifterLevel } from './hooks/useGifterLevel.js'
import { useLiveActivity } from './hooks/useLiveActivity.js'
import { useLiveBroadcast } from './hooks/useLiveBroadcast.js'
import { useLiveDiscovery } from './hooks/useLiveDiscovery.js'
import { useLiveMedia } from './hooks/useLiveMedia.js'
import { useLivePresence } from './hooks/useLivePresence.js'
import { useLiveSessionSummary } from './hooks/useLiveSessionSummary.js'
import { useLiveSetup } from './hooks/useLiveSetup.js'
import { useLiveTapTotals } from './hooks/useLiveTapTotals.js'
import { usePwaInstall } from './hooks/usePwaInstall.js'

const SPLASH_MINIMUM_MS = 1800

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
  const [viewingRoom, setViewingRoom] = useState(null)
  const [splashMinimumElapsed, setSplashMinimumElapsed] = useState(false)
  const activityRef = useRef(null)

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
  const actorId = account.session?.user?.id || null
  const presence = useLivePresence({ userId: actorId })
  const broadcast = useLiveBroadcast({
    roomId: presence.room?.id,
    stream: live.mediaStream,
    enabled: live.isLive && Boolean(presence.room?.id),
  })
  const cohostHost = useCohostHost({
    roomId: presence.room?.id,
    enabled: live.isLive && Boolean(presence.room?.id),
    viewerIds: broadcast.viewerIds,
    setToast,
  })
  const tapTotals = useLiveTapTotals({ roomId: presence.room?.id })
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
  const activeActivityRoomId = live.isLive ? presence.room?.id : viewingRoom?.id
  const gifter = useGifterLevel({ userId: actorId, roomId: activeActivityRoomId, setToast })

  const gifts = useGiftSystem({
    isLive: live.isLive || Boolean(viewingRoom),
    displayName,
    actorId,
    gifterLevel: gifter.level,
    recordGifterGift: gifter.recordGift,
    setToast,
    setChat,
    onGiftAccepted: (giftEvent) => {
      if (live.isLive) sessionSummary.recordGift(giftEvent)
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
  const viewerCount = broadcast.viewerCount
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

  const startLive = async () => {
    const wasLive = live.isLive
    const roomTitle = liveSetup.active?.title || liveSetup.draft.title.trim() || 'Live session'
    const result = await live.startLive()

    if (wasLive) {
      cohostHost.endCohost()
      const presenceEnded = await presence.endPresence()
      sessionSummary.finishSession({ title: roomTitle, viewerCount })
      gifts.stopGiftPlayback()
      gifts.setGiftTrayOpen(false)
      setCohostTrayOpen(false)
      setChat([])
      setCommentText('')
      liveSetup.reset()
      setToast(presenceEnded ? 'Live ended' : 'Live ended locally · room presence will expire')
      return result
    }

    if (!result) return false

    const presenceStarted = await presence.startPresence(roomTitle)
    if (!presenceStarted) {
      live.stopMedia()
      live.setIsLive(false)
      setToast('Could not publish Live room · try again')
      return false
    }

    sessionSummary.beginSession({ title: roomTitle })
    setToast("You're Live on Fameverse")
    return true
  }

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
    const roomTitle = roomOverride?.title || liveSetup.active?.title || 'Fameverse Live Beta'
    const creatorName = roomOverride?.host?.displayName || roomOverride?.host?.username || displayName
    const shareData = {
      title: roomTitle,
      text: `${creatorName} is live on Fameverse: ${roomTitle}`,
      url: window.location.href,
    }
    try {
      if (navigator.share) await navigator.share(shareData)
      else {
        await navigator.clipboard.writeText(window.location.href)
        setToast('Live link copied')
      }
    } catch {
      // User cancelled share sheet.
    }
  }

  const signOut = async () => {
    cohostHost.endCohost()
    gifts.stopGiftPlayback()
    await presence.endPresence()
    liveSetup.reset()
    sessionSummary.clear()
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
    <div className={`app-shell ${tab === 'live' && live.isLive ? 'live-app-shell' : ''}`}>
      {toast && <div className="toast">{toast}</div>}
      <GiftOverlay giftOverlay={gifts.giftOverlay} />

      {viewingRoom ? (
        <ViewerLiveScreen
          room={viewingRoom}
          onClose={() => setViewingRoom(null)}
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
                tapCount={tapTotals.rawTaps}
                isStartingLive={live.isStartingLive}
                startLive={startLive}
                liveSetup={liveSetup}
                sessionSummary={sessionSummary}
                premiumRepeat={gifts.premiumRepeat}
                setGiftTrayOpen={gifts.setGiftTrayOpen}
                setCohostTrayOpen={setCohostTrayOpen}
                micMuted={live.micMuted}
                toggleMic={live.toggleMic}
                cameraOff={live.cameraOff}
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
                cohost={cohostHost}
                presenceState={presence.state}
                currentUserId={actorId}
                followNetwork={followNetwork}
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
        </>
      )}
    </div>
  )
}

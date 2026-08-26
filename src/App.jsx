import { useEffect, useMemo, useRef, useState } from 'react'
import { supabase } from './supabase.js'

const GROK_WELCOME_VIDEO = 'https://d2ol7oe51mr4n9.cloudfront.net/user_3IL6AXXAqcrsLZJmbjvrquIP0Bd/8d3fd7e2-9073-4e1b-8ef6-843a1514aae6.mp4'

const gifts = [
  { id: 'welcome-to-fameverse', label: 'Welcome to Fameverse', cost: 100, activityEmoji: '\u2726', rendererId: 'welcome-to-fameverse', video: GROK_WELCOME_VIDEO, thumbnailTime: 2.6, cinematic: true },
  { id: 'rose', emoji: '\uD83C\uDF39', label: 'Rose', cost: 1 },
  { id: 'heart', emoji: '\uD83D\uDC9C', label: 'Heart', cost: 5 },
  { id: 'fire', emoji: '\uD83D\uDD25', label: 'Fire', cost: 10 },
  { id: 'star', emoji: '\u2B50', label: 'Star', cost: 20 },
  { id: 'crown', emoji: '\uD83D\uDC51', label: 'Crown', cost: 50 },
]

const creatorContent = {
  clips: ['Clips', 'Short highlights from your lives will appear here.'],
  replays: ['Replays', 'Saved live replays will appear here when cloud rooms are connected.'],
  gifts: ['Gifts', 'Public gift history will appear here after the production wallet is built.'],
}

function loadCoins() {
  const saved = Number(localStorage.getItem('fameverse-owner-test-coins'))
  return Number.isFinite(saved) && saved >= 0 ? saved : 10000
}

function isRunningStandalone() {
  return window.matchMedia?.('(display-mode: standalone)').matches || window.navigator.standalone === true
}

function cleanUsername(value = '') {
  return value.toLowerCase().replace(/^@/, '').replace(/[^a-z0-9_]/g, '').slice(0, 24)
}

function seekGiftThumbnail(event, seconds = 0) {
  const video = event.currentTarget
  if (!Number.isFinite(seconds) || seconds <= 0) return
  try { video.currentTime = seconds } catch {}
}

export default function App() {
  const [authReady, setAuthReady] = useState(false)
  const [session, setSession] = useState(null)
  const [profile, setProfile] = useState(null)
  const [profileBusy, setProfileBusy] = useState(false)
  const [authMode, setAuthMode] = useState('signin')
  const [authForm, setAuthForm] = useState({ email: '', password: '', displayName: '' })
  const [authMessage, setAuthMessage] = useState('')
  const [tab, setTab] = useState('live')
  const [profileMode, setProfileMode] = useState('view')
  const [creatorTab, setCreatorTab] = useState('clips')
  const [isLive, setIsLive] = useState(false)
  const [isStartingLive, setIsStartingLive] = useState(false)
  const [coins, setCoins] = useState(loadCoins)
  const [chat, setChat] = useState([])
  const [commentText, setCommentText] = useState('')
  const [toast, setToast] = useState('')
  const [giftOverlay, setGiftOverlay] = useState(null)
  const [premiumRepeat, setPremiumRepeat] = useState(null)
  const [mediaStream, setMediaStream] = useState(null)
  const [micMuted, setMicMuted] = useState(false)
  const [cameraOff, setCameraOff] = useState(false)
  const [facingMode, setFacingMode] = useState('user')
  const [standalone, setStandalone] = useState(isRunningStandalone)
  const [giftTrayOpen, setGiftTrayOpen] = useState(false)
  const [profileDraft, setProfileDraft] = useState({ display_name: '', username: '', bio: '' })

  const giftTimerRef = useRef(null)
  const premiumRepeatTimerRef = useRef(null)
  const premiumComboRef = useRef({ id: null, at: 0, count: 0 })
  const videoRef = useRef(null)
  const streamRef = useRef(null)
  const coinsRef = useRef(coins)

  const viewerCount = useMemo(() => 0, [])
  const displayName = profile?.display_name || session?.user?.email?.split('@')[0] || 'Fameverse User'
  const username = profile?.username ? `@${profile.username}` : '@newuser'
  const initial = displayName.trim().charAt(0).toUpperCase() || 'F'

  useEffect(() => {
    let mounted = true
    supabase.auth.getSession().then(({ data }) => {
      if (!mounted) return
      setSession(data.session)
      setAuthReady(true)
    }).catch(() => setAuthReady(true))
    const { data: authListener } = supabase.auth.onAuthStateChange((_event, nextSession) => {
      setSession(nextSession)
      setAuthReady(true)
    })
    return () => {
      mounted = false
      authListener.subscription.unsubscribe()
    }
  }, [])

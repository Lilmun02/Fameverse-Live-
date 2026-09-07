import '../../../styles/gifts/engine.css'
import {
  primeGiftAudio,
  startGiftAudioSession,
  stopGiftAudioSession,
} from './gift-audio.js'

const GROK_WELCOME_VIDEO = 'https://d2ol7oe51mr4n9.cloudfront.net/user_3IL6AXXAqcrsLZJmbjvrquIP0Bd/8d3fd7e2-9073-4e1b-8ef6-843a1514aae6.mp4'

const giftRegistry = Object.freeze({
  welcomeToFameverse: {
    id: 'welcome-to-fameverse',
    label: 'Welcome to Fameverse',
    tier: 'premium',
    duration: 6400,
    cost: 100,
    video: GROK_WELCOME_VIDEO,
    effect: 'video-cinematic',
  },
})

let activeGift = null
let giftQueue = []
const giftMediaCache = new Map()

function isLiveActive() {
  return Boolean(document.querySelector('.mobile-live-shell.is-live, .fv-viewer-live'))
}

function getGiftVideo(config) {
  const cached = giftMediaCache.get(config.id)
  if (cached) return cached

  const video = document.createElement('video')
  video.className = 'fv-gift-video'
  video.src = config.video
  video.preload = 'auto'
  video.playsInline = true
  video.autoplay = false
  video.controls = false
  video.loop = false
  video.muted = false
  video.defaultMuted = false
  video.volume = 0.82
  video.disablePictureInPicture = true
  video.setAttribute('playsinline', '')
  video.setAttribute('webkit-playsinline', '')
  video.setAttribute('disableRemotePlayback', '')

  try { video.load() } catch {}
  giftMediaCache.set(config.id, video)
  return video
}

function primeGiftMedia() {
  for (const config of Object.values(giftRegistry)) {
    if (config.video) getGiftVideo(config)
  }
  return true
}

function primeGiftPlayback() {
  primeGiftMedia()
  return primeGiftAudio()
}

function resetGiftVideo(video) {
  if (!video) return
  try { video.pause() } catch {}
  video.muted = false
  video.defaultMuted = false
  video.volume = 0.82
  try { video.currentTime = 0 } catch {}
}

function destroyActiveScene() {
  if (!activeGift) return

  clearTimeout(activeGift.timer)
  if (activeGift.video) {
    if (activeGift.onEnded) activeGift.video.removeEventListener('ended', activeGift.onEnded)
    if (activeGift.onPlaying) activeGift.video.removeEventListener('playing', activeGift.onPlaying)
    resetGiftVideo(activeGift.video)
  }
  activeGift.root?.remove()
  activeGift = null
}

function stopGiftEngine() {
  giftQueue = []
  destroyActiveScene()
  document.documentElement.classList.remove('fv-gift-engine-active')
}

function escapeText(value) {
  const node = document.createElement('span')
  node.textContent = String(value ?? '')
  return node.innerHTML
}

function comboLabel(meta) {
  const index = Number(meta?.comboIndex)
  const total = Number(meta?.comboTotal)
  if (!Number.isSafeInteger(index) || !Number.isSafeInteger(total) || total <= 1) return ''
  return ` · combo ×${index}`
}

function buildVideoScene(config, meta) {
  const root = document.createElement('div')
  root.className = 'fv-gift-engine fv-video-gift'
  root.dataset.giftId = config.id
  root.setAttribute('role', 'status')
  root.setAttribute('aria-live', 'polite')

  const video = getGiftVideo(config)
  resetGiftVideo(video)
  video.remove()

  const metaBar = document.createElement('div')
  metaBar.className = 'fv-gift-meta'
  metaBar.innerHTML = `
    <span class="fv-gift-meta-icon" aria-hidden="true">F</span>
    <div>
      <strong>${escapeText(meta.sender || 'Fameverse Creator')}</strong>
      <small>sent ${escapeText(config.label)}${comboLabel(meta)}</small>
    </div>
  `

  root.append(video, metaBar)
  return { root, video, metaBar }
}

function playNextQueuedGift() {
  destroyActiveScene()

  if (!isLiveActive()) {
    giftQueue = []
    document.documentElement.classList.remove('fv-gift-engine-active')
    return
  }

  const next = giftQueue.shift()
  if (!next) {
    document.documentElement.classList.remove('fv-gift-engine-active')
    return
  }

  startGiftScene(next.config, next.meta)
}

function startGiftScene(config, meta) {
  const scene = config.effect === 'video-cinematic'
    ? buildVideoScene(config, meta)
    : null
  if (!scene) return false

  document.documentElement.classList.add('fv-gift-engine-active')
  document.body.appendChild(scene.root)

  const finish = () => {
    if (!activeGift || activeGift.video !== scene.video) return
    playNextQueuedGift()
  }
  const onPlaying = () => scene.root.classList.add('is-playing')

  activeGift = {
    ...scene,
    timer: null,
    id: config.id,
    comboIndex: meta.comboIndex || 1,
    comboTotal: meta.comboTotal || 1,
    onEnded: finish,
    onPlaying,
  }

  scene.video.addEventListener('ended', finish, { once: true })
  scene.video.addEventListener('playing', onPlaying, { once: true })
  activeGift.timer = window.setTimeout(finish, config.duration + 1200)

  const start = scene.video.play()
  start?.catch?.(() => {
    scene.video.muted = true
    scene.video.play().catch(finish)
  })
  return true
}

function buildComboEntries(config, meta, quantity) {
  return Array.from({ length: quantity }, (_, index) => ({
    config,
    meta: {
      ...meta,
      quantity: 1,
      comboIndex: index + 1,
      comboTotal: quantity,
    },
  }))
}

function playGift(giftKey, meta = {}) {
  const config = giftRegistry[giftKey] || Object.values(giftRegistry).find((gift) => gift.id === giftKey)
  if (!config || !isLiveActive()) return false

  const requestedQuantity = Number(meta.quantity)
  const quantity = Number.isSafeInteger(requestedQuantity) && requestedQuantity > 0 ? requestedQuantity : 1
  const entries = buildComboEntries(config, meta, quantity)

  if (activeGift) {
    giftQueue.push(...entries)
    return true
  }

  const first = entries.shift()
  giftQueue.push(...entries)
  return startGiftScene(first.config, first.meta)
}

document.addEventListener('pointerdown', primeGiftMedia, { capture: true, passive: true, once: true })
document.addEventListener('touchstart', primeGiftMedia, { capture: true, passive: true, once: true })

document.addEventListener('fameverse:gift', (event) => {
  const detail = event.detail || {}
  if (detail.id) playGift(detail.id, detail)
})

window.FameverseGiftEngine = Object.freeze({
  play: playGift,
  primeAudio: primeGiftPlayback,
  startAudioSession: startGiftAudioSession,
  stopAudioSession: stopGiftAudioSession,
  registry: giftRegistry,
  stop: stopGiftEngine,
})
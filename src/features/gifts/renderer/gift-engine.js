import '../../../styles/gifts/engine.css'
import {
  CELESTIAL_PHOENIX_VIDEO,
  EMBER_DRAGON_VIDEO,
  GROK_WELCOME_VIDEO,
} from '../../../config/gifts.js'
import {
  primeGiftAudio,
  startGiftAudioSession,
  stopGiftAudioSession,
} from './gift-audio.js'

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
  emberDragon: {
    id: 'ember-dragon',
    label: 'Ember Dragon',
    tier: 'premium',
    duration: 8500,
    cost: 1000,
    video: EMBER_DRAGON_VIDEO,
    effect: 'video-cinematic',
  },
  celestialPhoenix: {
    id: 'celestial-phoenix',
    label: 'Celestial Phoenix',
    tier: 'premium',
    duration: 8000,
    cost: 1000,
    video: CELESTIAL_PHOENIX_VIDEO,
    effect: 'video-cinematic',
  },
})

let activeGift = null
let giftQueue = []
const preparedGiftVideos = new Map()

function isLiveActive() {
  return Boolean(document.querySelector('.fv2-host-live, .mobile-live-shell.is-live, .fv-viewer-live'))
}

function findGiftConfig(giftKey) {
  return giftRegistry[giftKey] || Object.values(giftRegistry).find((gift) => gift.id === giftKey) || null
}

function createPreparedVideo(config) {
  const video = document.createElement('video')
  video.className = 'fv-gift-video'
  video.src = config.video
  video.preload = 'auto'
  video.playsInline = true
  video.autoplay = false
  video.controls = false
  video.loop = false
  video.muted = false
  video.volume = 1
  video.setAttribute('playsinline', '')
  video.setAttribute('webkit-playsinline', '')
  return video
}

function getPreparedVideo(config) {
  let video = preparedGiftVideos.get(config.id)
  if (!video) {
    video = createPreparedVideo(config)
    preparedGiftVideos.set(config.id, video)
  }
  return video
}

function prepareGiftMedia(giftKey) {
  const config = findGiftConfig(giftKey)
  if (!config?.video) return false

  const video = getPreparedVideo(config)
  if (video.readyState < 3) {
    try { video.load() } catch {}
  }
  return true
}

function destroyActiveScene() {
  if (!activeGift) return

  clearTimeout(activeGift.timer)
  if (activeGift.video) {
    activeGift.video.onended = null
    activeGift.video.onplaying = null
    try { activeGift.video.pause() } catch {}
    try { activeGift.video.currentTime = 0 } catch {}
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
  root.style.setProperty('--fv-gift-duration', `${config.duration}ms`)
  root.setAttribute('role', 'status')
  root.setAttribute('aria-live', 'polite')

  const video = getPreparedVideo(config)
  video.className = 'fv-gift-video'
  video.muted = false
  video.volume = 1
  try { video.currentTime = 0 } catch {}

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

  activeGift = {
    ...scene,
    timer: null,
    id: config.id,
    comboIndex: meta.comboIndex || 1,
    comboTotal: meta.comboTotal || 1,
  }

  const finish = () => {
    if (!activeGift || activeGift.video !== scene.video) return
    playNextQueuedGift()
  }

  let playbackStarted = false
  const markPlaybackStarted = () => {
    if (playbackStarted || !activeGift || activeGift.video !== scene.video) return
    playbackStarted = true
    scene.root.classList.add('is-playing')
    clearTimeout(activeGift.timer)
    activeGift.timer = window.setTimeout(finish, config.duration + 1200)
  }

  scene.video.onended = finish
  scene.video.onplaying = markPlaybackStarted

  const start = scene.video.play()
  start?.then?.(markPlaybackStarted).catch?.(() => {
    scene.video.muted = true
    scene.video.play().then(markPlaybackStarted).catch(finish)
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
  const config = findGiftConfig(giftKey)
  if (!config || !isLiveActive()) return false

  prepareGiftMedia(config.id)
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

document.addEventListener('fameverse:gift', (event) => {
  const detail = event.detail || {}
  if (detail.id) playGift(detail.id, detail)
})

window.FameverseGiftEngine = Object.freeze({
  play: playGift,
  prepare: prepareGiftMedia,
  primeAudio: primeGiftAudio,
  startAudioSession: startGiftAudioSession,
  stopAudioSession: stopGiftAudioSession,
  registry: giftRegistry,
  stop: stopGiftEngine,
})

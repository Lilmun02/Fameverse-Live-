import '../../../styles/gifts/engine.css'
import { startPocketCometAnimation } from './pocketComet.js'

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
  pocketComet: {
    id: 'fv_pocket_comet_15',
    label: 'Pocket Comet',
    tier: 'low',
    duration: 4500,
    cost: 15,
    effect: 'canvas-pocket-comet',
  },
})

let activeGift = null
let giftQueue = []

function isLiveActive() {
  return Boolean(document.querySelector('.mobile-live-shell.is-live'))
}

function destroyActiveScene() {
  if (!activeGift) return

  clearTimeout(activeGift.timer)
  activeGift.cancelAnimation?.()
  if (activeGift.video) {
    try { activeGift.video.pause() } catch {}
    activeGift.video.removeAttribute('src')
    try { activeGift.video.load() } catch {}
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

function buildVideoScene(config, meta, quantity) {
  const root = document.createElement('div')
  root.className = 'fv-gift-engine fv-video-gift'
  root.dataset.giftId = config.id
  root.setAttribute('role', 'status')
  root.setAttribute('aria-live', 'polite')

  const video = document.createElement('video')
  video.className = 'fv-gift-video'
  video.src = config.video
  video.preload = 'auto'
  video.playsInline = true
  video.autoplay = false
  video.controls = false
  video.loop = false
  video.muted = false
  video.volume = 0.78
  video.setAttribute('playsinline', '')
  video.setAttribute('webkit-playsinline', '')

  const metaBar = document.createElement('div')
  metaBar.className = 'fv-gift-meta'
  metaBar.innerHTML = `
    <span class="fv-gift-meta-icon" aria-hidden="true">F</span>
    <div>
      <strong>${escapeText(meta.sender || 'Fameverse Creator')}</strong>
      <small>sent ${escapeText(config.label)}${quantity > 1 ? ` · ×${quantity}` : ''}</small>
    </div>
  `

  root.append(video, metaBar)
  return { root, video, metaBar }
}

function buildPocketCometScene(config) {
  const root = document.createElement('div')
  root.className = 'fv-gift-engine fv-canvas-gift'
  root.dataset.giftId = config.id
  root.setAttribute('role', 'status')
  root.setAttribute('aria-label', 'Pocket Comet gift animation')
  root.style.animationDuration = `${config.duration}ms`

  const canvas = document.createElement('canvas')
  canvas.className = 'fv-gift-canvas'
  root.append(canvas)

  return {
    root,
    canvas,
    start: () => startPocketCometAnimation(canvas, config.duration),
  }
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

  startGiftScene(next.config, next.meta, next.quantity)
}

function startGiftScene(config, meta, quantity) {
  const scene = config.effect === 'video-cinematic'
    ? buildVideoScene(config, meta, quantity)
    : config.effect === 'canvas-pocket-comet'
      ? buildPocketCometScene(config)
      : null
  if (!scene) return false

  document.documentElement.classList.add('fv-gift-engine-active')
  document.body.appendChild(scene.root)

  activeGift = {
    ...scene,
    timer: null,
    id: config.id,
    quantity,
    cancelAnimation: scene.start?.() || null,
  }

  const finish = () => {
    if (!activeGift || activeGift.root !== scene.root) return
    playNextQueuedGift()
  }

  activeGift.timer = window.setTimeout(finish, config.duration + (scene.video ? 1200 : 120))

  if (scene.video) {
    scene.video.addEventListener('ended', finish, { once: true })
    const start = scene.video.play()
    start?.catch?.(() => {
      scene.video.muted = true
      scene.video.play().catch(finish)
    })
  }
  return true
}

function playGift(giftKey, meta = {}) {
  const config = giftRegistry[giftKey] || Object.values(giftRegistry).find((gift) => gift.id === giftKey)
  if (!config || !isLiveActive()) return false

  const requestedQuantity = Number(meta.quantity)
  const quantity = Number.isSafeInteger(requestedQuantity) && requestedQuantity > 0 ? requestedQuantity : 1

  if (activeGift) {
    giftQueue.push({ config, meta, quantity })
    return true
  }

  return startGiftScene(config, meta, quantity)
}

document.addEventListener('fameverse:gift', (event) => {
  const detail = event.detail || {}
  if (detail.id) playGift(detail.id, detail)
})

window.FameverseGiftEngine = Object.freeze({
  play: playGift,
  registry: giftRegistry,
  stop: stopGiftEngine,
})

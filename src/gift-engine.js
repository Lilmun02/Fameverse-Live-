import './gift-engine.css'

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
let lastGift = { id: null, at: 0, count: 0 }

function isLiveActive() {
  return Boolean(document.querySelector('.mobile-live-shell.is-live'))
}

function cleanupActiveGift() {
  if (!activeGift) return

  clearTimeout(activeGift.timer)
  if (activeGift.video) {
    try { activeGift.video.pause() } catch {}
    activeGift.video.removeAttribute('src')
    try { activeGift.video.load() } catch {}
  }
  activeGift.root?.remove()
  activeGift = null
  document.documentElement.classList.remove('fv-gift-engine-active')
}

function escapeText(value) {
  const node = document.createElement('span')
  node.textContent = String(value ?? '')
  return node.innerHTML
}

function buildVideoScene(config, meta, comboCount) {
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
      <small>sent ${escapeText(config.label)}${comboCount > 1 ? ` · ×${comboCount}` : ''}</small>
    </div>
  `

  video.addEventListener('ended', cleanupActiveGift, { once: true })
  root.append(video, metaBar)
  return { root, video }
}

function playGift(giftKey, meta = {}) {
  const config = giftRegistry[giftKey] || Object.values(giftRegistry).find((gift) => gift.id === giftKey)
  if (!config || !isLiveActive()) return false

  const now = performance.now()
  const fallbackCombo = lastGift.id === config.id && now - lastGift.at < 2200 ? lastGift.count + 1 : 1
  const requestedCombo = Number(meta.comboCount)
  const comboCount = Number.isFinite(requestedCombo) && requestedCombo > 0 ? requestedCombo : fallbackCombo
  lastGift = { id: config.id, at: now, count: comboCount }

  cleanupActiveGift()

  const scene = config.effect === 'video-cinematic'
    ? buildVideoScene(config, meta, comboCount)
    : null
  if (!scene) return false

  document.documentElement.classList.add('fv-gift-engine-active')
  document.body.appendChild(scene.root)

  const timer = window.setTimeout(cleanupActiveGift, config.duration)
  activeGift = { ...scene, timer, id: config.id }

  const start = scene.video.play()
  start?.catch?.(() => {
    scene.video.muted = true
    scene.video.play().catch(() => cleanupActiveGift())
  })
  return true
}

document.addEventListener('fameverse:gift', (event) => {
  const detail = event.detail || {}
  if (detail.id) playGift(detail.id, detail)
})

window.FameverseGiftEngine = Object.freeze({
  play: playGift,
  registry: giftRegistry,
  stop: cleanupActiveGift,
})

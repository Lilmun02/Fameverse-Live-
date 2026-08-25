import './gift-engine.css'

const giftRegistry = Object.freeze({
  farmhouseWelcome: {
    id: 'farmhouse-welcome',
    label: 'Farmhouse Welcome',
    tier: 'medium',
    duration: 4200,
    art: '/gifts/farmhouse-welcome.svg',
    effect: 'farmhouse-welcome',
    sound: 'welcome-chime',
  },
})

let activeGift = null
let lastGift = { id: null, at: 0, count: 0 }
let previewObserver = null

function cleanupActiveGift() {
  if (!activeGift) return
  clearTimeout(activeGift.timer)
  activeGift.stopAudio?.()
  activeGift.root?.remove()
  activeGift = null
  document.documentElement.classList.remove('fv-gift-engine-active')
}

function makeParticles(count = 18) {
  return Array.from({ length: count }, (_, index) => {
    const particle = document.createElement('i')
    particle.className = 'fv-gift-particle'
    particle.style.setProperty('--fv-x', `${8 + ((index * 37) % 84)}%`)
    particle.style.setProperty('--fv-y', `${14 + ((index * 29) % 68)}%`)
    particle.style.setProperty('--fv-delay', `${(index % 7) * 90}ms`)
    particle.style.setProperty('--fv-size', `${5 + (index % 4) * 2}px`)
    return particle
  })
}

function buildFarmhouseScene(config, meta, comboCount) {
  const root = document.createElement('div')
  root.className = 'fv-gift-engine'
  root.dataset.giftId = config.id
  root.setAttribute('role', 'status')
  root.setAttribute('aria-live', 'polite')

  const reducedMotion = window.matchMedia?.('(prefers-reduced-motion: reduce)').matches
  if (reducedMotion) root.classList.add('fv-reduced-motion')

  const scene = document.createElement('div')
  scene.className = 'fv-farmhouse-scene'

  const glow = document.createElement('div')
  glow.className = 'fv-farmhouse-glow'

  const art = document.createElement('img')
  art.className = 'fv-farmhouse-art'
  art.src = config.art
  art.alt = ''
  art.decoding = 'async'
  art.draggable = false

  const host = document.createElement('div')
  host.className = 'fv-welcome-host'
  host.innerHTML = '<span class="fv-host-head"></span><span class="fv-host-body"></span><span class="fv-host-arm"></span>'

  const message = document.createElement('div')
  message.className = 'fv-welcome-copy'
  message.innerHTML = `
    <span class="fv-welcome-kicker">FAMEVERSE GIFT</span>
    <strong>WELCOME TO FAMEVERSE</strong>
    <small>${escapeText(meta.sender || 'Fameverse Creator')}${comboCount > 1 ? ` · COMBO ×${comboCount}` : ''}</small>
  `

  const floorGlow = document.createElement('div')
  floorGlow.className = 'fv-floor-glow'

  scene.append(glow, floorGlow, art, host, message, ...makeParticles(reducedMotion ? 8 : 20))
  root.append(scene)
  return root
}

function escapeText(value) {
  const node = document.createElement('span')
  node.textContent = String(value ?? '')
  return node.innerHTML
}

function playWelcomeChime() {
  const AudioContextClass = window.AudioContext || window.webkitAudioContext
  if (!AudioContextClass) return () => {}

  let context
  const nodes = []
  let closeTimer

  try {
    context = new AudioContextClass()
    context.resume?.().catch?.(() => {})

    const master = context.createGain()
    master.gain.setValueAtTime(0.0001, context.currentTime)
    master.gain.exponentialRampToValueAtTime(0.18, context.currentTime + 0.025)
    master.gain.exponentialRampToValueAtTime(0.0001, context.currentTime + 1.15)
    master.connect(context.destination)
    nodes.push(master)

    const notes = [392, 523.25, 659.25]
    notes.forEach((frequency, index) => {
      const oscillator = context.createOscillator()
      const gain = context.createGain()
      const start = context.currentTime + index * 0.12
      const end = start + 0.62

      oscillator.type = index === 0 ? 'triangle' : 'sine'
      oscillator.frequency.setValueAtTime(frequency, start)
      gain.gain.setValueAtTime(0.0001, start)
      gain.gain.exponentialRampToValueAtTime(index === 0 ? 0.38 : 0.24, start + 0.02)
      gain.gain.exponentialRampToValueAtTime(0.0001, end)
      oscillator.connect(gain)
      gain.connect(master)
      oscillator.start(start)
      oscillator.stop(end)
      nodes.push(oscillator, gain)
    })

    const sweep = context.createOscillator()
    const sweepGain = context.createGain()
    sweep.type = 'sine'
    sweep.frequency.setValueAtTime(170, context.currentTime)
    sweep.frequency.exponentialRampToValueAtTime(520, context.currentTime + 0.42)
    sweepGain.gain.setValueAtTime(0.0001, context.currentTime)
    sweepGain.gain.exponentialRampToValueAtTime(0.12, context.currentTime + 0.04)
    sweepGain.gain.exponentialRampToValueAtTime(0.0001, context.currentTime + 0.48)
    sweep.connect(sweepGain)
    sweepGain.connect(master)
    sweep.start()
    sweep.stop(context.currentTime + 0.5)
    nodes.push(sweep, sweepGain)

    closeTimer = window.setTimeout(() => {
      context?.close?.().catch?.(() => {})
      context = null
    }, 1500)
  } catch {
    context?.close?.().catch?.(() => {})
    context = null
  }

  return () => {
    clearTimeout(closeTimer)
    nodes.forEach((node) => {
      try { node.disconnect?.() } catch {}
      try { node.stop?.() } catch {}
    })
    context?.close?.().catch?.(() => {})
    context = null
  }
}

function playGift(giftKey, meta = {}) {
  const config = giftRegistry[giftKey] || Object.values(giftRegistry).find((gift) => gift.id === giftKey)
  if (!config) return false

  const now = performance.now()
  const comboCount = lastGift.id === config.id && now - lastGift.at < 2200 ? lastGift.count + 1 : 1
  lastGift = { id: config.id, at: now, count: comboCount }

  cleanupActiveGift()

  const root = config.effect === 'farmhouse-welcome'
    ? buildFarmhouseScene(config, meta, comboCount)
    : null
  if (!root) return false

  document.documentElement.classList.add('fv-gift-engine-active')
  document.body.appendChild(root)

  const stopAudio = config.sound === 'welcome-chime' ? playWelcomeChime() : () => {}
  const timer = window.setTimeout(cleanupActiveGift, config.duration)
  activeGift = { root, timer, stopAudio, id: config.id }
  return true
}

function addPreviewGiftButton() {
  const grid = document.querySelector('.live-gift-grid')
  if (!grid || grid.querySelector('[data-fv-gift-preview]')) return

  const button = document.createElement('button')
  button.type = 'button'
  button.className = 'live-gift-item fv-gift-preview-item'
  button.dataset.fvGiftPreview = 'farmhouseWelcome'
  button.setAttribute('aria-label', 'Preview Farmhouse Welcome gift engine')
  button.innerHTML = '<span>🏡</span><strong>Farmhouse</strong><small>ENGINE TEST</small>'
  button.addEventListener('click', (event) => {
    event.preventDefault()
    event.stopPropagation()
    playGift('farmhouseWelcome', { sender: 'Engine Preview' })
  })
  grid.appendChild(button)
}

function schedulePreviewButton() {
  requestAnimationFrame(addPreviewGiftButton)
}

function startPreviewObserver() {
  if (previewObserver || !document.body) return
  previewObserver = new MutationObserver(schedulePreviewButton)
  previewObserver.observe(document.body, { childList: true, subtree: true })
  schedulePreviewButton()
}

document.addEventListener('fameverse:gift', (event) => {
  const detail = event.detail || {}
  if (detail.id) playGift(detail.id, detail)
})

document.addEventListener('DOMContentLoaded', startPreviewObserver, { once: true })
if (document.readyState !== 'loading') startPreviewObserver()

window.FameverseGiftEngine = Object.freeze({
  play: playGift,
  registry: giftRegistry,
  stop: cleanupActiveGift,
})

let audioContext = null
let primeInstalled = false
let keepAliveSource = null
let keepAliveGain = null
let sessionActive = false

function getAudioContext() {
  if (audioContext) return audioContext
  const AudioContextClass = window.AudioContext || window.webkitAudioContext
  if (!AudioContextClass) return null
  audioContext = new AudioContextClass()
  return audioContext
}

function playUnlockPulse(context) {
  try {
    const buffer = context.createBuffer(1, 1, context.sampleRate)
    const source = context.createBufferSource()
    const gain = context.createGain()
    gain.gain.value = 0.00001
    source.buffer = buffer
    source.connect(gain)
    gain.connect(context.destination)
    source.start(0)
  } catch {
    // Some mobile browsers do not need or expose a warm-up buffer.
  }
}

function ensureKeepAlive(context) {
  if (keepAliveSource || !sessionActive || context.state !== 'running') return
  try {
    const source = context.createConstantSource()
    const gain = context.createGain()
    source.offset.value = 0
    gain.gain.value = 0.000001
    source.connect(gain)
    gain.connect(context.destination)
    source.start()
    keepAliveSource = source
    keepAliveGain = gain
  } catch {
    // ConstantSource is a best-effort keep-alive for unlocked gift-video audio.
  }
}

export function primeGiftAudio() {
  const context = getAudioContext()
  if (!context) return false

  const warm = () => {
    playUnlockPulse(context)
    ensureKeepAlive(context)
    return context.state === 'running'
  }

  if (context.state === 'running') return warm()

  try {
    const resume = context.resume()
    resume?.then?.(warm).catch(() => {})
  } catch {
    return false
  }

  return true
}

export function startGiftAudioSession() {
  sessionActive = true
  return primeGiftAudio()
}

export function stopGiftAudioSession() {
  sessionActive = false
  try { keepAliveSource?.stop?.() } catch {}
  try { keepAliveSource?.disconnect?.() } catch {}
  try { keepAliveGain?.disconnect?.() } catch {}
  keepAliveSource = null
  keepAliveGain = null
}

function installPrimeListeners() {
  if (primeInstalled) return
  primeInstalled = true

  const prime = () => primeGiftAudio()
  document.addEventListener('pointerdown', prime, { capture: true, passive: true })
  document.addEventListener('touchstart', prime, { capture: true, passive: true })
  document.addEventListener('keydown', prime, { capture: true })
}

installPrimeListeners()

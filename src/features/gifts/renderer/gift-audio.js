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
    // ConstantSource is a best-effort keep-alive. Chime playback still has its normal path.
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

function scheduleTone(context, destination, frequency, startAt, duration, gainValue) {
  const oscillator = context.createOscillator()
  const gain = context.createGain()

  oscillator.type = 'sine'
  oscillator.frequency.setValueAtTime(frequency, startAt)
  oscillator.frequency.exponentialRampToValueAtTime(frequency * 1.08, startAt + duration)

  gain.gain.setValueAtTime(0.0001, startAt)
  gain.gain.exponentialRampToValueAtTime(gainValue, startAt + 0.025)
  gain.gain.exponentialRampToValueAtTime(0.0001, startAt + duration)

  oscillator.connect(gain)
  gain.connect(destination)
  oscillator.start(startAt)
  oscillator.stop(startAt + duration + 0.02)
}

function playUnlockedChime(context) {
  if (context.state !== 'running') return false

  ensureKeepAlive(context)
  const now = context.currentTime + 0.015
  const master = context.createGain()
  master.gain.setValueAtTime(0.92, now)
  master.connect(context.destination)

  scheduleTone(context, master, 392.0, now, 0.36, 0.18)
  scheduleTone(context, master, 523.25, now + 0.07, 0.42, 0.20)
  scheduleTone(context, master, 659.25, now + 0.16, 0.48, 0.18)
  scheduleTone(context, master, 783.99, now + 0.28, 0.52, 0.15)

  window.setTimeout(() => {
    try { master.disconnect() } catch {}
  }, 1100)
  return true
}

export function playGiftChime() {
  const context = getAudioContext()
  if (!context) return false

  if (context.state === 'running') return playUnlockedChime(context)

  try {
    const resume = context.resume()
    resume?.then?.(() => playUnlockedChime(context)).catch(() => {})
  } catch {
    return false
  }

  return false
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

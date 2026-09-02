let audioContext = null
let primeInstalled = false

function getAudioContext() {
  if (audioContext) return audioContext
  const AudioContextClass = window.AudioContext || window.webkitAudioContext
  if (!AudioContextClass) return null
  audioContext = new AudioContextClass()
  return audioContext
}

export function primeGiftAudio() {
  const context = getAudioContext()
  if (!context) return false

  if (context.state === 'suspended') {
    void context.resume().catch(() => {})
  }

  return true
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

export function playGiftChime() {
  const context = getAudioContext()
  if (!context) return false

  const play = () => {
    if (context.state !== 'running') return false
    const now = context.currentTime + 0.015
    const master = context.createGain()
    master.gain.setValueAtTime(0.86, now)
    master.connect(context.destination)

    scheduleTone(context, master, 523.25, now, 0.34, 0.048)
    scheduleTone(context, master, 659.25, now + 0.08, 0.4, 0.044)
    scheduleTone(context, master, 783.99, now + 0.17, 0.48, 0.036)

    window.setTimeout(() => {
      try { master.disconnect() } catch {}
    }, 900)
    return true
  }

  if (context.state === 'running') return play()
  void context.resume().then(play).catch(() => {})
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

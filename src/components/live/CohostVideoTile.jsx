import { useEffect, useRef } from 'react'

const COHOST_RETURN_VOLUME = 0.32
const FEEDBACK_MUTE_MS = 1400

export default function CohostVideoTile({
  stream,
  label = 'Co-host',
  local = false,
  audioReturnStream = null,
}) {
  const videoRef = useRef(null)
  const audioRef = useRef(null)

  useEffect(() => {
    const video = videoRef.current
    if (!video) return
    video.srcObject = stream || null
    if (stream) void video.play().catch(() => {})
    return () => {
      if (video.srcObject === stream) video.srcObject = null
    }
  }, [stream])

  useEffect(() => {
    const audio = audioRef.current
    if (!audio) return undefined

    audio.srcObject = audioReturnStream || null
    audio.volume = COHOST_RETURN_VOLUME
    if (audioReturnStream) void audio.play().catch(() => {})
    if (!audioReturnStream || typeof AudioContext === 'undefined') {
      return () => {
        if (audio.srcObject === audioReturnStream) audio.srcObject = null
      }
    }

    let context = null
    let analyser = null
    let frame = 0
    let hotFrames = 0
    let mutedUntil = 0

    try {
      context = new AudioContext()
      const source = context.createMediaStreamSource(audioReturnStream)
      analyser = context.createAnalyser()
      analyser.fftSize = 2048
      analyser.smoothingTimeConstant = 0.7
      source.connect(analyser)
      void context.resume().catch(() => {})
    } catch {
      context = null
      analyser = null
    }

    const frequencyData = analyser ? new Uint8Array(analyser.frequencyBinCount) : null
    const scan = () => {
      if (!analyser || !frequencyData) return
      analyser.getByteFrequencyData(frequencyData)

      const nyquist = (context?.sampleRate || 44100) / 2
      const firstBin = Math.max(1, Math.floor((300 / nyquist) * frequencyData.length))
      const lastBin = Math.min(frequencyData.length - 1, Math.ceil((5000 / nyquist) * frequencyData.length))
      let peak = 0
      let sum = 0
      let count = 0

      for (let index = firstBin; index <= lastBin; index += 1) {
        const value = frequencyData[index]
        peak = Math.max(peak, value)
        sum += value
        count += 1
      }

      const average = count ? sum / count : 0
      const feedbackLike = peak >= 205 && peak - average >= 82
      hotFrames = feedbackLike ? hotFrames + 1 : Math.max(0, hotFrames - 2)

      const now = Date.now()
      if (hotFrames >= 7) {
        audio.volume = 0
        mutedUntil = now + FEEDBACK_MUTE_MS
        hotFrames = 0
      } else if (audio.volume === 0 && now >= mutedUntil) {
        audio.volume = COHOST_RETURN_VOLUME
      }

      frame = window.requestAnimationFrame(scan)
    }

    if (analyser) frame = window.requestAnimationFrame(scan)

    return () => {
      if (frame) window.cancelAnimationFrame(frame)
      if (audio.srcObject === audioReturnStream) audio.srcObject = null
      void context?.close?.().catch?.(() => {})
    }
  }, [audioReturnStream])

  if (!stream) return null

  return (
    <div className={`fv-cohost-video-tile ${local ? 'is-local' : ''}`}>
      <video ref={videoRef} autoPlay playsInline muted={local} />
      {local && audioReturnStream && <audio ref={audioRef} autoPlay />}
      <span>{local ? 'You · Co-host' : label}</span>
    </div>
  )
}

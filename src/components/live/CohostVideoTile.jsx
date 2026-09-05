import { useEffect, useRef } from 'react'

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
    if (!audio) return
    audio.srcObject = audioReturnStream || null
    audio.volume = 0.65
    if (audioReturnStream) void audio.play().catch(() => {})
    return () => {
      if (audio.srcObject === audioReturnStream) audio.srcObject = null
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

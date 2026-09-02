import { useEffect, useRef } from 'react'

export default function CohostVideoTile({ stream, label = 'Co-host', local = false }) {
  const videoRef = useRef(null)

  useEffect(() => {
    const video = videoRef.current
    if (!video) return
    video.srcObject = stream || null
    if (stream) void video.play().catch(() => {})
    return () => {
      if (video.srcObject === stream) video.srcObject = null
    }
  }, [stream])

  if (!stream) return null

  return (
    <div className={`fv-cohost-video-tile ${local ? 'is-local' : ''}`}>
      <video ref={videoRef} autoPlay playsInline muted={local} />
      <span>{local ? 'You · Co-host' : label}</span>
    </div>
  )
}

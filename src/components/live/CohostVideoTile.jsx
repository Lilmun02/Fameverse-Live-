import { useEffect, useRef } from 'react'

export default function CohostVideoTile({
  stream,
  label = 'Co-host',
  local = false,
}) {
  const videoRef = useRef(null)

  useEffect(() => {
    const video = videoRef.current
    if (!video) return undefined

    video.srcObject = stream || null
    video.muted = Boolean(local)
    video.defaultMuted = Boolean(local)
    video.volume = local ? 0 : 1

    if (stream) void video.play().catch(() => {})

    return () => {
      if (video.srcObject === stream) video.srcObject = null
    }
  }, [local, stream])

  if (!stream) return null

  return (
    <div className={`fv-cohost-video-tile ${local ? 'is-local' : ''}`}>
      <video ref={videoRef} autoPlay playsInline muted={local} />
      <span>{local ? 'You · Co-host' : label}</span>
    </div>
  )
}

import { useEffect, useRef, useState } from 'react'
import { useLiveTapTotals } from '../../hooks/useLiveTapTotals.js'
import { useLiveViewer } from '../../hooks/useLiveViewer.js'
import { useViewerTapCapture } from '../../hooks/useViewerTapCapture.js'

export default function ViewerLiveScreen({ room, onClose }) {
  const videoRef = useRef(null)
  const [needsPlay, setNeedsPlay] = useState(false)
  const relay = useLiveViewer({ roomId: room?.id, enabled: Boolean(room?.id) })
  const totals = useLiveTapTotals({ roomId: room?.id })
  const capture = useViewerTapCapture({ roomId: room?.id })
  const hostLabel = room?.host?.username
    ? `@${room.host.username}`
    : room?.host?.displayName || 'Fameverse creator'
  const serverTotal = Math.max(totals.rawTaps, Number(capture.lastResult?.totalRawTaps || 0))
  const ended = relay.state === 'ended' || capture.lastResult?.reasons?.includes('inactive_live_session')

  useEffect(() => {
    const video = videoRef.current
    if (!video) return
    video.srcObject = relay.remoteStream || null
    if (!relay.remoteStream) {
      setNeedsPlay(false)
      return
    }

    video.play()
      .then(() => setNeedsPlay(false))
      .catch(() => setNeedsPlay(true))
  }, [relay.remoteStream])

  const playVideo = () => {
    videoRef.current?.play?.()
      .then(() => setNeedsPlay(false))
      .catch(() => setNeedsPlay(true))
  }

  const onTap = (event) => {
    if (event.pointerType === 'mouse' && event.button !== 0) return
    if (relay.state !== 'connected' || ended) return
    playVideo()
    capture.tap()
  }

  return (
    <section className="fv-viewer-live" aria-label={`Watching ${hostLabel} live`}>
      <div className="fv-viewer-live-stage" onPointerDown={onTap}>
        <video ref={videoRef} autoPlay playsInline className="fv-viewer-live-video" />

        {!relay.remoteStream && !ended && (
          <div className="fv-viewer-live-connecting" aria-live="polite">
            <span className="fv-viewer-live-pulse" aria-hidden="true" />
            <strong>{relay.state === 'degraded' ? 'Reconnecting…' : 'Connecting to Live…'}</strong>
            <small>Opening the creator’s live camera and audio.</small>
          </div>
        )}

        {ended && (
          <div className="fv-viewer-live-ended">
            <strong>This Live ended</strong>
            <small>Return to Discover to find another live creator.</small>
            <button type="button" onPointerDown={(event) => event.stopPropagation()} onClick={onClose}>Back to Discover</button>
          </div>
        )}

        {needsPlay && !ended && (
          <button
            type="button"
            className="fv-viewer-live-play"
            onPointerDown={(event) => event.stopPropagation()}
            onClick={playVideo}
          >
            Tap to play Live
          </button>
        )}

        <header className="fv-viewer-live-header" onPointerDown={(event) => event.stopPropagation()}>
          <button type="button" className="fv-viewer-live-back" onClick={onClose} aria-label="Back to Discover">‹</button>
          <div className="fv-viewer-live-identity">
            <span>LIVE</span>
            <strong>{room?.title || 'Live session'}</strong>
            <small>{hostLabel}</small>
          </div>
          <b className="fv-viewer-live-total">♥ {serverTotal}</b>
        </header>

        {!ended && (
          <div className="fv-viewer-live-tap-hud" aria-live="polite">
            <span>♥</span>
            <strong>{capture.localTapCount}</strong>
            <small>{capture.localTapCount === 1 ? 'Fame Tap' : 'Fame Taps'}</small>
          </div>
        )}
      </div>
    </section>
  )
}

import { useEffect, useMemo, useState } from 'react'
import { isPrivilegedIdentityRole } from '../../services/accountRoles.js'
import { loadLiveViewerIdentityStats } from '../../services/live/viewerIdentityStats.js'
import GifterBadge from '../profile/GifterBadge.jsx'

function stopLiveTap(event) {
  event.stopPropagation()
}

function initialFor(name) {
  return String(name || 'F').trim().charAt(0).toUpperCase() || 'F'
}

export default function LiveViewerSheet({
  open,
  onClose,
  roomId = null,
  viewers = [],
  onOpenIdentity,
}) {
  const [stats, setStats] = useState([])
  const [status, setStatus] = useState('idle')

  const roster = useMemo(() => {
    const seen = new Set()
    return viewers
      .filter((viewer) => viewer?.userId && !seen.has(viewer.userId) && seen.add(viewer.userId))
      .slice(0, 200)
  }, [viewers])

  useEffect(() => {
    if (!open) {
      setStatus('idle')
      return undefined
    }

    if (!roster.length) {
      setStats([])
      setStatus('ready')
      return undefined
    }

    let active = true
    setStatus('loading')
    loadLiveViewerIdentityStats(roomId, roster.map((viewer) => viewer.userId))
      .then((rows) => {
        if (!active) return
        setStats(rows)
        setStatus('ready')
      })
      .catch(() => {
        if (!active) return
        setStats([])
        setStatus('error')
      })

    return () => {
      active = false
    }
  }, [open, roomId, roster])

  if (!open) return null

  const statsByUser = new Map(stats.map((row) => [row.userId, row]))
  const rows = roster.map((viewer) => ({
    ...viewer,
    ...(statsByUser.get(viewer.userId) || {}),
  }))

  const openIdentity = (userId) => {
    if (!userId) return
    onClose?.()
    onOpenIdentity?.(userId)
  }

  return (
    <div className="live-sheet-backdrop fv-viewers-backdrop" onPointerDown={stopLiveTap} onClick={onClose}>
      <section className="live-sheet fv-viewers-sheet" role="dialog" aria-modal="true" aria-label="Live viewers" onClick={stopLiveTap} onPointerDown={stopLiveTap}>
        <div className="sheet-handle" aria-hidden="true" />
        <div className="sheet-heading">
          <div><span>VIEWERS</span><strong>{roster.length} watching</strong></div>
          <button type="button" onClick={onClose}>Close</button>
        </div>

        {status === 'loading' && <p className="fv-viewers-status">Loading viewer activity…</p>}
        {status === 'error' && <p className="fv-viewers-status">Viewer activity is reconnecting.</p>}
        {status === 'ready' && rows.length === 0 && <p className="fv-viewers-status">No viewers are connected right now.</p>}

        <div className="fv-viewers-list">
          {rows.map((viewer) => {
            const displayName = viewer.displayName || 'Fameverse viewer'
            const level = Math.min(99, Math.max(1, Number(viewer.gifterLevel || 1)))
            const totalCoinsSent = Math.max(0, Number(viewer.totalCoinsSent || 0))
            const hideBadge = isPrivilegedIdentityRole(viewer.accountRole)
            return (
              <button type="button" className="fv-viewer-row" key={viewer.userId} onClick={() => openIdentity(viewer.userId)}>
                {viewer.avatarUrl ? (
                  <img className="fv-viewer-row-avatar" src={viewer.avatarUrl} alt="" />
                ) : (
                  <span className="fv-viewer-row-avatar is-fallback">{initialFor(displayName)}</span>
                )}
                <span className="fv-viewer-row-copy">
                  <span className="fv-viewer-row-name">
                    <strong>{displayName}</strong>
                    {totalCoinsSent > 0 && !hideBadge && (
                      <GifterBadge level={level} size="small" showLevel={false} totalCoinsSent={totalCoinsSent} />
                    )}
                    <span className="fv-viewer-level">Lv. {level}</span>
                  </span>
                  <small>{Math.max(0, Number(viewer.roomGiftCount || 0)).toLocaleString()} gifts · {Math.max(0, Number(viewer.roomFameTaps || 0)).toLocaleString()} FameTaps</small>
                </span>
                <span className="fv-viewer-row-chevron" aria-hidden="true">›</span>
              </button>
            )
          })}
        </div>
      </section>
    </div>
  )
}

import { useEffect, useRef, useState } from 'react'

const MAX_POSTER_RETRIES = 2
const posterPreloadCache = new Map()

function retryUrl(url, attempt) {
  if (!attempt) return url
  const joiner = url.includes('?') ? '&' : '?'
  return `${url}${joiner}fv_retry=${attempt}`
}

function isVideoSource(url = '') {
  return /\.mp4(?:$|\?)/i.test(url)
}

export function primeGiftPosters(giftList = []) {
  if (typeof Image === 'undefined') return
  for (const gift of giftList) {
    if (!gift?.poster || isVideoSource(gift.poster) || posterPreloadCache.has(gift.poster)) continue
    const image = new Image()
    image.decoding = 'async'
    image.src = gift.poster
    posterPreloadCache.set(gift.poster, image)
  }
}

export default function GiftVisual({ gift, className = '' }) {
  const [posterReady, setPosterReady] = useState(false)
  const [posterAttempt, setPosterAttempt] = useState(0)
  const retryTimer = useRef(null)

  useEffect(() => {
    setPosterReady(false)
    setPosterAttempt(0)
    return () => {
      if (retryTimer.current) clearTimeout(retryTimer.current)
    }
  }, [gift?.poster])

  if (!gift?.poster) {
    return <span className={className} aria-hidden="true">{gift?.emoji || gift?.activityEmoji || '✦'}</span>
  }

  const src = retryUrl(gift.poster, posterAttempt)

  if (isVideoSource(gift.poster)) {
    return (
      <span className={`fv-gift-poster-shell ${className} ${posterReady ? 'is-ready' : ''}`} aria-hidden="true">
        <video
          src={src}
          muted
          playsInline
          preload="metadata"
          draggable="false"
          onLoadedData={(event) => {
            const target = event.currentTarget
            const thumbnailTime = Math.max(0, Number(gift?.thumbnailTime || 0))
            if (thumbnailTime > 0 && Number.isFinite(target.duration) && target.duration > thumbnailTime) {
              try { target.currentTime = thumbnailTime } catch {}
            } else {
              setPosterReady(true)
            }
          }}
          onSeeked={() => setPosterReady(true)}
          onError={() => {
            setPosterReady(false)
            if (posterAttempt >= MAX_POSTER_RETRIES) return
            if (retryTimer.current) clearTimeout(retryTimer.current)
            retryTimer.current = setTimeout(() => {
              setPosterAttempt((attempt) => Math.min(MAX_POSTER_RETRIES, attempt + 1))
            }, 180)
          }}
        />
      </span>
    )
  }

  return (
    <span className={`fv-gift-poster-shell ${className} ${posterReady ? 'is-ready' : ''}`} aria-hidden="true">
      <img
        src={src}
        alt=""
        decoding="async"
        draggable="false"
        onLoad={() => setPosterReady(true)}
        onError={() => {
          setPosterReady(false)
          if (posterAttempt >= MAX_POSTER_RETRIES) return
          if (retryTimer.current) clearTimeout(retryTimer.current)
          retryTimer.current = setTimeout(() => {
            setPosterAttempt((attempt) => Math.min(MAX_POSTER_RETRIES, attempt + 1))
          }, 180)
        }}
      />
    </span>
  )
}

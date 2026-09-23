import { useEffect, useRef, useState } from 'react'
import { seekGiftThumbnail } from '../../utils/media.js'

const MAX_POSTER_RETRIES = 2
const posterPreloadCache = new Map()

function retryUrl(url, attempt) {
  if (!attempt) return url
  const joiner = url.includes('?') ? '&' : '?'
  return `${url}${joiner}fv_retry=${attempt}`
}

export function primeGiftPosters(giftList = []) {
  if (typeof Image === 'undefined') return
  for (const gift of giftList) {
    if (!gift?.poster || posterPreloadCache.has(gift.poster)) continue
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
  }, [gift?.poster, gift?.video])

  if (!gift?.poster && gift?.video) {
    return (
      <span
        className={`fv-gift-video-shell ${className}`}
        aria-hidden="true"
        style={{ display: 'inline-block', overflow: 'hidden' }}
      >
        <video
          src={`${gift.video}#t=${gift.thumbnailTime || 0}`}
          muted
          playsInline
          preload="metadata"
          onLoadedMetadata={(event) => seekGiftThumbnail(event, gift.thumbnailTime)}
          style={{ width: '100%', height: '100%', objectFit: 'cover', display: 'block' }}
        />
      </span>
    )
  }

  if (!gift?.poster) {
    return <span className={className} aria-hidden="true">{gift?.emoji || gift?.activityEmoji || '✦'}</span>
  }

  const src = retryUrl(gift.poster, posterAttempt)

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

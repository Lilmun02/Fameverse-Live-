import { useEffect, useRef, useState } from 'react'

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
  const imageRef = useRef(null)

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
  const fallbackGlyph = gift?.activityEmoji || gift?.emoji || 'F'

  useEffect(() => {
    const image = imageRef.current
    if (image?.complete && image.naturalWidth > 0) setPosterReady(true)
  }, [src])

  return (
    <span className={`fv-gift-poster-shell ${className} ${posterReady ? 'is-ready' : ''}`} aria-hidden="true">
      <span className="fv-gift-poster-fallback">{fallbackGlyph}</span>
      <img
        ref={imageRef}
        src={src}
        alt=""
        decoding="async"
        draggable="false"
        onLoad={(event) => {
          if (event.currentTarget.naturalWidth > 0) setPosterReady(true)
        }}
        onError={() => {
          setPosterReady(false)
          if (posterAttempt >= MAX_POSTER_RETRIES) return
          if (retryTimer.current) clearTimeout(retryTimer.current)
          retryTimer.current = setTimeout(() => {
            setPosterAttempt((attempt) => Math.min(MAX_POSTER_RETRIES, attempt + 1))
          }, 180)
        }}
      />
      {gift?.rendererId && <span className="fv-gift-poster-brand">F</span>}
    </span>
  )
}

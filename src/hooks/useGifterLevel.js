import { useCallback, useEffect, useRef, useState } from 'react'
import { computeGifterLevel, loadGifterStats, recordBetaGift } from '../services/gifterLevels.js'

const EMPTY_STATS = Object.freeze({ totalCoinsSent: 0, giftCount: 0, level: 1 })

export function useGifterLevel({ userId, roomId, setToast }) {
  const [stats, setStats] = useState(EMPTY_STATS)
  const statsRef = useRef(EMPTY_STATS)

  const applyStats = useCallback((next) => {
    const normalized = {
      totalCoinsSent: Number(next?.totalCoinsSent || 0),
      giftCount: Number(next?.giftCount || 0),
      level: Math.max(1, Number(next?.level || 1)),
    }
    statsRef.current = normalized
    setStats(normalized)
    return normalized
  }, [])

  useEffect(() => {
    let active = true
    if (!userId) {
      applyStats(EMPTY_STATS)
      return undefined
    }

    loadGifterStats(userId)
      .then((next) => active && applyStats(next))
      .catch(() => active && applyStats(EMPTY_STATS))

    return () => { active = false }
  }, [applyStats, userId])

  const recordGift = useCallback((gift, quantity) => {
    const normalizedQuantity = Math.max(1, Number(quantity) || 1)
    const previous = statsRef.current
    const predictedCoins = previous.totalCoinsSent + Math.max(0, Number(gift?.cost || 0)) * normalizedQuantity
    const predicted = {
      totalCoinsSent: predictedCoins,
      giftCount: previous.giftCount + normalizedQuantity,
      level: computeGifterLevel(predictedCoins),
    }
    applyStats(predicted)

    if (!roomId || !gift?.id) return predicted.level

    recordBetaGift({ roomId, giftId: gift.id, quantity: normalizedQuantity })
      .then((confirmed) => applyStats(confirmed))
      .catch(() => {
        applyStats(previous)
        setToast?.('Gift sent · gifter level sync is reconnecting')
      })

    return predicted.level
  }, [applyStats, roomId, setToast])

  return { ...stats, recordGift }
}

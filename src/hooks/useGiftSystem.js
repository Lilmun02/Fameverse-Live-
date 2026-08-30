import { useEffect, useRef, useState } from 'react'
import { loadCoins } from '../utils/pwa.js'

export function useGiftSystem({ isLive, displayName, setToast, setChat }) {
  const [coins, setCoins] = useState(loadCoins)
  const [giftOverlay, setGiftOverlay] = useState(null)
  const [premiumRepeat, setPremiumRepeat] = useState(null)
  const [giftTrayOpen, setGiftTrayOpen] = useState(false)

  const giftTimerRef = useRef(null)
  const premiumRepeatTimerRef = useRef(null)
  const premiumComboRef = useRef({ id: null, at: 0, count: 0 })
  const coinsRef = useRef(coins)

  useEffect(() => {
    coinsRef.current = coins
    localStorage.setItem('fameverse-owner-test-coins', String(coins))
  }, [coins])

  useEffect(() => () => {
    clearTimeout(giftTimerRef.current)
    clearTimeout(premiumRepeatTimerRef.current)
    window.FameverseGiftEngine?.stop?.()
  }, [])

  useEffect(() => {
    if (isLive) return
    clearTimeout(premiumRepeatTimerRef.current)
    setPremiumRepeat(null)
    setGiftTrayOpen(false)
    premiumComboRef.current = { id: null, at: 0, count: 0 }
    window.FameverseGiftEngine?.stop?.()
  }, [isLive])

  const addTestCoins = (amount = 10000) => {
    const next = coinsRef.current + amount
    coinsRef.current = next
    setCoins(next)
    setToast(`+${amount.toLocaleString()} beta test coins`)
  }

  const showGift = (gift) => {
    if (giftTrayOpen) return

    clearTimeout(giftTimerRef.current)
    const now = Date.now()
    setGiftOverlay((previous) => {
      const sameCombo = previous?.id === gift.id && now - (previous.lastSentAt || 0) < 2200
      return {
        ...gift,
        sender: displayName,
        duration: 1800,
        count: sameCombo ? (previous.count || 1) + 1 : 1,
        lastSentAt: now,
      }
    })
    giftTimerRef.current = setTimeout(() => setGiftOverlay(null), 1800)
  }

  const sendGift = (gift) => {
    if (!isLive) {
      setGiftTrayOpen(false)
      setToast('Start Live before sending gifts')
      return
    }

    if (coinsRef.current < gift.cost) {
      setToast('Test balance empty · tap refill')
      return
    }

    const nextBalance = coinsRef.current - gift.cost
    coinsRef.current = nextBalance
    setCoins(nextBalance)

    const activityEmoji = gift.activityEmoji || gift.emoji || '✦'
    setChat((items) => [...items, {
      id: `${Date.now()}-${Math.random()}`,
      user: displayName,
      text: `${activityEmoji} sent ${gift.label}`,
    }])

    if (gift.rendererId) {
      const now = Date.now()
      const previous = premiumComboRef.current
      const sameCombo = previous.id === gift.id && now - previous.at < 2200
      const comboCount = sameCombo ? previous.count + 1 : 1
      premiumComboRef.current = { id: gift.id, at: now, count: comboCount }

      setGiftTrayOpen(false)
      setPremiumRepeat({ ...gift, comboCount })
      clearTimeout(premiumRepeatTimerRef.current)
      premiumRepeatTimerRef.current = window.setTimeout(() => setPremiumRepeat(null), 6800)

      window.setTimeout(() => {
        document.dispatchEvent(new CustomEvent('fameverse:gift', {
          detail: { id: gift.rendererId, sender: displayName, comboCount },
        }))
      }, 140)
      return
    }

    showGift(gift)
  }

  const stopGiftPlayback = () => {
    clearTimeout(premiumRepeatTimerRef.current)
    setPremiumRepeat(null)
    window.FameverseGiftEngine?.stop?.()
  }

  return {
    coins,
    giftOverlay,
    premiumRepeat,
    giftTrayOpen,
    setGiftTrayOpen,
    addTestCoins,
    sendGift,
    stopGiftPlayback,
  }
}

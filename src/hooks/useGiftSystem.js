import { useEffect, useRef, useState } from 'react'
import { loadCoins } from '../utils/pwa.js'

export function useGiftSystem({ isLive, displayName, setToast, setChat }) {
  const [coins, setCoins] = useState(loadCoins)
  const [giftOverlay, setGiftOverlay] = useState(null)
  const [premiumRepeat, setPremiumRepeat] = useState(null)
  const [giftTrayOpen, setGiftTrayOpenState] = useState(false)
  const [giftSendCounts, setGiftSendCounts] = useState({})

  const giftTimerRef = useRef(null)
  const premiumRepeatTimerRef = useRef(null)
  const premiumComboRef = useRef({ id: null, at: 0, count: 0 })
  const coinsRef = useRef(coins)

  const setGiftTrayOpen = (open) => {
    setGiftTrayOpenState(open)
    if (open) {
      clearTimeout(giftTimerRef.current)
      setGiftOverlay(null)
    }
  }

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
    setGiftSendCounts({})
    premiumComboRef.current = { id: null, at: 0, count: 0 }
    window.FameverseGiftEngine?.stop?.()
  }, [isLive])

  const addTestCoins = (amount = 10000) => {
    const next = coinsRef.current + amount
    coinsRef.current = next
    setCoins(next)
    setToast(`+${amount.toLocaleString()} beta test coins`)
  }

  const showGift = (gift, quantity = 1) => {
    clearTimeout(giftTimerRef.current)
    const now = Date.now()
    setGiftOverlay((previous) => {
      const sameCombo = previous?.id === gift.id && now - (previous.lastSentAt || 0) < 2200
      return {
        ...gift,
        sender: displayName,
        duration: 1800,
        count: sameCombo ? (previous.count || 1) + quantity : quantity,
        lastSentAt: now,
      }
    })
    giftTimerRef.current = setTimeout(() => setGiftOverlay(null), 1800)
  }

  const sendGift = (gift, quantity = 1) => {
    const safeQuantity = [1, 5, 10].includes(quantity) ? quantity : 1

    if (!isLive) {
      setGiftTrayOpen(false)
      setToast('Start Live before sending gifts')
      return
    }

    const totalCost = gift.cost * safeQuantity
    if (coinsRef.current < totalCost) {
      setToast(`Need ${totalCost.toLocaleString()} test coins for ×${safeQuantity}`)
      return
    }

    const nextBalance = coinsRef.current - totalCost
    coinsRef.current = nextBalance
    setCoins(nextBalance)
    setGiftSendCounts((counts) => ({
      ...counts,
      [gift.id]: (counts[gift.id] || 0) + safeQuantity,
    }))

    const activityEmoji = gift.activityEmoji || gift.emoji || '✦'
    setChat((items) => [...items, {
      id: `${Date.now()}-${Math.random()}`,
      user: displayName,
      text: `${activityEmoji} sent ${gift.label}${safeQuantity > 1 ? ` ×${safeQuantity}` : ''}`,
    }])

    // Sending and browsing are separate states: the tray always closes before
    // any gift renderer or simple overlay is allowed onto the live screen.
    setGiftTrayOpen(false)

    if (gift.rendererId) {
      const now = Date.now()
      const previous = premiumComboRef.current
      const sameCombo = previous.id === gift.id && now - previous.at < 2200
      const comboCount = sameCombo ? previous.count + safeQuantity : safeQuantity
      premiumComboRef.current = { id: gift.id, at: now, count: comboCount }

      setPremiumRepeat({ ...gift, comboCount })
      clearTimeout(premiumRepeatTimerRef.current)
      premiumRepeatTimerRef.current = window.setTimeout(() => setPremiumRepeat(null), 6800)

      window.setTimeout(() => {
        document.dispatchEvent(new CustomEvent('fameverse:gift', {
          detail: { id: gift.rendererId, sender: displayName, comboCount },
        }))
      }, 180)
      return
    }

    window.setTimeout(() => showGift(gift, safeQuantity), 180)
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
    giftSendCounts,
    setGiftTrayOpen,
    addTestCoins,
    sendGift,
    stopGiftPlayback,
  }
}

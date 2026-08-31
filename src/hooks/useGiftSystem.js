import { useEffect, useRef, useState } from 'react'
import { loadCoins } from '../utils/pwa.js'

const SIMPLE_GIFT_DURATION_MS = 1800

export function useGiftSystem({ isLive, displayName, setToast, setChat }) {
  const [coins, setCoins] = useState(loadCoins)
  const [giftOverlay, setGiftOverlay] = useState(null)
  const [premiumRepeat, setPremiumRepeat] = useState(null)
  const [giftTrayOpen, setGiftTrayOpen] = useState(false)

  const giftTimerRef = useRef(null)
  const simpleGiftQueueRef = useRef([])
  const simpleGiftActiveRef = useRef(false)
  const premiumRepeatTimerRef = useRef(null)
  const coinsRef = useRef(coins)

  useEffect(() => {
    coinsRef.current = coins
    localStorage.setItem('fameverse-owner-test-coins', String(coins))
  }, [coins])

  useEffect(() => () => {
    clearTimeout(giftTimerRef.current)
    simpleGiftQueueRef.current = []
    simpleGiftActiveRef.current = false
    clearTimeout(premiumRepeatTimerRef.current)
    window.FameverseGiftEngine?.stop?.()
  }, [])

  const clearSimpleGiftPlayback = () => {
    clearTimeout(giftTimerRef.current)
    giftTimerRef.current = null
    simpleGiftQueueRef.current = []
    simpleGiftActiveRef.current = false
    setGiftOverlay(null)
  }

  useEffect(() => {
    if (isLive) return
    clearSimpleGiftPlayback()
    clearTimeout(premiumRepeatTimerRef.current)
    setPremiumRepeat(null)
    setGiftTrayOpen(false)
    window.FameverseGiftEngine?.stop?.()
  }, [isLive])

  const addTestCoins = (amount = 10000) => {
    const next = coinsRef.current + amount
    coinsRef.current = next
    setCoins(next)
    setToast(`+${amount.toLocaleString()} beta test coins`)
  }

  const playNextSimpleGift = () => {
    if (simpleGiftActiveRef.current) return
    const next = simpleGiftQueueRef.current.shift()
    if (!next) return

    simpleGiftActiveRef.current = true
    setGiftOverlay({
      ...next.gift,
      sender: displayName,
      duration: SIMPLE_GIFT_DURATION_MS,
      count: next.quantity,
      lastSentAt: Date.now(),
    })

    giftTimerRef.current = window.setTimeout(() => {
      giftTimerRef.current = null
      setGiftOverlay(null)
      simpleGiftActiveRef.current = false
      playNextSimpleGift()
    }, SIMPLE_GIFT_DURATION_MS)
  }

  const showGift = (gift, quantity) => {
    simpleGiftQueueRef.current.push({ gift, quantity })
    playNextSimpleGift()
  }

  const sendGift = (gift, quantity = 1, { keepTrayOpen = false } = {}) => {
    if (!isLive) {
      setGiftTrayOpen(false)
      setToast('Start Live before sending gifts')
      return false
    }

    const normalizedQuantity = Number(quantity)
    if (!Number.isSafeInteger(normalizedQuantity) || normalizedQuantity < 1) {
      setToast('Enter a whole gift amount of 1 or more')
      return false
    }

    const totalCost = gift.cost * normalizedQuantity
    if (!Number.isSafeInteger(totalCost) || totalCost < 0) {
      setToast('Gift amount is too large')
      return false
    }

    if (coinsRef.current < totalCost) {
      setToast('Test balance empty · lower the amount or tap refill')
      return false
    }

    const nextBalance = coinsRef.current - totalCost
    coinsRef.current = nextBalance
    setCoins(nextBalance)

    const activityEmoji = gift.activityEmoji || gift.emoji || '✦'
    setChat((items) => [...items, {
      id: `${Date.now()}-${Math.random()}`,
      user: displayName,
      text: `${activityEmoji} sent ${gift.label} ×${normalizedQuantity}`,
    }])

    if (!keepTrayOpen) setGiftTrayOpen(false)

    if (gift.rendererId) {
      setPremiumRepeat({ ...gift, quantity: normalizedQuantity })
      clearTimeout(premiumRepeatTimerRef.current)
      premiumRepeatTimerRef.current = window.setTimeout(() => setPremiumRepeat(null), 6800)

      window.setTimeout(() => {
        document.dispatchEvent(new CustomEvent('fameverse:gift', {
          detail: { id: gift.rendererId, sender: displayName, quantity: normalizedQuantity },
        }))
      }, 140)
      return true
    }

    showGift(gift, normalizedQuantity)
    return true
  }

  const stopGiftPlayback = () => {
    clearSimpleGiftPlayback()
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

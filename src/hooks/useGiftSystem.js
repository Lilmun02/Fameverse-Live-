import { useCallback, useEffect, useRef, useState } from 'react'
import { createGifterBadge } from '../features/badges/gifterBadgeSystem.js'
import { loadCoins } from '../utils/pwa.js'

const SIMPLE_GIFT_DURATION_MS = 1800

export function useGiftSystem({ isLive, displayName, actorId, setToast, setChat, onGiftAccepted }) {
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

  const clearSimpleGiftPlayback = useCallback(() => {
    clearTimeout(giftTimerRef.current)
    giftTimerRef.current = null
    simpleGiftQueueRef.current = []
    simpleGiftActiveRef.current = false
    setGiftOverlay(null)
  }, [])

  useEffect(() => {
    if (isLive) return
    clearSimpleGiftPlayback()
    clearTimeout(premiumRepeatTimerRef.current)
    setPremiumRepeat(null)
    setGiftTrayOpen(false)
    window.FameverseGiftEngine?.stop?.()
  }, [clearSimpleGiftPlayback, isLive])

  const addTestCoins = (amount = 10000) => {
    const next = coinsRef.current + amount
    coinsRef.current = next
    setCoins(next)
    setToast(`+${amount.toLocaleString()} beta test coins`)
  }

  const playNextSimpleGift = useCallback(() => {
    if (simpleGiftActiveRef.current) return
    const next = simpleGiftQueueRef.current.shift()
    if (!next) return

    simpleGiftActiveRef.current = true
    setGiftOverlay({
      ...next.gift,
      sender: next.sender || displayName,
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
  }, [displayName])

  const showGift = useCallback((gift, quantity, sender = displayName) => {
    simpleGiftQueueRef.current.push({ gift, quantity, sender })
    playNextSimpleGift()
  }, [displayName, playNextSimpleGift])

  const playPremiumGift = useCallback((gift, quantity, sender) => {
    setPremiumRepeat({ ...gift, quantity: Number(quantity) || 1 })
    clearTimeout(premiumRepeatTimerRef.current)
    premiumRepeatTimerRef.current = window.setTimeout(() => setPremiumRepeat(null), 6800)

    window.setTimeout(() => {
      document.dispatchEvent(new CustomEvent('fameverse:gift', {
        detail: { id: gift.rendererId, sender, quantity: Number(quantity) || 1 },
      }))
    }, 140)
  }, [])

  const receiveGift = useCallback((gift, quantity = 1, sender = 'Fameverse viewer') => {
    if (!gift) return false
    const normalizedQuantity = Math.max(1, Number(quantity) || 1)
    if (Boolean(gift.rendererId)) playPremiumGift(gift, normalizedQuantity, sender)
    else showGift(gift, normalizedQuantity, sender)
    return true
  }, [playPremiumGift, showGift])

  const sendGift = (gift, quantity = 1, { keepTrayOpen = false } = {}) => {
    if (!isLive) {
      setGiftTrayOpen(false)
      setToast('Open a Live before sending gifts')
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
      kind: 'gift',
      user: displayName,
      userId: actorId || null,
      badge: createGifterBadge(),
      giftId: gift.id,
      quantity: normalizedQuantity,
      text: `${activityEmoji} sent ${gift.label} ×${normalizedQuantity}`,
    }])

    onGiftAccepted?.({
      gift,
      quantity: normalizedQuantity,
      sender: displayName,
      totalCoins: totalCost,
    })

    if (!keepTrayOpen) setGiftTrayOpen(false)

    if (gift.rendererId) {
      playPremiumGift(gift, normalizedQuantity, displayName)
      return true
    }

    showGift(gift, normalizedQuantity, displayName)
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
    receiveGift,
    stopGiftPlayback,
  }
}

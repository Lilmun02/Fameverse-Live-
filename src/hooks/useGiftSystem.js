import { useCallback, useEffect, useRef, useState } from 'react'
import { MAX_BETA_GIFT_QUANTITY } from '../config/gifts.js'

const SIMPLE_GIFT_DURATION_MS = 1800

export function useGiftSystem({
  isLive,
  displayName,
  actorId,
  gifterLevel = 1,
  coins = 0,
  walletReady = false,
  setWalletBalance,
  recordGifterGift,
  addTestCoins,
  setToast,
  setChat,
  onGiftAccepted,
}) {
  const [giftOverlay, setGiftOverlay] = useState(null)
  const [premiumRepeat, setPremiumRepeat] = useState(null)
  const [giftTrayOpen, setGiftTrayOpen] = useState(false)

  const giftTimerRef = useRef(null)
  const simpleGiftQueueRef = useRef([])
  const simpleGiftActiveRef = useRef(false)
  const premiumRepeatTimerRef = useRef(null)
  const coinsRef = useRef(Math.max(0, Number(coins || 0)))
  const sendQueueRef = useRef(Promise.resolve())

  useEffect(() => {
    coinsRef.current = Math.max(0, Number(coins || 0))
  }, [coins])

  useEffect(() => () => {
    clearTimeout(giftTimerRef.current)
    simpleGiftQueueRef.current = []
    simpleGiftActiveRef.current = false
    clearTimeout(premiumRepeatTimerRef.current)
    window.FameverseGiftEngine?.stop?.()
    window.FameverseGiftEngine?.stopAudioSession?.()
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
    window.FameverseGiftEngine?.stopAudioSession?.()
  }, [clearSimpleGiftPlayback, isLive])

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
    window.FameverseGiftEngine?.primeAudio?.()
    setPremiumRepeat({ ...gift, quantity: Number(quantity) || 1 })
    clearTimeout(premiumRepeatTimerRef.current)
    premiumRepeatTimerRef.current = window.setTimeout(() => setPremiumRepeat(null), 6800)

    window.setTimeout(() => {
      window.FameverseGiftEngine?.primeAudio?.()
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

  const commitGift = useCallback(async (gift, normalizedQuantity, keepTrayOpen) => {
    if (!isLive) {
      setGiftTrayOpen(false)
      setToast('Open a Live before sending gifts')
      return false
    }

    if (!walletReady) {
      setToast('Gift wallet is reconnecting')
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

    let confirmed
    try {
      confirmed = await recordGifterGift?.(gift, normalizedQuantity)
    } catch (error) {
      const message = String(error?.message || '').toLowerCase()
      if (message.includes('insufficient beta coin balance')) {
        setToast('Test balance empty · lower the amount or tap refill')
      } else {
        setToast('Gift could not be recorded · try again')
      }
      return false
    }

    if (!confirmed) {
      setToast('Gift could not be recorded · try again')
      return false
    }

    const nextBalance = Math.max(0, Number(confirmed.walletBalance || 0))
    coinsRef.current = nextBalance
    setWalletBalance?.(nextBalance)

    const eventLevel = Math.max(1, Number(confirmed.level || gifterLevel || 1))
    const activityEmoji = gift.activityEmoji || gift.emoji || '✦'
    setChat((items) => [...items, {
      id: `${Date.now()}-${Math.random()}`,
      kind: 'gift',
      user: displayName,
      userId: actorId || null,
      gifterLevel: eventLevel,
      giftId: gift.id,
      quantity: normalizedQuantity,
      text: `${activityEmoji} sent ${gift.label} ×${normalizedQuantity}`,
    }])

    const acceptedGift = {
      gift,
      quantity: normalizedQuantity,
      sender: displayName,
      gifterLevel: eventLevel,
      totalCoins: totalCost,
    }
    onGiftAccepted?.(acceptedGift)

    if (!keepTrayOpen) setGiftTrayOpen(false)

    if (gift.rendererId) {
      playPremiumGift(gift, normalizedQuantity, displayName)
      return true
    }

    showGift(gift, normalizedQuantity, displayName)
    return true
  }, [
    actorId,
    displayName,
    gifterLevel,
    isLive,
    onGiftAccepted,
    playPremiumGift,
    recordGifterGift,
    setChat,
    setToast,
    setWalletBalance,
    showGift,
    walletReady,
  ])

  const sendGift = (gift, quantity = 1, { keepTrayOpen = false } = {}) => {
    const normalizedQuantity = Number(quantity)
    if (!Number.isSafeInteger(normalizedQuantity) || normalizedQuantity < 1) {
      setToast('Enter a whole gift amount of 1 or more')
      return Promise.resolve(false)
    }
    if (normalizedQuantity > MAX_BETA_GIFT_QUANTITY) {
      setToast(`Beta gift limit is ${MAX_BETA_GIFT_QUANTITY.toLocaleString()} per send`)
      return Promise.resolve(false)
    }

    const task = sendQueueRef.current.then(() => commitGift(gift, normalizedQuantity, keepTrayOpen))
    sendQueueRef.current = task.catch(() => false)
    return task
  }

  const refillTestCoins = (amount = 10000) => addTestCoins?.(amount)

  const stopGiftPlayback = () => {
    clearSimpleGiftPlayback()
    clearTimeout(premiumRepeatTimerRef.current)
    setPremiumRepeat(null)
    window.FameverseGiftEngine?.stop?.()
  }

  return {
    coins: Math.max(0, Number(coins || 0)),
    giftOverlay,
    premiumRepeat,
    giftTrayOpen,
    setGiftTrayOpen,
    addTestCoins: refillTestCoins,
    sendGift,
    receiveGift,
    stopGiftPlayback,
  }
}

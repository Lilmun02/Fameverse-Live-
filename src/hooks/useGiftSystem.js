import { useEffect, useRef, useState } from 'react'
import { createGiftComboState, nextGiftCombo, nextOverlayCount } from '../systems/gifts/giftComboSystem.js'
import {
  addGiftBalance,
  canAffordGift,
  deductGiftCost,
  giftTotalCost,
  loadGiftBalance,
  normalizeGiftQuantity,
  persistGiftBalance,
} from '../systems/gifts/giftWalletSystem.js'
import {
  CINEMATIC_GIFT_DELAY_MS,
  PREMIUM_REPEAT_DURATION_MS,
  SIMPLE_GIFT_DURATION_MS,
  clearGiftPresentationTimer,
  createGiftOverlay,
  dispatchCinematicGift,
  giftActivityMessage,
  scheduleGiftPresentation,
  stopGiftRenderer,
} from '../systems/gifts/giftPresentationSystem.js'

export function useGiftSystem({ isLive, displayName, setToast, setChat }) {
  const [coins, setCoins] = useState(loadGiftBalance)
  const [giftOverlay, setGiftOverlay] = useState(null)
  const [premiumRepeat, setPremiumRepeat] = useState(null)
  const [giftTrayOpen, setGiftTrayOpenState] = useState(false)
  const [giftSendCounts, setGiftSendCounts] = useState({})

  const giftTimerRef = useRef(null)
  const premiumRepeatTimerRef = useRef(null)
  const premiumComboRef = useRef(createGiftComboState())
  const coinsRef = useRef(coins)

  const clearGiftTimer = () => {
    clearGiftPresentationTimer(giftTimerRef.current)
    giftTimerRef.current = null
  }

  const clearPremiumRepeatTimer = () => {
    clearGiftPresentationTimer(premiumRepeatTimerRef.current)
    premiumRepeatTimerRef.current = null
  }

  const setGiftTrayOpen = (open) => {
    setGiftTrayOpenState(open)
    if (open) {
      clearGiftTimer()
      setGiftOverlay(null)
    }
  }

  const applyBalance = (nextBalance) => {
    coinsRef.current = nextBalance
    setCoins(nextBalance)
    persistGiftBalance(nextBalance)
  }

  useEffect(() => {
    coinsRef.current = coins
  }, [coins])

  useEffect(() => () => {
    clearGiftTimer()
    clearPremiumRepeatTimer()
    stopGiftRenderer()
  }, [])

  useEffect(() => {
    if (isLive) return
    clearPremiumRepeatTimer()
    setPremiumRepeat(null)
    setGiftTrayOpen(false)
    setGiftSendCounts({})
    premiumComboRef.current = createGiftComboState()
    stopGiftRenderer()
  }, [isLive])

  const addTestCoins = (amount = 10000) => {
    const nextBalance = addGiftBalance(coinsRef.current, amount)
    applyBalance(nextBalance)
    setToast(`+${amount.toLocaleString()} beta test coins`)
  }

  const showGift = (gift, quantity = 1) => {
    clearGiftTimer()
    const now = Date.now()
    setGiftOverlay((previous) => createGiftOverlay(
      gift,
      displayName,
      nextOverlayCount(previous, gift.id, quantity, now),
      now,
    ))
    giftTimerRef.current = scheduleGiftPresentation(
      () => setGiftOverlay(null),
      SIMPLE_GIFT_DURATION_MS,
    )
  }

  const sendGift = (gift, quantity = 1) => {
    const safeQuantity = normalizeGiftQuantity(quantity)

    if (!isLive) {
      setGiftTrayOpen(false)
      setToast('Start Live before sending gifts')
      return
    }

    const totalCost = giftTotalCost(gift, safeQuantity)
    if (!canAffordGift(coinsRef.current, totalCost)) {
      setToast(`Need ${totalCost.toLocaleString()} test coins for ×${safeQuantity}`)
      return
    }

    applyBalance(deductGiftCost(coinsRef.current, totalCost))
    setGiftSendCounts((counts) => ({
      ...counts,
      [gift.id]: (counts[gift.id] || 0) + safeQuantity,
    }))

    setChat((items) => [...items, {
      id: `${Date.now()}-${Math.random()}`,
      user: displayName,
      text: giftActivityMessage(gift, safeQuantity),
    }])

    setGiftTrayOpen(false)

    if (gift.rendererId) {
      const combo = nextGiftCombo(premiumComboRef.current, gift.id, safeQuantity)
      premiumComboRef.current = combo
      setPremiumRepeat({ ...gift, comboCount: combo.count })
      clearPremiumRepeatTimer()
      premiumRepeatTimerRef.current = scheduleGiftPresentation(
        () => setPremiumRepeat(null),
        PREMIUM_REPEAT_DURATION_MS,
      )
      scheduleGiftPresentation(
        () => dispatchCinematicGift(gift, displayName, combo.count),
        CINEMATIC_GIFT_DELAY_MS,
      )
      return
    }

    scheduleGiftPresentation(
      () => showGift(gift, safeQuantity),
      CINEMATIC_GIFT_DELAY_MS,
    )
  }

  const stopGiftPlayback = () => {
    clearPremiumRepeatTimer()
    setPremiumRepeat(null)
    stopGiftRenderer()
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

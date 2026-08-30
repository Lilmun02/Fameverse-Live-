import { useEffect, useRef, useState } from 'react'
import { createGiftComboState, nextGiftCombo, nextOverlayCount } from '../systems/gifts/giftComboSystem.js'
import {
  addGiftBalance,
  canAffordGift,
  deductGiftCost,
  giftTotalCost,
  loadGiftBalance,
  persistGiftBalance,
} from '../systems/gifts/giftWalletSystem.js'
import {
  CINEMATIC_GIFT_DELAY_MS,
  PREMIUM_REPEAT_DURATION_MS,
  SIMPLE_GIFT_DURATION_MS,
  clearAllGiftPresentationTimers,
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
    if (!persistGiftBalance(nextBalance)) return false
    coinsRef.current = nextBalance
    setCoins(nextBalance)
    return true
  }

  useEffect(() => {
    coinsRef.current = coins
  }, [coins])

  useEffect(() => () => {
    clearAllGiftPresentationTimers()
    clearGiftTimer()
    clearPremiumRepeatTimer()
    stopGiftRenderer()
  }, [])

  useEffect(() => {
    if (isLive) return
    clearAllGiftPresentationTimers()
    clearPremiumRepeatTimer()
    setPremiumRepeat(null)
    setGiftOverlay(null)
    setGiftTrayOpen(false)
    setGiftSendCounts({})
    premiumComboRef.current = createGiftComboState()
    stopGiftRenderer()
  }, [isLive])

  const addTestCoins = (amount = 10000) => {
    const nextBalance = addGiftBalance(coinsRef.current, amount)
    if (!applyBalance(nextBalance)) {
      setToast('Test coins could not be saved · try again')
      return
    }
    setToast(`+${amount.toLocaleString()} beta test coins`)
  }

  const showGift = (gift) => {
    clearGiftTimer()
    const now = Date.now()
    setGiftOverlay((previous) => createGiftOverlay(
      gift,
      displayName,
      nextOverlayCount(previous, gift.id, now),
      now,
    ))
    giftTimerRef.current = scheduleGiftPresentation(
      () => setGiftOverlay(null),
      SIMPLE_GIFT_DURATION_MS,
    )
  }

  const sendGift = (gift) => {
    if (!isLive) {
      setGiftTrayOpen(false)
      setToast('Start Live before sending gifts')
      return
    }

    const totalCost = giftTotalCost(gift)
    if (totalCost == null) {
      setToast('Gift unavailable · try again')
      return
    }

    if (!canAffordGift(coinsRef.current, totalCost)) {
      setToast(`Need ${totalCost.toLocaleString()} test coins`)
      return
    }

    const nextBalance = deductGiftCost(coinsRef.current, totalCost)
    if (!applyBalance(nextBalance)) {
      setToast('Gift could not be saved · try again')
      return
    }
    setGiftSendCounts((counts) => ({
      ...counts,
      [gift.id]: (counts[gift.id] || 0) + 1,
    }))

    setChat((items) => [...items, {
      id: `${Date.now()}-${Math.random()}`,
      user: displayName,
      text: giftActivityMessage(gift, 1),
    }])

    setGiftTrayOpen(false)

    if (gift.rendererId) {
      const combo = nextGiftCombo(premiumComboRef.current, gift.id)
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
      () => showGift(gift),
      CINEMATIC_GIFT_DELAY_MS,
    )
  }

  const stopGiftPlayback = () => {
    clearAllGiftPresentationTimers()
    clearPremiumRepeatTimer()
    setPremiumRepeat(null)
    setGiftOverlay(null)
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

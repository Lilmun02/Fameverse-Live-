import { useEffect, useRef, useState } from 'react'
import { createGiftComboState, nextGiftCombo } from '../systems/gifts/giftComboSystem.js'
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
  clearAllGiftPresentationTimers,
  clearGiftPresentationTimer,
  dispatchCinematicGift,
  enqueueSimpleGift,
  giftActivityMessage,
  pauseSimpleGiftPresentation,
  resumeSimpleGiftPresentation,
  scheduleGiftPresentation,
  stopGiftRenderer,
} from '../systems/gifts/giftPresentationSystem.js'

export function useGiftSystem({ isLive, displayName, setToast, setChat }) {
  const [coins, setCoins] = useState(loadGiftBalance)
  const [giftOverlay, setGiftOverlay] = useState(null)
  const [premiumRepeat, setPremiumRepeat] = useState(null)
  const [giftTrayOpen, setGiftTrayOpenState] = useState(false)
  const [giftSendCounts, setGiftSendCounts] = useState({})

  const premiumRepeatTimerRef = useRef(null)
  const giftComboRef = useRef(createGiftComboState())
  const coinsRef = useRef(coins)

  const clearPremiumRepeatTimer = () => {
    clearGiftPresentationTimer(premiumRepeatTimerRef.current)
    premiumRepeatTimerRef.current = null
  }

  const setGiftTrayOpen = (open) => {
    if (open) pauseSimpleGiftPresentation()
    setGiftTrayOpenState(open)
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

  useEffect(() => {
    if (!giftTrayOpen) resumeSimpleGiftPresentation()
  }, [giftTrayOpen])

  useEffect(() => () => {
    clearAllGiftPresentationTimers()
    clearPremiumRepeatTimer()
    stopGiftRenderer()
  }, [])

  useEffect(() => {
    if (isLive) return
    clearAllGiftPresentationTimers()
    clearPremiumRepeatTimer()
    setPremiumRepeat(null)
    setGiftOverlay(null)
    setGiftTrayOpenState(false)
    setGiftSendCounts({})
    giftComboRef.current = createGiftComboState()
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

  const showGift = (overlay) => setGiftOverlay(overlay)
  const hideGift = () => setGiftOverlay(null)

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

    const combo = nextGiftCombo(giftComboRef.current, gift.id)
    giftComboRef.current = combo

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

    enqueueSimpleGift(gift, displayName, combo.count, showGift, hideGift)
  }

  const stopGiftPlayback = () => {
    clearAllGiftPresentationTimers()
    clearPremiumRepeatTimer()
    setPremiumRepeat(null)
    setGiftOverlay(null)
    setGiftTrayOpenState(false)
    setGiftSendCounts({})
    giftComboRef.current = createGiftComboState()
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

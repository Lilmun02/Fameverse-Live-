import { useEffect, useRef, useState } from 'react'
import { loadCoins } from '../utils/pwa.js'
import { nextGiftCombo, nextOverlayCount } from '../systems/gifts/giftComboSystem.js'
import {
  canAffordGift,
  deductGiftCost,
  giftTotalCost,
  normalizeGiftQuantity,
} from '../systems/gifts/giftWalletSystem.js'
import {
  createGiftOverlay,
  dispatchCinematicGift,
  giftActivityMessage,
} from '../systems/gifts/giftPresentationSystem.js'

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
    setGiftOverlay((previous) => createGiftOverlay(
      gift,
      displayName,
      nextOverlayCount(previous, gift.id, quantity, now),
      now,
    ))
    giftTimerRef.current = setTimeout(() => setGiftOverlay(null), 1800)
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

    const nextBalance = deductGiftCost(coinsRef.current, totalCost)
    coinsRef.current = nextBalance
    setCoins(nextBalance)
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
      clearTimeout(premiumRepeatTimerRef.current)
      premiumRepeatTimerRef.current = window.setTimeout(() => setPremiumRepeat(null), 6800)
      window.setTimeout(() => dispatchCinematicGift(gift, displayName, combo.count), 180)
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

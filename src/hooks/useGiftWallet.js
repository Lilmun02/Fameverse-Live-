import { useCallback, useEffect, useState } from 'react'
import { loadBetaWalletBalance, refillBetaWallet } from '../services/giftWallet.js'

export function useGiftWallet({ userId, setToast }) {
  const [balance, setBalance] = useState(0)
  const [ready, setReady] = useState(false)

  const applyBalance = useCallback((nextBalance) => {
    const normalized = Math.max(0, Number(nextBalance || 0))
    setBalance(normalized)
    return normalized
  }, [])

  useEffect(() => {
    let active = true
    if (!userId) {
      setBalance(0)
      setReady(false)
      return undefined
    }

    setReady(false)
    loadBetaWalletBalance(userId)
      .then((nextBalance) => {
        if (!active) return
        applyBalance(nextBalance)
        setReady(true)
      })
      .catch(() => {
        if (!active) return
        setBalance(0)
        setReady(false)
        setToast?.('Gift wallet is reconnecting')
      })

    return () => { active = false }
  }, [applyBalance, setToast, userId])

  const refill = useCallback(async (amount = 10000) => {
    try {
      const nextBalance = await refillBetaWallet(amount)
      applyBalance(nextBalance)
      setReady(true)
      setToast?.(`+${amount.toLocaleString()} beta test coins`)
      return nextBalance
    } catch {
      setToast?.('Could not refill beta wallet')
      return null
    }
  }, [applyBalance, setToast])

  return {
    balance,
    ready,
    applyBalance,
    refill,
  }
}

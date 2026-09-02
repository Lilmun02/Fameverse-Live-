import { useEffect, useState } from 'react'
import { TAP_TOTALS_POLL_MS } from '../features/taps/tapIntegrityConfig.js'
import { getLiveTapTotals } from '../services/live/liveTaps.js'

const EMPTY_TOTALS = Object.freeze({ rawTaps: 0, eligibleTaps: 0, updatedAt: null })

export function useLiveTapTotals({ roomId }) {
  const [totals, setTotals] = useState(EMPTY_TOTALS)
  const [state, setState] = useState('idle')

  useEffect(() => {
    if (!roomId) {
      setTotals(EMPTY_TOTALS)
      setState('idle')
      return undefined
    }

    let active = true
    const refresh = async () => {
      const { totals: nextTotals, error } = await getLiveTapTotals(roomId)
      if (!active) return
      if (error) {
        setState('degraded')
        return
      }
      setTotals(nextTotals)
      setState('ready')
    }

    refresh()
    const timer = window.setInterval(refresh, TAP_TOTALS_POLL_MS)
    return () => {
      active = false
      window.clearInterval(timer)
    }
  }, [roomId])

  return {
    ...totals,
    state,
  }
}

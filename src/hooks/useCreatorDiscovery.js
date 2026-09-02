import { useCallback, useEffect, useState } from 'react'
import { listRecommendedCreators } from '../services/discovery/creatorDiscovery.js'

const CREATOR_REFRESH_MS = 20000

export function useCreatorDiscovery({ userId, enabled = true }) {
  const [creators, setCreators] = useState([])
  const [state, setState] = useState('idle')

  const refresh = useCallback(async () => {
    if (!enabled || !userId) {
      setCreators([])
      setState('idle')
      return
    }

    setState((current) => (current === 'idle' ? 'loading' : current))
    const { creators: nextCreators, error } = await listRecommendedCreators({ excludeUserId: userId })
    if (error) {
      setState('degraded')
      return
    }

    setCreators(nextCreators)
    setState('ready')
  }, [enabled, userId])

  useEffect(() => {
    if (!enabled || !userId) return undefined
    void refresh()
    const timer = window.setInterval(refresh, CREATOR_REFRESH_MS)
    return () => window.clearInterval(timer)
  }, [enabled, refresh, userId])

  return { creators, state, refresh }
}

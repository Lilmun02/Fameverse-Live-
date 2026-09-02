import { useCallback, useEffect, useState } from 'react'
import { listDiscoverableLiveRooms } from '../services/live/liveDiscovery.js'

const LIVE_DISCOVERY_POLL_MS = 3000

export function useLiveDiscovery({ userId, enabled = true }) {
  const [rooms, setRooms] = useState([])
  const [state, setState] = useState('idle')

  const refresh = useCallback(async () => {
    if (!enabled || !userId) {
      setRooms([])
      setState('idle')
      return
    }

    setState((current) => (current === 'idle' ? 'loading' : current))
    const { rooms: nextRooms, error } = await listDiscoverableLiveRooms({ excludeUserId: userId })
    if (error) {
      setState('degraded')
      return
    }

    setRooms(nextRooms)
    setState('ready')
  }, [enabled, userId])

  useEffect(() => {
    if (!enabled || !userId) return undefined
    let active = true

    const run = async () => {
      if (!active) return
      await refresh()
    }

    run()
    const timer = window.setInterval(run, LIVE_DISCOVERY_POLL_MS)
    return () => {
      active = false
      window.clearInterval(timer)
    }
  }, [enabled, refresh, userId])

  return { rooms, state, refresh }
}

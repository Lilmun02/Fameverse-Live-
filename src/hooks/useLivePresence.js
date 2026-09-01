import { useCallback, useEffect, useState } from 'react'
import { endLiveRoom, heartbeatLiveRoom, startLiveRoom } from '../services/live/livePresence.js'
import {
  LIVE_PRESENCE_HEARTBEAT_MS,
  LIVE_PRESENCE_STATES,
} from '../services/live/livePresenceConfig.js'

export function useLivePresence({ userId }) {
  const [room, setRoom] = useState(null)
  const [state, setState] = useState(LIVE_PRESENCE_STATES.IDLE)

  useEffect(() => {
    if (!room?.id || !userId) return undefined

    let active = true
    const heartbeat = async () => {
      const ok = await heartbeatLiveRoom({ roomId: room.id, hostUserId: userId })
      if (!active) return
      setState(ok ? LIVE_PRESENCE_STATES.LIVE : LIVE_PRESENCE_STATES.DEGRADED)
    }

    const timer = window.setInterval(heartbeat, LIVE_PRESENCE_HEARTBEAT_MS)
    return () => {
      active = false
      window.clearInterval(timer)
    }
  }, [room?.id, userId])

  const startPresence = useCallback(async (title) => {
    if (!userId) return false
    setState(LIVE_PRESENCE_STATES.STARTING)
    const { room: nextRoom, error } = await startLiveRoom({ hostUserId: userId, title })
    if (error || !nextRoom) {
      setRoom(null)
      setState(LIVE_PRESENCE_STATES.IDLE)
      return false
    }
    setRoom(nextRoom)
    setState(LIVE_PRESENCE_STATES.LIVE)
    return true
  }, [userId])

  const endPresence = useCallback(async () => {
    if (!room?.id || !userId) {
      setRoom(null)
      setState(LIVE_PRESENCE_STATES.IDLE)
      return true
    }

    setState(LIVE_PRESENCE_STATES.ENDING)
    const ok = await endLiveRoom({ roomId: room.id, hostUserId: userId })
    setRoom(null)
    setState(LIVE_PRESENCE_STATES.IDLE)
    return ok
  }, [room?.id, userId])

  return {
    room,
    state,
    startPresence,
    endPresence,
  }
}

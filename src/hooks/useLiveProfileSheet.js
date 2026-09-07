import { useCallback, useEffect, useState } from 'react'
import { loadLiveIdentity } from '../services/profiles.js'
import { loadLiveViewerIdentityStats } from '../services/live/viewerIdentityStats.js'

export function useLiveProfileSheet(roomId = null) {
  const [userId, setUserId] = useState(null)
  const [profile, setProfile] = useState(null)
  const [status, setStatus] = useState('idle')
  const [refreshToken, setRefreshToken] = useState(0)

  const open = useCallback((nextUserId) => {
    if (!nextUserId) return
    setUserId(nextUserId)
  }, [])

  const close = useCallback(() => {
    setUserId(null)
    setProfile(null)
    setStatus('idle')
  }, [])

  const refresh = useCallback(() => {
    if (!userId) return
    setRefreshToken((value) => value + 1)
  }, [userId])

  useEffect(() => {
    if (!userId) return undefined

    let active = true
    setStatus('loading')

    Promise.all([
      loadLiveIdentity(userId),
      loadLiveViewerIdentityStats(roomId, [userId]).catch(() => []),
    ])
      .then(([identity, roomStats]) => {
        if (!active) return
        if (!identity) {
          setProfile(null)
          setStatus('missing')
          return
        }
        const liveStats = roomStats?.[0] || null
        setProfile({
          ...identity,
          roomGiftCount: liveStats?.roomGiftCount || 0,
          roomFameTaps: liveStats?.roomFameTaps || 0,
        })
        setStatus('ready')
      })
      .catch(() => {
        if (!active) return
        setStatus('error')
      })

    return () => {
      active = false
    }
  }, [refreshToken, roomId, userId])

  return {
    open,
    close,
    refresh,
    userId,
    profile,
    status,
    isOpen: Boolean(userId),
  }
}

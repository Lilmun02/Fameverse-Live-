import { useCallback, useEffect, useState } from 'react'
import { loadLiveIdentity } from '../services/profiles.js'

export function useLiveProfileSheet() {
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

    loadLiveIdentity(userId)
      .then((identity) => {
        if (!active) return
        if (!identity) {
          setProfile(null)
          setStatus('missing')
          return
        }
        setProfile(identity)
        setStatus('ready')
      })
      .catch(() => {
        if (!active) return
        setStatus('error')
      })

    return () => {
      active = false
    }
  }, [refreshToken, userId])

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

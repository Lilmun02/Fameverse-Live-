import { useCallback, useEffect, useState } from 'react'
import { loadLiveIdentity } from '../services/profiles.js'

export function useLiveProfileSheet() {
  const [userId, setUserId] = useState(null)
  const [profile, setProfile] = useState(null)
  const [status, setStatus] = useState('idle')

  const open = useCallback((nextUserId) => {
    if (!nextUserId) return
    setUserId(nextUserId)
  }, [])

  const close = useCallback(() => {
    setUserId(null)
    setProfile(null)
    setStatus('idle')
  }, [])

  useEffect(() => {
    if (!userId) return undefined

    let active = true
    setStatus('loading')
    setProfile(null)

    loadLiveIdentity(userId)
      .then((identity) => {
        if (!active) return
        if (!identity) {
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
  }, [userId])

  return {
    open,
    close,
    userId,
    profile,
    status,
    isOpen: Boolean(userId),
  }
}

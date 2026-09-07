import { useEffect, useRef, useState } from 'react'
import { supabase } from '../services/supabase.js'
import { loadCreatorLiveDraft, saveCreatorLiveDraft } from '../services/live/creatorStudioBackend.js'

function createEmptySetup() {
  return {
    title: '',
    goal: '',
    wishlistGiftIds: [],
  }
}

export function useLiveSetup(setToast) {
  const [draft, setDraft] = useState(createEmptySetup)
  const [active, setActive] = useState(null)
  const [ownerUserId, setOwnerUserId] = useState(null)
  const hydratedUserIdRef = useRef(null)
  const saveTimerRef = useRef(null)

  useEffect(() => {
    let alive = true

    const hydrate = async (userId) => {
      window.clearTimeout(saveTimerRef.current)
      if (!userId) {
        hydratedUserIdRef.current = null
        setOwnerUserId(null)
        setDraft(createEmptySetup())
        setActive(null)
        return
      }

      hydratedUserIdRef.current = null
      setOwnerUserId(userId)
      const { draft: savedDraft, error } = await loadCreatorLiveDraft(userId)
      if (!alive) return
      if (error) {
        setToast('Could not load saved Live setup')
        setDraft(createEmptySetup())
      } else {
        setDraft(savedDraft || createEmptySetup())
      }
      hydratedUserIdRef.current = userId
    }

    supabase.auth.getSession().then(({ data }) => {
      if (alive) hydrate(data?.session?.user?.id || null)
    })

    const { data: authListener } = supabase.auth.onAuthStateChange((_event, session) => {
      hydrate(session?.user?.id || null)
    })

    return () => {
      alive = false
      window.clearTimeout(saveTimerRef.current)
      authListener?.subscription?.unsubscribe?.()
    }
  }, [setToast])

  useEffect(() => {
    if (!ownerUserId || hydratedUserIdRef.current !== ownerUserId) return undefined

    window.clearTimeout(saveTimerRef.current)
    saveTimerRef.current = window.setTimeout(() => {
      saveCreatorLiveDraft({ userId: ownerUserId, ...draft }).catch(() => {})
    }, 500)

    return () => window.clearTimeout(saveTimerRef.current)
  }, [draft, ownerUserId])

  const updateField = (field, value) => {
    if (field !== 'title' && field !== 'goal') return
    setDraft((current) => ({ ...current, [field]: value }))
  }

  const toggleWishlistGift = (giftId) => {
    setDraft((current) => {
      const selected = current.wishlistGiftIds.includes(giftId)
      const nextIds = selected
        ? current.wishlistGiftIds.filter((id) => id !== giftId)
        : [...current.wishlistGiftIds, giftId]

      return {
        ...current,
        wishlistGiftIds: nextIds.slice(0, 10),
      }
    })
  }

  const beginLive = async (startLive) => {
    const title = draft.title.trim()
    if (!title) {
      setToast('Add a live title first')
      return false
    }

    const nextSetup = {
      title,
      goal: draft.goal.trim(),
      wishlistGiftIds: [...draft.wishlistGiftIds],
    }

    const { error } = await saveCreatorLiveDraft({ userId: ownerUserId, ...nextSetup })
    if (error) {
      setToast('Could not save Live setup · try again')
      return false
    }

    const started = await startLive()
    if (started) setActive(nextSetup)
    return started
  }

  const reset = () => {
    setDraft(createEmptySetup())
    setActive(null)
  }

  return {
    draft,
    active,
    updateField,
    toggleWishlistGift,
    beginLive,
    reset,
  }
}

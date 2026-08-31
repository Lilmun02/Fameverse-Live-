import { useState } from 'react'

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

  const updateField = (field, value) => {
    if (field !== 'title' && field !== 'goal') return
    setDraft((current) => ({ ...current, [field]: value }))
  }

  const toggleWishlistGift = (giftId) => {
    setDraft((current) => {
      const selected = current.wishlistGiftIds.includes(giftId)
      return {
        ...current,
        wishlistGiftIds: selected
          ? current.wishlistGiftIds.filter((id) => id !== giftId)
          : [...current.wishlistGiftIds, giftId],
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

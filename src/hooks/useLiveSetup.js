import { useState } from 'react'

const EMPTY_SETUP = Object.freeze({
  title: '',
  goal: '',
  wishlist: '',
})

export function useLiveSetup(setToast) {
  const [draft, setDraft] = useState(EMPTY_SETUP)
  const [active, setActive] = useState(null)

  const updateField = (field, value) => {
    if (!(field in EMPTY_SETUP)) return
    setDraft((current) => ({ ...current, [field]: value }))
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
      wishlist: draft.wishlist.trim(),
    }
    const started = await startLive()
    if (started) setActive(nextSetup)
    return started
  }

  const reset = () => {
    setDraft(EMPTY_SETUP)
    setActive(null)
  }

  return {
    draft,
    active,
    updateField,
    beginLive,
    reset,
  }
}

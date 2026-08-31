import { useRef, useState } from 'react'

function aggregateGiftEvents(events) {
  const giftsById = new Map()
  const giftersByName = new Map()
  let giftCount = 0
  let totalGiftCoins = 0

  for (const event of events) {
    giftCount += event.quantity
    totalGiftCoins += event.totalCoins

    const giftEntry = giftsById.get(event.giftId) || {
      giftId: event.giftId,
      label: event.label,
      symbol: event.symbol,
      quantity: 0,
      totalCoins: 0,
    }
    giftEntry.quantity += event.quantity
    giftEntry.totalCoins += event.totalCoins
    giftsById.set(event.giftId, giftEntry)

    const gifterEntry = giftersByName.get(event.sender) || {
      sender: event.sender,
      giftCount: 0,
      totalCoins: 0,
    }
    gifterEntry.giftCount += event.quantity
    gifterEntry.totalCoins += event.totalCoins
    giftersByName.set(event.sender, gifterEntry)
  }

  return {
    giftCount,
    totalGiftCoins,
    giftBreakdown: [...giftsById.values()].sort((a, b) => b.totalCoins - a.totalCoins),
    gifters: [...giftersByName.values()].sort((a, b) => b.totalCoins - a.totalCoins),
  }
}

export function useLiveSessionSummary() {
  const [summary, setSummary] = useState(null)
  const startedAtRef = useRef(null)
  const giftEventsRef = useRef([])

  const beginSession = ({ title } = {}) => {
    startedAtRef.current = Date.now()
    giftEventsRef.current = []
    setSummary(null)
    return title || 'Live session'
  }

  const recordGift = ({ gift, quantity, sender, totalCoins }) => {
    if (!startedAtRef.current || !gift) return
    giftEventsRef.current = [...giftEventsRef.current, {
      giftId: gift.id,
      label: gift.label,
      symbol: gift.activityEmoji || gift.emoji || '✦',
      quantity,
      sender: sender || 'Fameverse viewer',
      totalCoins: Number.isFinite(totalCoins) ? totalCoins : gift.cost * quantity,
    }]
  }

  const finishSession = ({ title, viewerCount = 0 } = {}) => {
    const endedAt = Date.now()
    const startedAt = startedAtRef.current || endedAt
    const giftTotals = aggregateGiftEvents(giftEventsRef.current)

    setSummary({
      title: title || 'Live session',
      startedAt,
      endedAt,
      durationMs: Math.max(0, endedAt - startedAt),
      viewerCount,
      ...giftTotals,
      cashEarnings: null,
    })

    startedAtRef.current = null
    giftEventsRef.current = []
  }

  const dismissSummary = () => setSummary(null)

  const clear = () => {
    startedAtRef.current = null
    giftEventsRef.current = []
    setSummary(null)
  }

  return {
    summary,
    beginSession,
    recordGift,
    finishSession,
    dismissSummary,
    clear,
  }
}

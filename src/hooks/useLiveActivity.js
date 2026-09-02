import { useCallback, useEffect, useRef, useState } from 'react'
import { createGifterBadge } from '../features/badges/gifterBadgeSystem.js'
import {
  createLiveActivityChannel,
  removeLiveActivityChannel,
  sendLiveActivity,
} from '../services/live/liveActivity.js'

function makeActivityId(prefix) {
  if (globalThis.crypto?.randomUUID) return `${prefix}-${globalThis.crypto.randomUUID()}`
  return `${prefix}-${Date.now()}-${Math.random().toString(36).slice(2, 9)}`
}

export function useLiveActivity({ roomId, displayName, enabled, setMessages, onRemoteGift }) {
  const channelRef = useRef(null)
  const remoteGiftRef = useRef(onRemoteGift)
  const [state, setState] = useState('idle')

  useEffect(() => {
    remoteGiftRef.current = onRemoteGift
  }, [onRemoteGift])

  useEffect(() => {
    if (!enabled || !roomId) {
      setState('idle')
      return undefined
    }

    let active = true
    const channel = createLiveActivityChannel(roomId)
    channelRef.current = channel
    setState('connecting')

    channel
      .on('broadcast', { event: 'comment' }, ({ payload }) => {
        if (!active || !payload?.text || !payload?.user) return
        setMessages((items) => [...items, {
          id: payload.id || makeActivityId('comment'),
          user: payload.user,
          text: String(payload.text).slice(0, 160),
        }])
      })
      .on('broadcast', { event: 'gift' }, ({ payload }) => {
        if (!active || !payload?.gift?.id || !payload?.sender) return
        const quantity = Math.max(1, Number(payload.quantity) || 1)
        const gift = payload.gift
        const activityEmoji = gift.activityEmoji || gift.emoji || '✦'
        setMessages((items) => [...items, {
          id: payload.id || makeActivityId('gift'),
          kind: 'gift',
          user: payload.sender,
          badge: createGifterBadge(),
          giftId: gift.id,
          quantity,
          text: `${activityEmoji} sent ${gift.label} ×${quantity}`,
        }])
        remoteGiftRef.current?.(gift, quantity, payload.sender)
      })
      .subscribe((status) => {
        if (!active) return
        if (status === 'SUBSCRIBED') setState('ready')
        else if (status === 'CHANNEL_ERROR' || status === 'TIMED_OUT') setState('degraded')
      })

    return () => {
      active = false
      channelRef.current = null
      void removeLiveActivityChannel(channel)
    }
  }, [enabled, roomId, setMessages])

  const sendComment = useCallback((text) => {
    const normalized = String(text || '').trim().slice(0, 160)
    if (!roomId || !normalized) return false

    const payload = {
      id: makeActivityId('comment'),
      user: displayName || 'Fameverse User',
      text: normalized,
    }
    setMessages((items) => [...items, payload])
    void sendLiveActivity(channelRef.current, 'comment', payload)
    return true
  }, [displayName, roomId, setMessages])

  const sendGift = useCallback(({ gift, quantity, sender }) => {
    if (!roomId || !gift?.id) return false
    const payload = {
      id: makeActivityId('gift'),
      sender: sender || displayName || 'Fameverse User',
      quantity: Math.max(1, Number(quantity) || 1),
      gift: {
        id: gift.id,
        label: gift.label,
        emoji: gift.emoji,
        activityEmoji: gift.activityEmoji,
        rendererId: gift.rendererId || null,
        cinematic: Boolean(gift.cinematic),
      },
    }
    void sendLiveActivity(channelRef.current, 'gift', payload)
    return true
  }, [displayName, roomId])

  return { state, sendComment, sendGift }
}

import { useCallback, useEffect, useRef, useState } from 'react'
import { TAP_NETWORK_BATCH_MAX } from '../features/taps/tapIntegrityConfig.js'
import { submitLiveTapBatch } from '../services/live/liveTaps.js'

const TAP_FLUSH_MS = 1200
const TAP_FLUSH_AT = Math.min(100, TAP_NETWORK_BATCH_MAX)

function makeBatchId() {
  if (globalThis.crypto?.randomUUID) return `tap-${globalThis.crypto.randomUUID()}`
  return `tap-${Date.now()}-${Math.random().toString(36).slice(2, 10)}`
}

export function useViewerTapCapture({ roomId }) {
  const bufferedTimesRef = useRef([])
  const queueRef = useRef([])
  const drainingRef = useRef(false)
  const [localTapCount, setLocalTapCount] = useState(0)
  const [state, setState] = useState('idle')
  const [lastResult, setLastResult] = useState(null)

  const queueBufferedTaps = useCallback(() => {
    const absoluteTimes = bufferedTimesRef.current
    if (!absoluteTimes.length) return

    bufferedTimesRef.current = []
    const first = absoluteTimes[0]
    queueRef.current.push({
      batchId: makeBatchId(),
      timestamps: absoluteTimes.map((value) => Math.max(0, value - first)),
    })
  }, [])

  const drainQueue = useCallback(async () => {
    if (!roomId || drainingRef.current || !queueRef.current.length) return
    drainingRef.current = true
    setState('sending')

    try {
      while (queueRef.current.length) {
        const batch = queueRef.current[0]
        const { result, error } = await submitLiveTapBatch({
          roomId,
          batchId: batch.batchId,
          timestamps: batch.timestamps,
        })

        if (error) {
          setState('degraded')
          return
        }

        queueRef.current.shift()
        setLastResult(result)
        setState(result?.classification === 'rejected' ? 'rejected' : 'ready')
      }
    } finally {
      drainingRef.current = false
    }
  }, [roomId])

  const flush = useCallback(() => {
    queueBufferedTaps()
    void drainQueue()
  }, [drainQueue, queueBufferedTaps])

  const tap = useCallback(() => {
    if (!roomId) return
    bufferedTimesRef.current.push(performance.now())
    setLocalTapCount((count) => count + 1)
    if (bufferedTimesRef.current.length >= TAP_FLUSH_AT) flush()
  }, [flush, roomId])

  useEffect(() => {
    bufferedTimesRef.current = []
    queueRef.current = []
    setLocalTapCount(0)
    setLastResult(null)
    setState(roomId ? 'ready' : 'idle')
    if (!roomId) return undefined

    const timer = window.setInterval(flush, TAP_FLUSH_MS)
    return () => {
      window.clearInterval(timer)
      queueBufferedTaps()
      void drainQueue()
    }
  }, [drainQueue, flush, queueBufferedTaps, roomId])

  return {
    tap,
    flush,
    localTapCount,
    state,
    lastResult,
  }
}

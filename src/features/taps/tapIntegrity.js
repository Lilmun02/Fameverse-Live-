import { TAP_INTEGRITY_VERSION, TAP_LEDGER_SOURCE } from './tapIntegrityConfig.js'

function positiveInteger(value) {
  const number = Number(value)
  return Number.isFinite(number) && number > 0 ? Math.floor(number) : 0
}

export function createIntegrityVerifiedTapEvent(result = {}) {
  const actorId = String(result.actorId || '').trim()
  const roomId = String(result.roomId || '').trim()
  const batchId = String(result.batchId || '').trim()
  const eligibleTapCount = positiveInteger(result.eligibleTapCount)

  if (result.source !== TAP_LEDGER_SOURCE) return null
  if (result.integrityVersion !== TAP_INTEGRITY_VERSION) return null
  if (!actorId || !roomId || !batchId || eligibleTapCount < 1) return null

  return Object.freeze({
    type: 'tap',
    actorId,
    value: eligibleTapCount,
    integrityVerified: true,
    integrityVersion: TAP_INTEGRITY_VERSION,
    sessionId: roomId,
    batchId,
  })
}

export function getTapIntegrityStatus() {
  return Object.freeze({
    version: TAP_INTEGRITY_VERSION,
    rawTapCap: null,
    authoritativeLedger: true,
    visibleTotalsConnected: true,
    viewerCaptureConnected: true,
    liveCaptureConnected: true,
  })
}

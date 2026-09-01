export const LIVE_PRESENCE_VERSION = 'FAM-LIVE-PRESENCE-1'
export const LIVE_PRESENCE_HEARTBEAT_MS = 15000
export const LIVE_PRESENCE_STALE_MS = 45000

export const LIVE_PRESENCE_STATES = Object.freeze({
  IDLE: 'idle',
  STARTING: 'starting',
  LIVE: 'live',
  DEGRADED: 'degraded',
  ENDING: 'ending',
})

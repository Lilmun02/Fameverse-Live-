import { supabase } from '../supabase.js'

const STUN_SERVERS = [
  'stun:stun.l.google.com:19302',
  'stun:stun1.l.google.com:19302',
]

function buildIceServers() {
  const servers = [{ urls: STUN_SERVERS }]
  const turnUrl = String(import.meta.env.VITE_TURN_URL || '').trim()
  if (!turnUrl) return servers

  servers.push({
    urls: turnUrl,
    username: String(import.meta.env.VITE_TURN_USERNAME || ''),
    credential: String(import.meta.env.VITE_TURN_CREDENTIAL || ''),
  })
  return servers
}

export const LIVE_RELAY_ICE_SERVERS = buildIceServers()

export function createLiveRelayChannel(roomId) {
  if (!roomId) throw new Error('missing-live-room')
  return supabase.channel(`live-relay:${roomId}`, {
    config: {
      broadcast: { ack: false, self: false },
    },
  })
}

export function sendLiveRelayEvent(channel, event, payload = {}) {
  if (!channel) return Promise.resolve('error')
  return channel.send({ type: 'broadcast', event, payload })
}

export function removeLiveRelayChannel(channel) {
  if (!channel) return Promise.resolve('ok')
  return supabase.removeChannel(channel)
}

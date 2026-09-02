import { supabase } from '../supabase.js'

export function createLiveActivityChannel(roomId) {
  if (!roomId) throw new Error('missing-live-room')
  return supabase.channel(`live-activity:${roomId}`, {
    config: {
      broadcast: { ack: false, self: false },
    },
  })
}

export function sendLiveActivity(channel, event, payload = {}) {
  if (!channel) return Promise.resolve('error')
  return channel.send({ type: 'broadcast', event, payload })
}

export function removeLiveActivityChannel(channel) {
  if (!channel) return Promise.resolve('ok')
  return supabase.removeChannel(channel)
}

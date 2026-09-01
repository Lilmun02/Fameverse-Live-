import assert from 'node:assert/strict'
import { readFile } from 'node:fs/promises'
import {
  LIVE_PRESENCE_HEARTBEAT_MS,
  LIVE_PRESENCE_STALE_MS,
  LIVE_PRESENCE_VERSION,
} from '../src/services/live/livePresenceConfig.js'

const read = (path) => readFile(new URL(`../${path}`, import.meta.url), 'utf8')

assert.equal(LIVE_PRESENCE_VERSION, 'FAM-LIVE-PRESENCE-1')
assert.ok(LIVE_PRESENCE_HEARTBEAT_MS >= 5000, 'Heartbeat must not hammer the backend.')
assert.ok(
  LIVE_PRESENCE_STALE_MS >= LIVE_PRESENCE_HEARTBEAT_MS * 3,
  'Stale window must tolerate at least three heartbeat intervals.',
)

const [service, hook, app, liveHeader, packageJson, migration] = await Promise.all([
  read('src/services/live/livePresence.js'),
  read('src/hooks/useLivePresence.js'),
  read('src/App.jsx'),
  read('src/components/live/LiveHeader.jsx'),
  read('package.json'),
  read('supabase/migrations/20260901_add_live_presence_rooms.sql'),
])

assert.match(service, /from\('live_rooms'\)/, 'Live Presence must use the authoritative live_rooms table.')
assert.match(service, /heartbeat_at/, 'Live Presence must maintain a heartbeat.')
assert.match(service, /status: 'ended'/, 'Live Presence must explicitly end rooms.')
assert.match(service, /LIVE_PRESENCE_STALE_MS/, 'Active-room discovery must reject stale heartbeats.')
assert.match(hook, /setInterval\(heartbeat, LIVE_PRESENCE_HEARTBEAT_MS\)/, 'Live heartbeat loop is missing.')
assert.match(app, /startPresence\(roomTitle\)/, 'Go Live must publish authoritative presence.')
assert.match(app, /endPresence\(\)/, 'End Live must close authoritative presence.')
assert.match(liveHeader, /LIVE · SYNCED/, 'Phone diagnostics must expose synced Live presence.')
assert.match(packageJson, /"check:presence"/, 'Production build must run the Live Presence guard.')
assert.match(migration, /live_rooms_one_active_per_host/, 'Database must enforce one active room per host.')
assert.match(migration, /enable row level security/, 'Live rooms must keep RLS enabled.')

console.log(`Live Presence checks passed (${LIVE_PRESENCE_VERSION}): one room per host, heartbeat expiry, RLS, start/end coordination guarded.`)

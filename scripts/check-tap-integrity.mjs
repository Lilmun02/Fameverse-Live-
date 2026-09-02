import assert from 'node:assert/strict'
import { readFileSync } from 'node:fs'
import {
  TAP_INTEGRITY_VERSION,
  TAP_LEDGER_SOURCE,
  TAP_NETWORK_BATCH_MAX,
} from '../src/features/taps/tapIntegrityConfig.js'
import {
  createIntegrityVerifiedTapEvent,
  getTapIntegrityStatus,
} from '../src/features/taps/tapIntegrity.js'

const migration = readFileSync(new URL('../supabase/migrations/20260902_add_authoritative_live_tap_ledger.sql', import.meta.url), 'utf8')
const service = readFileSync(new URL('../src/services/live/liveTaps.js', import.meta.url), 'utf8')
const totalsHook = readFileSync(new URL('../src/hooks/useLiveTapTotals.js', import.meta.url), 'utf8')

assert.equal(TAP_INTEGRITY_VERSION, 'FAM-TAP-2')
assert.equal(TAP_NETWORK_BATCH_MAX, 200, 'Network batching may be bounded, but total Fame Taps must not be capped.')

const status = getTapIntegrityStatus()
assert.equal(status.rawTapCap, null)
assert.equal(status.authoritativeLedger, true)
assert.equal(status.visibleTotalsConnected, true)
assert.equal(status.viewerCaptureConnected, false, 'Do not claim viewer tap capture before a real viewer Live surface exists.')

assert.match(migration, /create table if not exists public\.live_tap_totals/i)
assert.match(migration, /create table if not exists public\.live_tap_batches/i)
assert.match(migration, /create or replace function public\.record_live_tap_batch/i)
assert.match(migration, /security definer/i)
assert.match(migration, /host_self_tap/)
assert.match(migration, /replayed_batch/)
assert.match(migration, /impossible_rate/)
assert.match(migration, /batch_too_large/)
assert.match(migration, /unique \(room_id, actor_user_id, batch_id\)/i)
assert.match(migration, /grant execute on function public\.record_live_tap_batch[\s\S]*to authenticated/i)
assert.match(migration, /integrity_version text not null default 'FAM-TAP-2'/i)

assert.match(service, /\.rpc\('record_live_tap_batch'/)
assert.match(service, /\.from\('live_tap_totals'\)/)
assert.match(totalsHook, /getLiveTapTotals\(roomId\)/)

const verifiedEvent = createIntegrityVerifiedTapEvent({
  source: TAP_LEDGER_SOURCE,
  integrityVersion: TAP_INTEGRITY_VERSION,
  actorId: 'viewer-1',
  roomId: 'room-1',
  batchId: 'batch-0001',
  eligibleTapCount: 1250,
})
assert.equal(verifiedEvent?.type, 'tap')
assert.equal(verifiedEvent?.integrityVerified, true)
assert.equal(verifiedEvent?.value, 1250)

assert.equal(createIntegrityVerifiedTapEvent({
  source: 'client_guess',
  integrityVersion: TAP_INTEGRITY_VERSION,
  actorId: 'viewer-1',
  roomId: 'room-1',
  batchId: 'batch-0002',
  eligibleTapCount: 1250,
}), null, 'Client-classified tap values must not become verified Verse Momentum events.')

console.log(`Tap Integrity checks passed (${status.version}): authoritative ledger guarded, raw taps uncapped, viewer capture intentionally pending.`)

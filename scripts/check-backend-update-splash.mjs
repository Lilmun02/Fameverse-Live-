import assert from 'node:assert/strict'
import { readFileSync } from 'node:fs'

function read(path) {
  return readFileSync(new URL(`../${path}`, import.meta.url), 'utf8')
}

const main = read('src/main.jsx')
const updater = read('src/services/app/pwaUpdate.js')
const index = read('index.html')
const migration = read('supabase/migrations/20260920_add_backend_release_gate.sql')

const preflightIndex = main.indexOf('await prepareFameverseBeforeMount()')
const renderIndex = main.indexOf('ReactDOM.createRoot')

assert.ok(preflightIndex >= 0, 'Fameverse must run the backend update preflight before app mount.')
assert.ok(renderIndex > preflightIndex, 'React must not mount until the backend update preflight finishes.')
assert.match(updater, /from\('app_release_state'\)/, 'Splash updater must read the backend release state from Supabase.')
assert.match(updater, /backend_revision/, 'Splash updater must compare the authoritative backend revision.')
assert.match(updater, /Updating Fameverse…/, 'Splash must visibly report when a backend release is being applied.')
assert.match(updater, /serviceWorker\.register\('\/sw\.js', \{ updateViaCache: 'none' \}\)/, 'Backend update gate must refresh the canonical service worker.')
assert.match(updater, /forceNewestShell/, 'Backend update gate must reload once into the newest shell before app entry.')
assert.doesNotMatch(updater, /fv-update-notice/, 'Backend updates must not render a floating notice inside the running app.')
assert.doesNotMatch(updater, /setInterval\(/, 'Backend release checks must not poll inside the running app.')
assert.match(index, /data-fameverse-boot-status/, 'The splash screen must expose a status target for update progress.')
assert.match(migration, /create table if not exists public\.app_release_state/, 'Backend release state must be persistent in Supabase.')
assert.match(migration, /backend_revision bigint/, 'Backend release state must expose a monotonic revision.')
assert.match(migration, /grant select on public\.app_release_state to anon, authenticated/, 'Splash must be able to read release state before authentication finishes.')

console.log('[backend-update-splash-law] backend-only release gate runs on the splash before React mounts; in-app update popups and polling stay banned')

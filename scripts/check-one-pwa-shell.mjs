import assert from 'node:assert/strict'
import { readFileSync } from 'node:fs'

function read(path) {
  return readFileSync(new URL(`../${path}`, import.meta.url), 'utf8')
}

const serviceWorker = read('public/sw.js')
const updater = read('src/services/app/pwaUpdate.js')
const vercel = read('vercel.json')

assert.doesNotMatch(
  serviceWorker,
  /addEventListener\(['"]fetch['"]|self\.addEventListener\(['"]fetch['"]/, 
  'Canonical PWA shell must not be intercepted by a service-worker fetch cache.',
)
assert.match(serviceWorker, /caches\.keys\(\)/, 'Canonical-shell worker must enumerate legacy caches.')
assert.match(serviceWorker, /keys\.map\(\(key\) => caches\.delete\(key\)\)/, 'Canonical-shell worker must delete all legacy CacheStorage entries.')
assert.match(serviceWorker, /self\.skipWaiting\(\)/, 'Canonical-shell worker must activate immediately.')
assert.match(serviceWorker, /self\.clients\.claim\(\)/, 'Canonical-shell worker must claim existing installed PWA windows.')
assert.match(serviceWorker, /FAMEVERSE_UPDATE_READY/, 'Canonical-shell worker must notify open clients after migration.')

assert.match(updater, /purgeLegacyCaches/, 'PWA updater must defensively purge leftover CacheStorage entries.')
assert.match(updater, /serviceWorker\.register\('\/sw\.js', \{ updateViaCache: 'none' \}\)/, 'PWA updater must always fetch the current service worker.')
assert.match(updater, /registration\.update\(\)/, 'PWA updater must explicitly check for the current worker.')
assert.match(updater, /shellAssetSignature/, 'PWA updater must detect when the running hashed shell differs from production.')
assert.match(updater, /fv-force-refresh/, 'PWA updater must reload into the current network shell when a new build exists.')

for (const source of ['/sw.js', '/manifest.webmanifest', '/', '/index.html']) {
  assert.ok(vercel.includes(`\"source\": \"${source}\"`), `Vercel must define cache policy for ${source}.`)
}
assert.match(vercel, /no-store, max-age=0, must-revalidate/, 'Canonical shell endpoints must be delivered without browser caching.')

console.log('One-PWA canonical-shell guard passed: no SW fetch cache, legacy caches purge, current worker polling, and no-store shell delivery are locked.')

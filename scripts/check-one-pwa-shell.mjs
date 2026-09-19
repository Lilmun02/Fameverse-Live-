import assert from 'node:assert/strict'
import { readFileSync } from 'node:fs'

function read(path) {
  return readFileSync(new URL(`../${path}`, import.meta.url), 'utf8')
}

const serviceWorker = read('public/sw.js')
const updater = read('src/services/app/pwaUpdate.js')
const vercel = read('vercel.json')
const liveScreen = read('src/components/live/LiveScreen.jsx')
const liveLayout = read('src/styles/live/live-layout-v1-refinement.css')

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
assert.match(serviceWorker, /one-canonical-pwa-shell-v2/, 'Canonical-shell migration generation must be current.')

assert.match(updater, /purgeLegacyCaches/, 'PWA updater must defensively purge leftover CacheStorage entries.')
assert.match(updater, /serviceWorker\.register\('\/sw\.js', \{ updateViaCache: 'none' \}\)/, 'PWA updater must always fetch the current service worker.')
assert.match(updater, /registration\.update\(\)/, 'PWA updater must explicitly check for the current worker.')
assert.match(updater, /shellAssetSignature/, 'PWA updater must detect when the running hashed shell differs from production.')
assert.match(updater, /fv-force-refresh/, 'PWA updater must reload into the current network shell when a new build exists.')

assert.doesNotMatch(liveScreen, /iP\(ad\|hone\|od\)|isiOS|iOSWebKit|navigator\.standalone|userAgent/, 'Live runtime must not branch into an iOS-only shell.')
assert.doesNotMatch(liveScreen, /visualViewport|--fv-visible-viewport-height/, 'Live runtime must not inject platform-specific viewport geometry.')
assert.match(liveScreen, /One-PWA law/, 'Live runtime must document the shared-shell contract.')
assert.match(liveLayout, /background:\s*transparent\s*!important/, 'Canonical Live camera shell must not restore the legacy fade overlay.')
assert.doesNotMatch(liveLayout, /iOS may refresh|Safari\/WebKit/, 'Canonical Live layout must not describe or depend on platform-specific geometry.')

for (const source of ['/sw.js', '/manifest.webmanifest', '/', '/index.html']) {
  assert.ok(vercel.includes(`\"source\": \"${source}\"`), `Vercel must define cache policy for ${source}.`)
}
assert.match(vercel, /no-store, max-age=0, must-revalidate/, 'Canonical shell endpoints must be delivered without browser caching.')

console.log('One-PWA canonical-shell guard passed: one runtime, no iOS branch, no SW shell cache, no legacy fade, and no-store delivery are locked.')

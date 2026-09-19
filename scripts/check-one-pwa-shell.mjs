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

assert.ok(!serviceWorker.includes("addEventListener('fetch'") && !serviceWorker.includes('addEventListener("fetch"'), 'Canonical worker must not intercept app-shell fetches.')
assert.ok(serviceWorker.includes('caches.keys()'), 'Canonical worker must enumerate legacy caches.')
assert.ok(serviceWorker.includes('keys.map((key) => caches.delete(key))'), 'Canonical worker must delete every legacy CacheStorage entry.')
assert.ok(serviceWorker.includes('self.skipWaiting()'), 'Canonical worker must activate immediately.')
assert.ok(serviceWorker.includes('self.clients.claim()'), 'Canonical worker must claim installed PWA windows.')
assert.ok(serviceWorker.includes('one-canonical-pwa-shell-v2'), 'Canonical worker must use the current migration generation.')

assert.ok(updater.includes('purgeLegacyCaches'), 'Updater must defensively purge leftover CacheStorage entries.')
assert.ok(updater.includes("serviceWorker.register('/sw.js', { updateViaCache: 'none' })"), 'Updater must fetch the current worker without cache reuse.')
assert.ok(updater.includes('registration.update()'), 'Updater must explicitly check for the current worker.')
assert.ok(updater.includes('shellAssetSignature'), 'Updater must compare the running hashed shell with production.')
assert.ok(updater.includes('fv-force-refresh'), 'Updater must reload into the current network shell when needed.')

for (const forbidden of ['userAgent', 'navigator.standalone', 'isiOS', 'iOSWebKit', 'visualViewport', '--fv-visible-viewport-height']) {
  assert.ok(!liveScreen.includes(forbidden), `LiveScreen must not contain platform-specific shell token: ${forbidden}`)
}
assert.ok(liveScreen.includes('One-PWA law'), 'Live runtime must document the shared-shell contract.')
assert.ok(liveLayout.includes('background: transparent !important;'), 'Shared Live camera shell must not restore the legacy fade overlay.')

for (const source of ['/sw.js', '/manifest.webmanifest', '/', '/index.html']) {
  assert.ok(vercel.includes(`\"source\": \"${source}\"`), `Vercel must define no-store delivery for ${source}.`)
}
assert.ok(vercel.includes('no-store, max-age=0, must-revalidate'), 'Canonical shell endpoints must be delivered without browser caching.')

console.log('One-PWA shell guard passed: one runtime, no platform branch, no cached app shell, no legacy camera fade, and no-store delivery.')

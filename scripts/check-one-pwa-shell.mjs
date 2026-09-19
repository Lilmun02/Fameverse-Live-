import assert from 'node:assert/strict'
import { readFileSync } from 'node:fs'

function read(path) {
  return readFileSync(new URL(`../${path}`, import.meta.url), 'utf8')
}

function count(source, token) {
  return source.split(token).length - 1
}

const serviceWorker = read('public/sw.js')
const updater = read('src/services/app/pwaUpdate.js')
const vercel = read('vercel.json')
const main = read('src/main.jsx')
const app = read('src/App.jsx')
const liveScreen = read('src/components/live/LiveScreen.jsx')
const liveLayout = read('src/styles/live/live-layout-v1-refinement.css')
const liveContract = read('src/styles/live/live-contract.css')
const nonLiveLegacy = read('src/styles/legacy/nonlive-preserved.css')
const jailedRelease = read('src/styles/legacy/disabled/live-release-shell.css')
const jailedQa = read('src/styles/legacy/disabled/live-qa-shell.css')

assert.ok(!serviceWorker.includes("addEventListener('fetch'") && !serviceWorker.includes('addEventListener("fetch"'), 'Canonical worker must not intercept app-shell fetches.')
assert.ok(serviceWorker.includes('caches.keys()'), 'Canonical worker must enumerate legacy caches.')
assert.ok(serviceWorker.includes('keys.map((key) => caches.delete(key))'), 'Canonical worker must delete every legacy CacheStorage entry.')
assert.ok(serviceWorker.includes('self.skipWaiting()'), 'Canonical worker must activate immediately.')
assert.ok(serviceWorker.includes('self.clients.claim()'), 'Canonical worker must claim installed PWA windows.')
assert.ok(serviceWorker.includes('one-canonical-pwa-shell-v3-hard-cutover'), 'Canonical worker must use the hard-cutover migration generation.')
assert.ok(serviceWorker.includes('client.navigate(url.toString())'), 'Canonical migration must hard-navigate stale installed PWA windows into the current network shell.')
assert.ok(serviceWorker.includes("const MIGRATION_PARAM = 'fv-shell-migration'"), 'Canonical migration must mark the one-time shell cutover navigation.')

assert.ok(updater.includes('purgeLegacyCaches'), 'Updater must defensively purge leftover CacheStorage entries.')
assert.ok(updater.includes("serviceWorker.register('/sw.js', { updateViaCache: 'none' })"), 'Updater must fetch the current worker without cache reuse.')
assert.ok(updater.includes('registration.update()'), 'Updater must explicitly check for the current worker.')
assert.ok(updater.includes('shellAssetSignature'), 'Updater must compare the running hashed shell with production.')
assert.ok(updater.includes('fv-force-refresh'), 'Updater must reload into the current network shell when needed.')

// Canonical shell ownership lock: old Live CSS may exist only in quarantine.
assert.ok(main.includes("./styles/legacy/nonlive-preserved.css"), 'Non-Live legacy presentation must use the preserved non-Live file.')
for (const forbiddenImport of [
  './styles/legacy/release.css',
  './styles/legacy/qa-fixes.css',
  './styles/legacy/disabled/',
]) {
  assert.ok(!main.includes(forbiddenImport), `Active bundle must not import quarantined legacy shell source: ${forbiddenImport}`)
}
assert.equal(count(main, "./styles/live/live-layout-v1-refinement.css"), 1, 'Canonical Live layout must be imported exactly once.')
assert.equal(count(main, "./styles/live/live-contract.css"), 1, 'Canonical Live contract must be imported exactly once.')
assert.ok(jailedRelease.includes('QUARANTINED — DO NOT IMPORT'), 'Historical release Live rules must remain visibly jailed.')
assert.ok(jailedQa.includes('QUARANTINED — DO NOT IMPORT'), 'Historical QA Live rules must remain visibly jailed.')

for (const forbiddenSelector of [
  '.mobile-live-shell',
  '.fam-live-',
  '.host-video',
  '.live-comment-composer',
  '.live-chat-overlay',
  '.live-action-rail',
  '.camera-off-placeholder',
]) {
  assert.ok(!nonLiveLegacy.includes(forbiddenSelector), `Preserved non-Live legacy CSS must not own Live selector: ${forbiddenSelector}`)
}

// Exactly one host Live component tree. ViewerLiveScreen is a viewer experience,
// not an iOS/Android fork of the host shell.
assert.equal(count(app, "import LiveScreen from './components/live/LiveScreen.jsx'"), 1, 'App must import exactly one host LiveScreen.')
assert.equal(count(app, '<LiveScreen'), 1, 'App must render exactly one host LiveScreen path.')

for (const forbidden of ['userAgent', 'navigator.standalone', 'isiOS', 'iOSWebKit', 'visualViewport', '--fv-visible-viewport-height']) {
  assert.ok(!liveScreen.includes(forbidden), `LiveScreen must not contain platform-specific shell token: ${forbidden}`)
}
for (const forbiddenRecovery of ['visibilitychange', 'pageshow', "addEventListener('focus'", 'srcObject = null']) {
  assert.ok(!liveScreen.includes(forbiddenRecovery), `LiveScreen must not own destructive foreground recovery: ${forbiddenRecovery}`)
}
assert.ok(!liveScreen.includes('fam-live-vignette'), 'Canonical host Live shell must not render a legacy vignette layer.')
assert.ok(liveScreen.includes('Canonical Live shell law'), 'Live runtime must document the shared-shell ownership contract.')

assert.ok(liveLayout.includes('object-fit: cover !important;'), 'Canonical Live layout must preserve full-canvas cover geometry.')
assert.ok(liveLayout.includes('One PWA Build Law'), 'Canonical Live layout must document shared geometry.')
assert.ok(liveContract.includes('Canonical active-Live contract'), 'Canonical Live contract must remain the final active-room contract.')
assert.ok(liveContract.includes('backdrop-filter: none !important;'), 'Canonical creator header must forbid blur compositing.')

for (const source of ['/sw.js', '/manifest.webmanifest', '/', '/index.html']) {
  assert.ok(vercel.includes(`\"source\": \"${source}\"`), `Vercel must define no-store delivery for ${source}.`)
}
assert.ok(vercel.includes('no-store, max-age=0, must-revalidate'), 'Canonical shell endpoints must be delivered without browser caching.')

console.log('One-PWA shell guard passed: one host tree, one active Live contract, legacy Live CSS quarantined, hard installed-PWA cutover locked, no cached app shell, and no platform presentation fork.')

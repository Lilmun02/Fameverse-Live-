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
const liveHeader = read('src/components/live/LiveHeader.jsx')
const liveActions = read('src/components/live/LiveActions.jsx')
const liveChat = read('src/components/live/LiveChat.jsx')
const freshHost = read('src/styles/live/fresh-host-live.css')
const freshBridge = read('src/styles/live/fresh-host-live-bridge.css')
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

assert.ok(updater.includes('purgeLegacyCaches'), 'Updater must defensively purge leftover CacheStorage entries.')
assert.ok(updater.includes("serviceWorker.register('/sw.js', { updateViaCache: 'none' })"), 'Updater must fetch the current worker without cache reuse.')
assert.ok(updater.includes('registration.update()'), 'Updater must explicitly check for the current worker.')

for (const forbiddenImport of [
  './styles/legacy/release.css',
  './styles/legacy/qa-fixes.css',
  './styles/legacy/disabled/',
]) {
  assert.ok(!main.includes(forbiddenImport), `Active bundle must not import quarantined legacy shell source: ${forbiddenImport}`)
}
assert.equal(count(main, "./styles/live/fresh-host-live.css"), 1, 'Fresh host Live stylesheet must be imported exactly once.')
assert.equal(count(main, "./styles/live/fresh-host-live-bridge.css"), 1, 'Fresh host Live bridge must be imported exactly once.')
assert.ok(jailedRelease.includes('QUARANTINED — DO NOT IMPORT'), 'Historical release Live rules must remain visibly jailed.')
assert.ok(jailedQa.includes('QUARANTINED — DO NOT IMPORT'), 'Historical QA Live rules must remain visibly jailed.')

for (const forbiddenSelector of ['.mobile-live-shell', '.fam-live-', '.host-video', '.live-comment-composer', '.live-chat-overlay', '.live-action-rail', '.camera-off-placeholder']) {
  assert.ok(!nonLiveLegacy.includes(forbiddenSelector), `Preserved non-Live legacy CSS must not own Live selector: ${forbiddenSelector}`)
}

assert.equal(count(app, "import LiveScreen from './components/live/LiveScreen.jsx'"), 1, 'App must import exactly one host LiveScreen.')
assert.equal(count(app, '<LiveScreen'), 1, 'App must render exactly one host LiveScreen path.')

for (const forbidden of ['userAgent', 'navigator.standalone', 'isiOS', 'iOSWebKit', 'visualViewport', '--fv-visible-viewport-height']) {
  assert.ok(!liveScreen.includes(forbidden), `LiveScreen must not contain platform-specific shell token: ${forbidden}`)
}
for (const forbiddenRecovery of ['visibilitychange', 'pageshow', "addEventListener('focus'", 'srcObject = null']) {
  assert.ok(!liveScreen.includes(forbiddenRecovery), `LiveScreen must not own destructive foreground recovery: ${forbiddenRecovery}`)
}
for (const retiredClass of ['mobile-live-shell', 'fam-live-shell', 'fam-live-video-surface', 'host-video', 'immersive-video']) {
  assert.ok(!liveScreen.includes(retiredClass), `Fresh host Live tree must not reuse retired shell class: ${retiredClass}`)
}
assert.ok(liveScreen.includes('data-fresh-host-live="true"'), 'Fresh host Live tree marker is missing.')
assert.ok(liveScreen.includes('fvx-host-live'), 'Fresh host Live root is missing.')
assert.ok(liveHeader.includes('fvx-live-header') && !liveHeader.includes('fam-live-header'), 'Fresh host header must use only the fresh presentation namespace.')
assert.ok(liveActions.includes('fvx-live-more') && liveActions.includes('fvx-live-f-menu'), 'Fresh host controls must use the fresh presentation namespace.')
assert.ok(liveChat.includes('fvx-chat-feed') && liveChat.includes('fvx-live-composer'), 'Fresh host chat/composer must use the fresh presentation namespace.')

assert.ok(freshHost.includes('.fvx-host-live {') && freshHost.includes('position: fixed;'), 'Fresh host Live root must own the viewport.')
assert.ok(freshHost.includes('height: 100dvh;'), 'Fresh host Live root must use one dynamic viewport height.')
assert.ok(freshHost.includes('.fvx-host-video') && freshHost.includes('object-fit: cover;'), 'Fresh host camera must fill its stage with cover geometry.')
assert.ok(freshHost.includes('.fvx-creator') && freshHost.includes('backdrop-filter: none;'), 'Fresh host header must explicitly forbid blur compositing.')
assert.ok(!freshHost.includes('fam-live-vignette') && !freshHost.includes('live-vignette'), 'Fresh host Live must not reintroduce a vignette/fade layer.')
assert.ok(freshBridge.includes('.live-app-shell {') && freshBridge.includes('position: static !important;'), 'Retired outer Live wrapper must be neutralized.')
assert.ok(freshBridge.includes('overflow: visible !important;'), 'Retired outer Live wrapper must not clip the fresh host viewport.')

for (const source of ['/sw.js', '/manifest.webmanifest', '/', '/index.html']) {
  assert.ok(vercel.includes(`\"source\": \"${source}\"`), `Vercel must define no-store delivery for ${source}.`)
}
assert.ok(vercel.includes('no-store, max-age=0, must-revalidate'), 'Canonical shell endpoints must be delivered without browser caching.')

console.log('One-PWA shell guard passed: fresh host Live owns one viewport, retired host shell classes are not rendered, old outer wrapper is neutralized, and platform forks remain forbidden.')

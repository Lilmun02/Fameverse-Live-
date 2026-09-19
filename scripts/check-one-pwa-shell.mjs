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
const bottomNav = read('src/components/layout/BottomNav.jsx')
const viewerContract = read('src/styles/live/viewer-contract.css')
const nonLiveLegacy = read('src/styles/legacy/nonlive-preserved.css')
const jailedRelease = read('src/styles/legacy/disabled/live-release-shell.css')
const jailedQa = read('src/styles/legacy/disabled/live-qa-shell.css')

assert.ok(!serviceWorker.includes("addEventListener('fetch'") && !serviceWorker.includes('addEventListener("fetch"'), 'Canonical worker must not intercept app-shell fetches.')
assert.ok(serviceWorker.includes('caches.keys()'), 'Canonical worker must enumerate legacy caches.')
assert.ok(serviceWorker.includes('keys.map((key) => caches.delete(key))'), 'Canonical worker must delete every legacy CacheStorage entry.')
assert.ok(serviceWorker.includes('self.skipWaiting()'), 'Canonical worker must activate immediately.')
assert.ok(serviceWorker.includes('self.clients.claim()'), 'Canonical worker must claim installed PWA windows.')
assert.ok(serviceWorker.includes('one-canonical-pwa-shell-v4-visible-updater'), 'Canonical worker must use the visible-updater migration generation.')
assert.ok(serviceWorker.includes('client.navigate(url.toString())'), 'Canonical migration must hard-navigate stale installed PWA windows into the current network shell.')
assert.ok(serviceWorker.includes("const MIGRATION_PARAM = 'fv-shell-migration'"), 'Canonical migration must mark the one-time shell cutover navigation.')

assert.ok(updater.includes('purgeLegacyCaches'), 'Updater must defensively purge leftover CacheStorage entries.')
assert.ok(updater.includes("serviceWorker.register('/sw.js', { updateViaCache: 'none' })"), 'Updater must fetch the current worker without cache reuse.')
assert.ok(updater.includes('registration.update()'), 'Updater must explicitly check for the current worker.')
assert.ok(updater.includes('shellAssetSignature'), 'Updater must compare the running hashed shell with production.')
assert.ok(updater.includes('fv-force-refresh'), 'Updater must reload into the current network shell when the user accepts an update.')
assert.ok(updater.includes('Fameverse update available'), 'Updater must expose a visible in-app update state.')
assert.ok(updater.includes('data-fameverse-update-action'), 'Updater must provide a real Update now control.')
assert.ok(updater.includes('applyUpdateNow'), 'Update control must be wired to the update action.')

// Hard-reset lock: the retired Host Live presentation is not allowed in the active bundle.
assert.ok(main.includes("./styles/legacy/nonlive-preserved.css"), 'Non-Live legacy presentation must use the preserved non-Live file.')
for (const forbiddenImport of [
  './styles/live/core.css',
  './styles/live/polish.css',
  './styles/live/fam1-shell.css',
  './styles/live/fam1-v2.css',
  './styles/live/prelive-setup.css',
  './styles/live/end-live-summary.css',
  './styles/live/live-layout-v1-refinement.css',
  './styles/live/live-contract.css',
  './styles/legacy/release.css',
  './styles/legacy/qa-fixes.css',
  './styles/legacy/disabled/',
]) {
  assert.ok(!main.includes(forbiddenImport), `Active bundle must not import retired Host Live source: ${forbiddenImport}`)
}
assert.equal(count(main, "./styles/live/viewer-contract.css"), 1, 'Viewer Live must retain one isolated viewer contract while Host Live is reset.')
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

// Host Live is completely absent from the active app until the CEO approves the rebuild.
for (const forbiddenHostRuntime of [
  "import LiveScreen from './components/live/LiveScreen.jsx'",
  '<LiveScreen',
  'useLiveMedia',
  'useLivePresence',
  'useLiveBroadcast',
  'useCohostHost',
  'useLiveSetup',
  'useLiveSessionSummary',
  'useLiveTapTotals',
  'const startLive',
  "tab === 'live'",
]) {
  assert.ok(!app.includes(forbiddenHostRuntime), `Active App must not contain Host Live runtime while reset is locked: ${forbiddenHostRuntime}`)
}

assert.ok(!bottomNav.includes("['live', 'Live']"), 'Bottom navigation must not expose a Host Live entry during the reset.')
assert.ok(!bottomNav.includes('live:'), 'Bottom navigation must not retain the Host Live icon during the reset.')

assert.ok(viewerContract.includes('.fv-viewer-live'), 'Viewer-only contract must remain scoped to Viewer Live.')
assert.ok(!viewerContract.includes('.mobile-live-shell'), 'Viewer-only contract must not reintroduce Host Live geometry.')

for (const source of ['/sw.js', '/manifest.webmanifest', '/', '/index.html']) {
  assert.ok(vercel.includes(`\"source\": \"${source}\"`), `Vercel must define no-store delivery for ${source}.`)
}
assert.ok(vercel.includes('no-store, max-age=0, must-revalidate'), 'Canonical shell endpoints must be delivered without browser caching.')

console.log('Host Live removal lock passed: no Host Live route, component, navigation entry, runtime owner, or retired Host Live CSS is active; Viewer Live remains isolated; one PWA runtime and visible updater remain locked.')

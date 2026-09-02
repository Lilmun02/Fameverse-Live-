import assert from 'node:assert/strict'
import { readFileSync } from 'node:fs'

function read(path) {
  return readFileSync(new URL(`../${path}`, import.meta.url), 'utf8')
}

const app = read('src/App.jsx')
const index = read('index.html')
const manifest = read('public/manifest.webmanifest')
const serviceWorker = read('public/sw.js')
const liveChat = read('src/components/live/LiveChat.jsx')
const viewerScreen = read('src/components/live/ViewerLiveScreen.jsx')
const viewerCss = read('src/styles/live/viewer-live.css')
const giftTray = read('src/components/gifts/LiveGiftTray.jsx')
const giftEngine = read('src/features/gifts/renderer/gift-engine.js')
const giftAudio = read('src/features/gifts/renderer/gift-audio.js')
const giftEngineCss = read('src/styles/gifts/engine.css')

assert.match(app, /SPLASH_MINIMUM_MS = 1800/, 'Splash must remain visible long enough to avoid a one-frame flash.')
assert.match(index, /name="color-scheme" content="dark"/, 'Initial document must request a dark browser surface.')
assert.match(index, /html\s*\{[\s\S]*color-scheme:\s*dark/, 'HTML must paint dark before React loads.')
assert.match(manifest, /"background_color": "#07010d"/, 'PWA launch background must match the splash.')
assert.match(serviceWorker, /APP_SHELL = \['\/'/, 'The root document must be pre-cached for instant PWA startup.')
assert.match(serviceWorker, /cache\.match\('\/'\)/, 'Navigation must have a cached root fallback.')
assert.match(serviceWorker, /if \(cached\) \{[\s\S]*event\.waitUntil\(networkPromise\)[\s\S]*return cached/, 'Navigation must return cached UI before waiting on the network.')

assert.match(liveChat, /className="live-comment-entry"[\s\S]*className="live-comment-gift"/, 'Gift control must stay attached to the chat entry pill.')
assert.match(liveChat, /className="live-comment-send"/, 'Send remains a separate compact action.')
assert.match(viewerScreen, /fv-viewer-live-name-row[\s\S]*fv-viewer-follow/, 'Follow must stay directly under the host identity.')
assert.doesNotMatch(viewerScreen, /fv-viewer-live-actions/, 'Do not restore the vertical viewer action rail.')
assert.match(viewerCss, /width:\s*min\(72vw, 300px\)/, 'Viewer composer must remain compact.')
assert.match(viewerCss, /\.fam-chat-line\s*\{[\s\S]*background:\s*transparent/, 'Normal viewer comments must remain lightweight overlays, not large cards.')
assert.doesNotMatch(viewerCss, /grid-template-columns:\s*minmax\(0, 1fr\) 43px 43px/, 'Do not detach Gift into the old three-button composer layout.')

assert.match(giftTray, /readyThumbnails/, 'Gift tray must track preview readiness.')
assert.match(giftTray, /live-gift-thumbnail-fallback/, 'Gift tray needs a branded fallback before video preview is ready.')
assert.match(giftTray, /onSeeked=/, 'Cinematic thumbnail must wait for the requested frame.')
assert.match(giftEngine, /\.mobile-live-shell\.is-live, \.fv-viewer-live/, 'Premium gifts must render for hosts and viewers.')
assert.match(giftEngine, /playGiftChime\(\)/, 'Premium gift playback must include audible Fameverse feedback.')
assert.match(giftEngine, /primeAudio:\s*primeGiftAudio/, 'Gift audio unlock must remain available to the runtime.')
assert.match(giftAudio, /AudioContext/, 'Gift audio must use an unlocked browser audio context.')
assert.match(giftAudio, /pointerdown/, 'Gift audio must be primed from a user gesture.')
assert.match(giftEngineCss, /\.fv-gift-engine\.is-playing \.fv-gift-video\s*\{\s*opacity:\s*1/, 'Premium gift video must not reveal a black frame before playback starts.')
assert.match(giftEngineCss, /\.fv-gift-engine::before/, 'Premium gift loading state must stay branded instead of black.')

console.log('Live UX checks passed: splash, compact viewer layout, gift previews, and premium gift audio are locked.')

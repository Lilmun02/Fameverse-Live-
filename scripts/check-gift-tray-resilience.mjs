import assert from 'node:assert/strict'
import { readFileSync } from 'node:fs'

function read(path) {
  return readFileSync(new URL(`../${path}`, import.meta.url), 'utf8')
}

const giftVisual = read('src/components/gifts/GiftVisual.jsx')
const giftTray = read('src/components/gifts/LiveGiftTray.jsx')
const resilienceCss = read('src/styles/gifts/resilience.css')
const giftEngine = read('src/features/gifts/renderer/gift-engine.js')
const giftEngineCss = read('src/styles/gifts/engine.css')

assert.match(giftTray, /primeGiftPosters\(gifts\)/, 'Gift posters must preload before the tray is opened.')
assert.match(giftVisual, /MAX_POSTER_RETRIES\s*=\s*2/, 'Poster load failures must retry instead of leaving Safari on a broken icon.')
assert.match(giftVisual, /posterReady \? 'is-ready' : ''/, 'Poster shell must expose an explicit ready state.')
assert.match(giftVisual, /onError[\s\S]*setPosterAttempt/, 'Poster failures must retry through controlled state.')
assert.match(resilienceCss, /\.fv-gift-poster-shell img[\s\S]*opacity:\s*0[\s\S]*visibility:\s*hidden/, 'Broken poster pixels/icons must stay hidden before load succeeds.')
assert.match(resilienceCss, /\.fv-gift-poster-shell\.is-ready img[\s\S]*opacity:\s*1[\s\S]*visibility:\s*visible/, 'Poster must reveal only after a successful load.')
assert.match(resilienceCss, /\.gift-test-sheet\.fv-gift-tray[\s\S]*display:\s*flex[\s\S]*flex-direction:\s*column/, 'Gift tray must use a shrink-safe column layout.')
assert.match(resilienceCss, /\.fv-gift-tray \.fv-gift-grid[\s\S]*flex:\s*1 1 auto[\s\S]*min-height:\s*116px[\s\S]*max-height:\s*none/, 'Gift grid must shrink/scroll before the action footer is clipped.')
assert.match(resilienceCss, /\.fv-gift-tray \.fv-gift-selection-bar[\s\S]*min-height:\s*66px[\s\S]*padding:\s*12px 2px 8px/, 'Selected gift action bar must retain breathing room.')
assert.match(resilienceCss, /padding:\s*10px 14px max\(24px, calc\(18px \+ env\(safe-area-inset-bottom\)\)\)/, 'Gift tray must reserve iOS safe-area breathing room.')

assert.match(giftEngine, /duration:\s*8500[\s\S]*id:\s*'celestial-phoenix'[\s\S]*duration:\s*8000/, 'Ember Dragon and Celestial Phoenix must retain their real cinematic durations.')
assert.match(giftEngine, /root\.style\.setProperty\('--fv-gift-duration', `\$\{config\.duration\}ms`\)/, 'Each cinematic scene must publish its own playback duration to CSS.')
assert.match(giftEngine, /const markPlaybackStarted = \(\) => \{[\s\S]*scene\.root\.classList\.add\('is-playing'\)[\s\S]*setTimeout\(finish, config\.duration \+ 1200\)/, 'Visual timing and fallback teardown must start only after real media playback begins.')
assert.match(giftEngine, /scene\.video\.onplaying = markPlaybackStarted/, 'iOS playing events must reveal the cinematic scene.')
assert.match(giftEngine, /start\?\.then\?\.\(markPlaybackStarted\)/, 'Resolved play promises must also reveal the cinematic scene if the playing event is delayed.')
assert.doesNotMatch(giftEngineCss, /\.fv-gift-engine \{[\s\S]*animation:\s*fv-gift-shell 6\.4s/, 'The cinematic shell must not use the old fixed 6.4 second timer from DOM creation.')
assert.match(giftEngineCss, /\.fv-gift-engine\.is-playing[\s\S]*animation:\s*fv-gift-shell var\(--fv-gift-duration, 6400ms\)/, 'Cinematic visibility must begin on playback and use the actual gift duration.')
assert.match(giftEngineCss, /\.fv-gift-engine\.is-playing \.fv-gift-meta[\s\S]*var\(--fv-gift-duration, 6400ms\)/, 'Gift metadata timing must stay synchronized with the cinematic playback.')

console.log('[gift-tray-resilience] poster/tray safety and playback-synced cinematic visibility are locked')

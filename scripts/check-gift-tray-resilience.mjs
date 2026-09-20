import assert from 'node:assert/strict'
import { readFileSync } from 'node:fs'

function read(path) {
  return readFileSync(new URL(`../${path}`, import.meta.url), 'utf8')
}

const giftVisual = read('src/components/gifts/GiftVisual.jsx')
const giftTray = read('src/components/gifts/LiveGiftTray.jsx')
const resilienceCss = read('src/styles/gifts/resilience.css')
const giftEngine = read('src/features/gifts/renderer/gift-engine.js')
const giftBaseCss = read('src/styles/gifts/base.css')
const giftEngineCss = read('src/styles/gifts/engine.css')

assert.match(giftTray, /primeGiftPosters\(gifts\)/, 'Gift posters must preload before the tray is opened.')
assert.match(giftVisual, /MAX_POSTER_RETRIES\s*=\s*2/, 'Poster load failures must retry instead of leaving Safari on a broken icon.')
assert.match(giftVisual, /posterReady \? 'is-ready' : ''/, 'Poster shell must expose an explicit ready state.')
assert.match(giftVisual, /image\.complete && image\.naturalWidth > 0/, 'Cached iOS poster loads must be recognized even if WebKit misses a later load event.')
assert.match(giftVisual, /fv-gift-poster-fallback/, 'Premium poster shells must have a visible fallback instead of a blank tile.')
assert.match(giftVisual, /gift\?\.rendererId && <span className="fv-gift-poster-brand">F<\/span>/, 'Cinematic gifts must remain visually identifiable in the tray.')
assert.match(giftVisual, /onError[\s\S]*setPosterAttempt/, 'Poster failures must retry through controlled state.')
assert.match(resilienceCss, /\.fv-gift-poster-fallback[\s\S]*opacity:\s*1/, 'Gift poster fallback must stay visible until the image is ready.')
assert.match(resilienceCss, /\.fv-gift-poster-shell img[\s\S]*opacity:\s*0/, 'Poster image may fade in, but the shell must retain its fallback.')
assert.doesNotMatch(resilienceCss, /\.fv-gift-poster-shell img[\s\S]*visibility:\s*hidden/, 'Gift poster images must not depend on WebKit visibility toggles that can leave cached art blank.')
assert.match(resilienceCss, /\.fv-gift-poster-shell\.is-ready img\s*\{\s*opacity:\s*1/, 'Poster must reveal after a successful or already-cached load.')
assert.match(resilienceCss, /\.fv-gift-poster-brand[\s\S]*z-index:\s*2/, 'Cinematic gift identity mark must stay above the poster.')
assert.match(resilienceCss, /\.gift-test-sheet\.fv-gift-tray[\s\S]*display:\s*flex[\s\S]*flex-direction:\s*column/, 'Gift tray must use a shrink-safe column layout.')
assert.match(resilienceCss, /\.fv-gift-tray \.fv-gift-grid[\s\S]*flex:\s*1 1 auto[\s\S]*min-height:\s*116px[\s\S]*max-height:\s*none/, 'Gift grid must shrink/scroll before the action footer is clipped.')
assert.match(resilienceCss, /\.fv-gift-tray \.fv-gift-selection-bar[\s\S]*min-height:\s*66px[\s\S]*padding:\s*12px 2px 8px/, 'Selected gift action bar must retain breathing room.')
assert.match(resilienceCss, /padding:\s*10px 14px max\(24px, calc\(18px \+ env\(safe-area-inset-bottom\)\)\)/, 'Gift tray must reserve iOS safe-area breathing room.')

assert.match(
  giftEngine,
  /\.mobile-live-shell\.is-live, \.fv2-host-live, \.fv-viewer-live/,
  'Gift engine must recognize the approved Host Live V2 shell as an active Live room.',
)
assert.match(
  giftBaseCss,
  /\.gift-overlay-simple[\s\S]*z-index:\s*1220/,
  'Simple gift overlays must render above Host Live V2.',
)
assert.match(
  giftEngineCss,
  /\.fv-gift-engine[\s\S]*z-index:\s*1230/,
  'Cinematic gift scenes must render above Host Live V2.',
)

console.log('[gift-tray-resilience] visible poster fallback/cache recovery, safe-area tray layout, and Host Live V2 gift visibility are locked')

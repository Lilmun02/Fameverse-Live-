import assert from 'node:assert/strict'
import { readFileSync } from 'node:fs'

function read(path) {
  return readFileSync(new URL(`../${path}`, import.meta.url), 'utf8')
}

const giftVisual = read('src/components/gifts/GiftVisual.jsx')
const giftTray = read('src/components/gifts/LiveGiftTray.jsx')
const resilienceCss = read('src/styles/gifts/resilience.css')

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

console.log('[gift-tray-resilience] poster preload/retry and unclipped safe-area action footer are locked')

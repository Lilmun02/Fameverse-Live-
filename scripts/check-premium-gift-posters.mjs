import assert from 'node:assert/strict'
import { readFileSync, statSync } from 'node:fs'

function read(path) {
  return readFileSync(new URL(`../${path}`, import.meta.url), 'utf8')
}

const giftConfig = read('src/config/gifts.js')
const giftTray = read('src/components/gifts/LiveGiftTray.jsx')
const giftVisual = read('src/components/gifts/GiftVisual.jsx')

const requiredPosters = [
  ['Welcome to Fameverse', '/gifts/welcome-to-fameverse-poster.webp', 'public/gifts/welcome-to-fameverse-poster.webp'],
  ['Ember Dragon', '/gifts/ember-dragon-poster.jpg', 'public/gifts/ember-dragon-poster.jpg'],
  ['Celestial Phoenix', '/gifts/celestial-phoenix-poster.jpg', 'public/gifts/celestial-phoenix-poster.jpg'],
]

for (const [label, publicPath, filePath] of requiredPosters) {
  assert.ok(giftConfig.includes(`poster: '${publicPath}'`), `${label} must use its real static tray poster.`)
  const stat = statSync(new URL(`../${filePath}`, import.meta.url))
  assert.ok(stat.size > 4000, `${label} poster must be a real image asset, not an empty placeholder.`)
}

assert.match(giftTray, /<GiftVisual gift=\{gift\}/, 'Gift cards must render through the canonical GiftVisual component.')
assert.match(giftTray, /<GiftVisual gift=\{selectedGift\}/, 'Selected gift must use the same custom poster source as its card.')
assert.doesNotMatch(giftTray, /<video|seekGiftThumbnail|onSeeked=/, 'Tray thumbnails must stay static and Safari-safe.')
assert.doesNotMatch(giftVisual, /<video|currentTime\s*=/, 'GiftVisual must never seek cinematic videos for tray artwork.')

console.log('Premium gift poster guard passed: Welcome, Ember Dragon, and Celestial Phoenix use real static tray artwork.')

import assert from 'node:assert/strict'
import { readFileSync, statSync } from 'node:fs'

function read(path) {
  return readFileSync(new URL(`../${path}`, import.meta.url), 'utf8')
}

function readBytes(path) {
  return readFileSync(new URL(`../${path}`, import.meta.url))
}

function isWebp(bytes) {
  return bytes.length >= 12
    && bytes.subarray(0, 4).toString('ascii') === 'RIFF'
    && bytes.subarray(8, 12).toString('ascii') === 'WEBP'
}

const giftConfig = read('src/config/gifts.js')
const giftTray = read('src/components/gifts/LiveGiftTray.jsx')
const giftVisual = read('src/components/gifts/GiftVisual.jsx')

const welcomePath = 'public/gifts/welcome-to-fameverse-poster.webp'
assert.ok(giftConfig.includes("poster: '/gifts/welcome-to-fameverse-poster.webp'"), 'Welcome to Fameverse must retain its static poster.')
assert.ok(isWebp(readBytes(welcomePath)), 'Welcome to Fameverse poster must remain a valid WEBP asset.')

const customPosters = [
  ['Ember Dragon', '/gifts/ember-dragon-poster.svg', 'public/gifts/ember-dragon-poster.svg', /Ember Dragon/i, /black dragon|red eyes|ember/i],
  ['Celestial Phoenix', '/gifts/celestial-phoenix-poster.svg', 'public/gifts/celestial-phoenix-poster.svg', /Celestial Phoenix/i, /phoenix|gold|purple|fire/i],
]

for (const [label, publicPath, filePath, identityPattern, artPattern] of customPosters) {
  assert.ok(giftConfig.includes(`poster: '${publicPath}'`), `${label} must use its custom static tray poster.`)
  const stat = statSync(new URL(`../${filePath}`, import.meta.url))
  assert.ok(stat.size > 1000, `${label} poster must be a substantive custom SVG asset.`)
  const svg = read(filePath)
  assert.match(svg, /<svg[\s>]/i, `${label} poster must be an SVG image.`)
  assert.match(svg, identityPattern, `${label} poster must identify the actual gift.`)
  assert.match(svg, artPattern, `${label} poster must retain its approved visual identity instead of an emoji placeholder.`)
  assert.match(svg, /data:image\/jpeg;base64,/i, `${label} poster must embed the approved real gift-frame image, not substitute drawn artwork.`)
}

assert.match(giftTray, /<GiftVisual gift=\{gift\}/, 'Gift cards must render through the canonical GiftVisual component.')
assert.match(giftTray, /<GiftVisual gift=\{selectedGift\}/, 'Selected gift must use the same custom poster source as its card.')
assert.doesNotMatch(giftTray, /<video|seekGiftThumbnail|onSeeked=/, 'Tray thumbnails must stay static and Safari-safe.')
assert.doesNotMatch(giftVisual, /<video|currentTime\s*=/, 'GiftVisual must never seek cinematic videos for tray artwork.')

console.log('Premium gift poster guard passed: Welcome uses its static poster, and Ember Dragon/Celestial Phoenix use the approved real gift-frame images with no emoji fallback.')

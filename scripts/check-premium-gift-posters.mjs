import assert from 'node:assert/strict'
import { readFileSync, statSync } from 'node:fs'

function read(path) {
  return readFileSync(new URL(`../${path}`, import.meta.url), 'utf8')
}

function readBytes(path) {
  return readFileSync(new URL(`../${path}`, import.meta.url))
}

function isJpeg(bytes) {
  return bytes.length >= 4 && bytes[0] === 0xff && bytes[1] === 0xd8 && bytes.at(-2) === 0xff && bytes.at(-1) === 0xd9
}

function isWebp(bytes) {
  return bytes.length >= 12
    && bytes.subarray(0, 4).toString('ascii') === 'RIFF'
    && bytes.subarray(8, 12).toString('ascii') === 'WEBP'
}

const giftConfig = read('src/config/gifts.js')
const giftTray = read('src/components/gifts/LiveGiftTray.jsx')
const giftVisual = read('src/components/gifts/GiftVisual.jsx')

const requiredPosters = [
  ['Welcome to Fameverse', '/gifts/welcome-to-fameverse-poster.webp', 'public/gifts/welcome-to-fameverse-poster.webp', 'webp'],
  ['Ember Dragon', '/gifts/ember-dragon-poster.jpg', 'public/gifts/ember-dragon-poster.jpg', 'jpeg'],
  ['Celestial Phoenix', '/gifts/celestial-phoenix-poster.jpg', 'public/gifts/celestial-phoenix-poster.jpg', 'jpeg'],
]

for (const [label, publicPath, filePath, format] of requiredPosters) {
  assert.ok(giftConfig.includes(`poster: '${publicPath}'`), `${label} must use its real static tray poster.`)
  const stat = statSync(new URL(`../${filePath}`, import.meta.url))
  assert.ok(stat.size > 500, `${label} poster must not be empty or a trivial placeholder.`)
  const bytes = readBytes(filePath)
  assert.ok(format === 'jpeg' ? isJpeg(bytes) : isWebp(bytes), `${label} poster must contain a valid ${format.toUpperCase()} file signature.`)
}

assert.match(giftTray, /<GiftVisual gift=\{gift\}/, 'Gift cards must render through the canonical GiftVisual component.')
assert.match(giftTray, /<GiftVisual gift=\{selectedGift\}/, 'Selected gift must use the same custom poster source as its card.')
assert.doesNotMatch(giftTray, /<video|seekGiftThumbnail|onSeeked=/, 'Tray thumbnails must stay static and Safari-safe.')
assert.doesNotMatch(giftVisual, /<video|currentTime\s*=/, 'GiftVisual must never seek cinematic videos for tray artwork.')

console.log('Premium gift poster guard passed: Welcome, Ember Dragon, and Celestial Phoenix use real static tray artwork.')

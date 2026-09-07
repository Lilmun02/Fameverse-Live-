import assert from 'node:assert/strict'
import { readFileSync } from 'node:fs'

function read(path) {
  return readFileSync(new URL(`../${path}`, import.meta.url), 'utf8')
}

const engine = read('src/features/gifts/renderer/gift-engine.js')

assert.match(engine, /const giftMediaCache = new Map\(\)/, 'Premium gift media must be cached instead of recreated for every send.')
assert.match(engine, /function getGiftVideo\(config\)/, 'Gift engine must reuse one video element per premium gift.')
assert.match(engine, /video\.preload = 'auto'/, 'Premium gift media must preload before playback.')
assert.match(engine, /function resetGiftVideo\(video\)/, 'Reused gift media must reset cleanly between combo entries.')
assert.match(engine, /document\.addEventListener\('pointerdown', primeGiftMedia/, 'The first user interaction must begin preloading premium gift media.')
assert.match(engine, /primeAudio:\s*primeGiftPlayback/, 'Gift audio priming must also prime the media cache.')
assert.doesNotMatch(engine, /removeAttribute\('src'\)/, 'Premium gift teardown must never destroy the media source between sends.')
assert.doesNotMatch(engine, /activeGift\.video\.load\(\)/, 'Premium gift teardown must never reload the decoder between sends.')

console.log('[welcome-gift-media-law] Premium gift video/audio media is preloaded, reused, reset, and never torn down between sends.')

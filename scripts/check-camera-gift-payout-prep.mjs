// Regression lock: camera flip + gift tray/payout-prep contracts.
import fs from 'node:fs'

const read = (path) => fs.readFileSync(new URL(`../${path}`, import.meta.url), 'utf8')
const media = read('src/hooks/useLiveMedia.js')
const gifts = read('src/config/gifts.js')
const visual = read('src/components/gifts/GiftVisual.jsx')
const tray = read('src/components/gifts/LiveGiftTray.jsx')
const wallet = read('src/services/giftWallet.js')

const requireText = (source, value, label) => {
  if (!source.includes(value)) throw new Error(`Fameverse regression: ${label}`)
}

requireText(media, "stagingVideo.srcObject = null", 'camera flip must reset reused iOS staging video')
requireText(media, "stagingVideo.load?.()", 'camera flip must force fresh staging geometry')
requireText(gifts, "poster: EMBER_DRAGON_VIDEO", 'Ember Dragon must have a real thumbnail source')
requireText(gifts, "poster: CELESTIAL_PHOENIX_VIDEO", 'Celestial Phoenix must have a real thumbnail source')
requireText(visual, "isVideoSource", 'cinematic gift thumbnails must support video sources')
requireText(tray, "canRefillTestCoins", 'test refill UI must be permission-gated')
if (wallet.includes("if (!data) return refillBetaWallet(10000)")) {
  throw new Error('Fameverse regression: missing wallets must never auto-seed test coins')
}
console.log('Fameverse camera/gift/payout-prep regression law passed')

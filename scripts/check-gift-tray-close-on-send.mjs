import { readFileSync } from 'node:fs'

const giftTray = readFileSync('src/components/gifts/LiveGiftTray.jsx', 'utf8')
const giftHook = readFileSync('src/hooks/useGiftSystem.js', 'utf8')

let failed = false
const assert = (condition, message) => {
  if (condition) return
  failed = true
  console.error(`[gift-tray-close-law] ${message}`)
}

assert(
  giftTray.includes('sendGift(selectedGift, 1)') && !giftTray.includes('sendGift(selectedGift, 1, { keepTrayOpen: true })'),
  'Normal selected gift sends must use the default close-after-success path.',
)
assert(
  giftTray.includes('sendGift(selectedGift, quantity)') && !giftTray.includes('sendGift(selectedGift, quantity, { keepTrayOpen: true })'),
  'Custom quantity sends must use the default close-after-success path.',
)
assert(
  giftHook.includes('if (!keepTrayOpen) setGiftTrayOpen(false)'),
  'useGiftSystem must retain backend-confirmed close behavior.',
)
assert(
  giftHook.indexOf('if (!keepTrayOpen) setGiftTrayOpen(false)') > giftHook.indexOf('if (!confirmed)'),
  'The tray may close only after a successful server-authoritative gift confirmation.',
)

if (failed) process.exit(1)
console.log('[gift-tray-close-law] successful gift sends close the tray; rejected sends keep it open')

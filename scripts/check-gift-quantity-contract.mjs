import assert from 'node:assert/strict'
import { readFileSync } from 'node:fs'

function read(path) {
  return readFileSync(new URL(`../${path}`, import.meta.url), 'utf8')
}

const giftConfig = read('src/config/gifts.js')
const giftTray = read('src/components/gifts/LiveGiftTray.jsx')
const giftSystem = read('src/hooks/useGiftSystem.js')
const liveActivity = read('src/hooks/useLiveActivity.js')
const migration = read('supabase/migrations/20260903_raise_beta_gift_quantity_contract.sql')

assert.match(giftConfig, /MAX_BETA_GIFT_QUANTITY\s*=\s*100000/, 'Client gift ceiling must remain explicit and bounded.')
assert.match(giftTray, /max=\{MAX_BETA_GIFT_QUANTITY\}/, 'Custom gift input must expose the same client ceiling.')
assert.match(giftSystem, /normalizedQuantity > MAX_BETA_GIFT_QUANTITY/, 'Gift send path must reject quantities above the shared ceiling.')
assert.match(migration, /quantity between 1 and 100000/, 'Gift ledger constraint must accept the same quantity range as the client.')
assert.match(migration, /p_quantity > 100000/, 'Gift RPC must enforce the same maximum as the ledger constraint.')
assert.match(liveActivity, /gifterLevel:\s*Math\.max\(1, Number\(gifterLevel \|\| 1\)\)/, 'Normal comments must carry the current gifter level.')
assert.match(liveActivity, /\[actorId, displayName, gifterLevel, roomId, setMessages\]/, 'Normal comment callback must refresh when the gifter level changes.')

console.log('Gift quantity contract checks passed: custom sends, ledger writes, RPC validation, and typed-message gifter identity stay synchronized.')

import assert from 'node:assert/strict'
import { readFileSync } from 'node:fs'

function read(path) {
  return readFileSync(new URL(`../${path}`, import.meta.url), 'utf8')
}

const app = read('src/App.jsx')
const giftSystem = read('src/hooks/useGiftSystem.js')
const giftHook = read('src/hooks/useGifterLevel.js')
const walletHook = read('src/hooks/useGiftWallet.js')
const walletService = read('src/services/giftWallet.js')
const gifterService = read('src/services/gifterLevels.js')
const pwa = read('src/utils/pwa.js')
const migration = read('supabase/migrations/20260906_add_authoritative_beta_wallet.sql')

assert.match(migration, /create table if not exists public\.beta_coin_wallets/, 'Gift coins must live in a server-side wallet table.')
assert.match(migration, /create table if not exists public\.beta_coin_ledger/, 'Every wallet mutation must have a persistent server ledger.')
assert.match(migration, /for update/, 'Gift debit must lock the sender wallet row before spending.')
assert.match(migration, /insufficient beta coin balance/, 'Server must reject gifts that exceed the authoritative wallet balance.')
assert.match(migration, /gift_send/, 'Gift debits must be recorded in the wallet ledger.')
assert.match(migration, /public\.gift_events/, 'Atomic gift flow must retain the server gift-event ledger.')
assert.match(migration, /public\.gifter_stats/, 'Atomic gift flow must update persistent gifter progression.')
assert.match(migration, /wallet_balance bigint/, 'Gift RPC must return the server-confirmed wallet balance.')
assert.match(migration, /revoke all privileges on table public\.beta_coin_wallets from anon, authenticated/, 'Clients must not receive direct wallet mutation privileges.')
assert.match(migration, /revoke all privileges on table public\.gifter_stats from anon, authenticated/, 'Clients must not directly mutate authoritative gifter totals.')
assert.match(migration, /grant execute on function public\.record_beta_gift/, 'Authenticated gift sends must use the controlled server RPC.')
assert.match(migration, /grant execute on function public\.refill_beta_wallet/, 'Beta refill must use the controlled server RPC.')

assert.match(walletService, /from\('beta_coin_wallets'\)/, 'Client wallet display must load the authenticated server balance.')
assert.match(walletService, /rpc\('refill_beta_wallet'/, 'Beta refill must be requested from Supabase instead of changing browser state.')
assert.match(walletHook, /loadBetaWalletBalance/, 'Signed-in users must hydrate the visible gift balance from Supabase.')
assert.match(walletHook, /applyBalance/, 'Server-confirmed balances must have one explicit state update path.')
assert.match(gifterService, /walletBalance:\s*Number\(row\?\.wallet_balance/, 'Gift RPC response must expose its server-confirmed wallet balance.')
assert.match(giftHook, /await recordBetaGift/, 'Gifter progression must wait for the server transaction instead of optimistic prediction.')
assert.doesNotMatch(giftHook, /predicted|optimistic/i, 'Gifter progression must not restore client-authoritative optimistic totals.')
assert.match(giftSystem, /await recordGifterGift/, 'Gift UI must wait for the backend transaction before displaying accepted gift activity.')
assert.match(giftSystem, /sendQueueRef/, 'Rapid gift sends must be serialized instead of racing wallet debits.')
assert.match(giftSystem, /setWalletBalance\?\.\(nextBalance\)/, 'Gift UI must adopt the balance returned by the backend transaction.')
assert.doesNotMatch(giftSystem, /localStorage|loadCoins/, 'Gift balance must never be read from or written to browser localStorage.')
assert.doesNotMatch(pwa, /loadCoins|fameverse-owner-test-coins/, 'Legacy local test-wallet helpers must stay retired.')
assert.match(app, /useGiftWallet/, 'The signed-in app must load its authoritative Supabase wallet.')
assert.match(app, /coins:\s*wallet\.balance/, 'Gift UI must display the Supabase wallet balance.')
assert.match(app, /setWalletBalance:\s*wallet\.applyBalance/, 'Server gift confirmations must update the shared wallet state.')
assert.match(app, /addTestCoins:\s*wallet\.refill/, 'Beta refill control must be wired to the server wallet RPC.')

console.log('[gift-backend-law] Supabase wallet, append-only ledger, atomic debit, server-confirmed progression, and no client-authoritative coins are locked')

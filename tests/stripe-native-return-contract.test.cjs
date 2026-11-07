// Read-only regression contract for Stripe app return.
// Run: node --test tests/stripe-native-return-contract.test.cjs
const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const root = path.resolve(__dirname, '..');
const read = (name) => fs.readFileSync(path.join(root, name), 'utf8');

test('both generated iOS shells register the same Fameverse scheme', () => {
  const yaml = read('codemagic.yaml');
  const registrations = yaml.match(/CFBundleURLSchemes:0 string fameverse/g) || [];
  assert.equal(registrations.length, 2, 'debug and TestFlight release must register scheme');
  assert.equal((yaml.match(/FlutterDeepLinkingEnabled bool false/g) || []).length, 2);
});

test('Stripe return page offers app navigation without payment operations', () => {
  const source = read('supabase/functions/stripe-return/index.ts');
  assert.match(source, /fameverse:\/\/checkout-return\?status=/);
  assert.match(source, /Return to Fameverse Live/);
  assert.match(source, /appReturnUrl/);
  assert.doesNotMatch(source, /stripe\.checkout\.sessions\.create|paymentIntents\.create|functions\.invoke\(/i);
});

test('native store refreshes wallet on resume rather than crediting from return URL', () => {
  const source = read('native/flutter_v1/lib/features/profile/fame_coin_store_screen.dart');
  assert.match(source, /AppLifecycleState\.resumed && _awaitingStripeReturn/);
  assert.match(source, /_refreshWalletAfterStripe\(\)/);
  assert.match(source, /from\('beta_coin_wallets'\)/);
});

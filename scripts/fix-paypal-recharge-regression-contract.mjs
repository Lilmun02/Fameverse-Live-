import fs from 'node:fs';

const path = 'native/flutter_v1/test/live_v2_release_contract_test.dart';
let source = fs.readFileSync(path, 'utf8');

source = source.replace(
  "'PayPal sandbox recharge is native, custom, and Vercel-free'",
  "'PayPal recharge is native, environment-aware, custom, and Vercel-free'",
);

source = source.replace(
  `        expect(screen, contains("'Complete sandbox purchase'"));\n`,
  `        expect(screen, contains("'Complete purchase'"));\n        expect(screen, contains("sandbox ? 'PAYPAL SANDBOX' : 'PAYPAL LIVE'"));\n        expect(screen, contains("'Test Fame Coin recharge'"));\n        expect(screen, contains("'Live PayPal environment'"));\n`,
);

if (source.includes("'Complete sandbox purchase'")) {
  throw new Error('stale sandbox-only PayPal copy assertion still present');
}
if (!source.includes("'PayPal recharge is native, environment-aware, custom, and Vercel-free'")) {
  throw new Error('PayPal regression test title was not updated');
}
if (!source.includes("sandbox ? 'PAYPAL SANDBOX' : 'PAYPAL LIVE'")) {
  throw new Error('environment-aware PayPal label assertion was not installed');
}
if (!source.includes("contains(\"'Test Fame Coin recharge'\")")) {
  throw new Error('environment-aware PayPal title assertion was not installed');
}

fs.writeFileSync(path, source);
console.log('PayPal recharge regression contract updated without removing coverage.');

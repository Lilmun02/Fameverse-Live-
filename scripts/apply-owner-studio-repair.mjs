import fs from 'node:fs';

function read(path) {
  return fs.readFileSync(path, 'utf8');
}

function write(path, content) {
  fs.writeFileSync(path, content);
}

function replaceRequired(source, before, after, label) {
  if (!source.includes(before)) {
    throw new Error(`owner-studio repair anchor missing: ${label}`);
  }
  return source.replace(before, after);
}

function replaceAllVisibleCurrency(source) {
  return source
    .replaceAll('Fame Coins', 'Fame Stones')
    .replaceAll('Fame Coin', 'Fame Stone');
}

const ownerPath = 'native/flutter_v1/lib/features/profile/owner_control_center_build23.dart';
let owner = read(ownerPath);

owner = replaceRequired(
  owner,
  "'get_creator_payout_moderation_queue',",
  "'get_creator_payout_moderation_queue_v2',",
  'owner payout queue v2',
);
owner = replaceRequired(
  owner,
  "title: const Text('Owner Control Center'),",
  "title: const Text('Owner Studio'),",
  'owner app bar',
);
owner = replaceRequired(
  owner,
  "title: 'Creator earnings & payout',",
  "title: 'My Creator Account',",
  'owner personal creator account title',
);
owner = replaceRequired(
  owner,
  "body:\n                      'Open your personal creator earnings, verification, PayPal payout method and payout history.',",
  "body:\n                      'Your creator earnings, verification progress, PayPal payout method and payout history live here. Owner moderation stays in Owner Studio.',",
  'owner personal creator account body',
);
owner = owner
  .replaceAll("const _Section('VERIFICATION REVIEW')", "const _Section('CREATOR VERIFICATION')")
  .replaceAll("const _Section('PAYOUT REVIEW')", "const _Section('CREATOR PAYOUTS')")
  .replaceAll("const _Section('BUSINESS MONEY')", "const _Section('PLATFORM FINANCES')")
  .replaceAll("const _Section('FAME COIN BALANCES')", "const _Section('FAME STONE BALANCES')")
  .replaceAll("const _Section('BUSINESS CASH & REWARD FUNDING')", "const _Section('REWARD FUNDING & OWNER BANKING')");

owner = replaceRequired(
  owner,
  "final amount = _money((payout['amount_cents'] as num?)?.toInt() ?? 0);",
  "final amount = _money((payout['amount_cents'] as num?)?.toInt() ?? 0);\n    final providerStatus = payout['provider_status']?.toString() ?? '';\n    final providerBatchId = payout['provider_batch_id']?.toString() ?? '';\n    final needsProviderRecovery =\n        status == 'processing' &&\n        providerBatchId.isEmpty &&\n        (providerStatus == 'SUBMISSION_UNKNOWN' ||\n            providerStatus == 'SUBMITTING');",
  'payout provider state',
);
owner = replaceRequired(
  owner,
  "Chip(label: Text('Verification: $verification')),",
  "Chip(label: Text('Verification: $verification')),\n              if (providerStatus.isNotEmpty)\n                Chip(label: Text('PayPal: ${providerStatus.replaceAll('_', ' ')}')),",
  'payout provider status chip',
);
owner = replaceRequired(
  owner,
  "          else if (status == 'processing')\n            FilledButton.icon(\n              key: const Key('owner-payout-sync-provider'),\n              onPressed: busy ? null : onSync,\n              icon: const Icon(Icons.sync_rounded),\n              label: const Text('Sync PayPal status'),\n            ),",
  "          else if (status == 'processing' && needsProviderRecovery)\n            FilledButton.icon(\n              key: const Key('owner-payout-recover-provider'),\n              onPressed: busy ? null : onProcess,\n              icon: const Icon(Icons.restart_alt_rounded),\n              label: const Text('Recover PayPal submission'),\n            )\n          else if (status == 'processing')\n            FilledButton.icon(\n              key: const Key('owner-payout-sync-provider'),\n              onPressed: busy ? null : onSync,\n              icon: const Icon(Icons.sync_rounded),\n              label: const Text('Sync PayPal status'),\n            ),",
  'payout recovery action',
);
owner = replaceRequired(
  owner,
  "          : text.contains('payout_not_processable')\n          ? 'This payout is not approved for processing.'\n          : 'Provider submission failed.';",
  "          : text.contains('paypal_submission_unknown') ||\n                text.contains('paypal_batch_id_missing')\n          ? 'PayPal submission is still unresolved. The creator funds remain reserved; use Recover PayPal submission again after refresh.'\n          : text.contains('payout_not_processable')\n          ? 'This payout is not approved for processing or recovery.'\n          : 'Provider submission failed.';",
  'payout recovery error copy',
);
owner = replaceAllVisibleCurrency(owner);
write(ownerPath, owner);

const creatorPath = 'native/flutter_v1/lib/features/profile/creator_studio_build23.dart';
let creator = read(creatorPath);
creator = replaceRequired(
  creator,
  "title: Text(widget.isOwner ? 'Owner Creator Studio' : 'Creator Studio'),",
  "title: Text(widget.isOwner ? 'My Creator Account' : 'Creator Studio'),",
  'owner creator sub-screen title',
);
creator = replaceAllVisibleCurrency(creator);
write(creatorPath, creator);

const profilePath = 'native/flutter_v1/lib/features/profile/native_profile_build23.dart';
let profile = read(profilePath);
profile = profile
  .replaceAll("isOwner ? 'Owner Creator Studio' : 'Creator Studio'", "isOwner ? 'Owner Studio' : 'Creator Studio'")
  .replaceAll("isOwner ? 'Owner Control Center' : 'Creator Studio'", "isOwner ? 'Owner Studio' : 'Creator Studio'")
  .replaceAll("? 'Premium tools, earnings and promo QA'", "? 'Moderation, payouts, platform finance and your creator account'");
profile = replaceAllVisibleCurrency(profile);
write(profilePath, profile);

for (const path of [
  'native/flutter_v1/lib/features/profile/fame_coin_store_screen.dart',
  'native/flutter_v1/lib/features/profile/coin_exchange_screen.dart',
  'native/flutter_v1/lib/features/profile/native_recharge_screen.dart',
  'native/flutter_v1/lib/features/live/native_live_components.dart',
  'native/flutter_v1/lib/features/live/stream_viewer_live_screen.dart',
]) {
  write(path, replaceAllVisibleCurrency(read(path)));
}

console.log('Owner Studio repair applied: unified owner IA, PayPal recovery action, and Fame Stones display copy.');

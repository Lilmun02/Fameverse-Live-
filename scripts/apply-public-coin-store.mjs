import fs from 'node:fs';

function read(path) {
  return fs.readFileSync(path, 'utf8');
}

function write(path, value) {
  fs.writeFileSync(path, value);
}

function replaceOnce(source, before, after, label) {
  if (source.includes(after)) return source;
  const count = source.split(before).length - 1;
  if (count !== 1) {
    throw new Error(`${label}: expected one patch target, found ${count}`);
  }
  return source.replace(before, after);
}

const profilePath = 'native/flutter_v1/lib/features/profile/native_profile_build23.dart';
let profile = read(profilePath);
profile = replaceOnce(
  profile,
  "import '../../data/fameverse_beta_backend.dart';\n",
  "import '../../data/fameverse_beta_backend.dart';\nimport 'fame_coin_store_screen.dart';\n",
  'profile store import',
);
profile = replaceOnce(
  profile,
  `  Future<void> _load() async {\n    if (mounted) setState(() => _loading = true);\n    try {\n      final row = await Supabase.instance.client\n          .from('beta_coin_wallets')\n          .select('balance')\n          .eq('user_id', widget.userId)\n          .maybeSingle();\n      if (!mounted) return;\n      setState(() {\n        _balance = (row?['balance'] as num?)?.toInt() ?? 0;\n        _loading = false;\n      });\n    } catch (_) {\n      if (mounted) setState(() => _loading = false);\n    }\n  }\n\n  @override\n`,
  `  Future<void> _load() async {\n    if (mounted) setState(() => _loading = true);\n    try {\n      final row = await Supabase.instance.client\n          .from('beta_coin_wallets')\n          .select('balance')\n          .eq('user_id', widget.userId)\n          .maybeSingle();\n      if (!mounted) return;\n      setState(() {\n        _balance = (row?['balance'] as num?)?.toInt() ?? 0;\n        _loading = false;\n      });\n    } catch (_) {\n      if (mounted) setState(() => _loading = false);\n    }\n  }\n\n  Future<void> _openStore() async {\n    await Navigator.of(context).push<void>(\n      MaterialPageRoute(\n        builder: (_) => FameCoinStoreScreen(\n          userId: widget.userId,\n          onBalanceChanged: (balance) {\n            if (mounted) setState(() => _balance = balance);\n          },\n        ),\n      ),\n    );\n    if (mounted) await _load();\n  }\n\n  @override\n`,
  'profile store route',
);
profile = replaceOnce(
  profile,
  `          IconButton(\n            onPressed: _loading ? null : _load,\n            icon: _loading\n                ? const SizedBox(\n                    width: 17,\n                    height: 17,\n                    child: CircularProgressIndicator(strokeWidth: 2),\n                  )\n                : const Icon(Icons.refresh_rounded),\n          ),\n`,
  `          Row(\n            mainAxisSize: MainAxisSize.min,\n            children: [\n              FilledButton.tonal(\n                key: const Key('profile-buy-fame-coins'),\n                onPressed: _loading ? null : _openStore,\n                child: const Text('Buy'),\n              ),\n              IconButton(\n                onPressed: _loading ? null : _load,\n                tooltip: 'Refresh Fame Coins',\n                icon: _loading\n                    ? const SizedBox(\n                        width: 17,\n                        height: 17,\n                        child: CircularProgressIndicator(strokeWidth: 2),\n                      )\n                    : const Icon(Icons.refresh_rounded),\n              ),\n            ],\n          ),\n`,
  'profile buy button',
);
write(profilePath, profile);

const trayPath = 'native/flutter_v1/lib/features/live/native_live_components.dart';
let tray = read(trayPath);
tray = replaceOnce(
  tray,
  `    required this.onRefill,\n    this.onExchange,\n    super.key,\n`,
  `    required this.onRefill,\n    this.onBuyCoins,\n    this.onExchange,\n    super.key,\n`,
  'gift tray constructor',
);
tray = replaceOnce(
  tray,
  `  final Future<int> Function() onRefill;\n  final VoidCallback? onExchange;\n`,
  `  final Future<int> Function() onRefill;\n  final VoidCallback? onBuyCoins;\n  final VoidCallback? onExchange;\n`,
  'gift tray field',
);
tray = replaceOnce(
  tray,
  `                const Spacer(),\n                if (widget.onExchange != null)\n`,
  `                const Spacer(),\n                if (widget.onBuyCoins != null)\n                  TextButton(\n                    key: const Key('gift-tray-buy-coins'),\n                    onPressed: _sending ? null : widget.onBuyCoins,\n                    child: const Text('Buy coins'),\n                  ),\n                if (widget.onExchange != null)\n`,
  'gift tray buy button',
);
write(trayPath, tray);

const viewerPath = 'native/flutter_v1/lib/features/live/stream_viewer_live_screen.dart';
let viewer = read(viewerPath);
viewer = replaceOnce(
  viewer,
  `import '../../data/fameverse_live_backend.dart';\nimport 'native_live_components.dart';\n`,
  `import '../../data/fameverse_live_backend.dart';\nimport '../profile/fame_coin_store_screen.dart';\nimport 'native_live_components.dart';\n`,
  'viewer store import',
);
viewer = replaceOnce(
  viewer,
  `        _walletBalance == 0\n            ? 'No beta test balance is available on this account.'\n            : 'Test balance is too low for that gift.',\n`,
  `        _walletBalance == 0\n            ? 'Your Fame Coin balance is empty.'\n            : 'Your Fame Coin balance is too low for that gift.',\n`,
  'viewer low balance copy',
);
viewer = replaceOnce(
  viewer,
  `      if (text.contains('insufficient beta coin balance')) {\n        _showMessage('Test balance is too low for that gift.');\n      } else if (text.contains('beta wallet unavailable')) {\n        _showMessage('No beta test balance is available on this account.');\n`,
  `      if (text.contains('insufficient beta coin balance')) {\n        _showMessage('Your Fame Coin balance is too low for that gift.');\n      } else if (text.contains('beta wallet unavailable')) {\n        _showMessage('Your Fame Coin wallet is unavailable right now.');\n`,
  'viewer backend wallet copy',
);
viewer = replaceOnce(
  viewer,
  `  void _showGiftTray() {\n    FocusManager.instance.primaryFocus?.unfocus();\n    showModalBottomSheet<void>(\n      context: context,\n      isScrollControlled: true,\n      backgroundColor: const Color(0xFF140D1B),\n      builder: (context) => NativeGiftTray(\n        coins: _walletBalance,\n        canRefill: _canRefill,\n        onSend: _sendGift,\n        onRefill: _refillWallet,\n      ),\n    ).then((_) {\n      if (mounted) setState(() {});\n    });\n  }\n`,
  `  Future<void> _openCoinStore() async {\n    await Navigator.of(context).push<void>(\n      MaterialPageRoute(\n        builder: (_) => FameCoinStoreScreen(\n          userId: widget.identity.id,\n          onBalanceChanged: (balance) {\n            if (!mounted) return;\n            setState(() {\n              _walletBalance = balance;\n              _walletReady = true;\n            });\n          },\n        ),\n      ),\n    );\n    try {\n      final balance = await widget.liveBackend.loadWalletBalance(\n        widget.identity.id,\n      );\n      if (mounted) {\n        setState(() {\n          _walletBalance = balance;\n          _walletReady = true;\n        });\n      }\n    } catch (_) {}\n  }\n\n  void _showGiftTray() {\n    FocusManager.instance.primaryFocus?.unfocus();\n    showModalBottomSheet<void>(\n      context: context,\n      isScrollControlled: true,\n      backgroundColor: const Color(0xFF140D1B),\n      builder: (sheetContext) => NativeGiftTray(\n        coins: _walletBalance,\n        canRefill: _canRefill,\n        onSend: _sendGift,\n        onRefill: _refillWallet,\n        onBuyCoins: () {\n          Navigator.of(sheetContext).pop();\n          WidgetsBinding.instance.addPostFrameCallback((_) {\n            if (mounted) unawaited(_openCoinStore());\n          });\n        },\n      ),\n    ).then((_) {\n      if (mounted) setState(() {});\n    });\n  }\n`,
  'viewer gift tray store route',
);
write(viewerPath, viewer);

const testPath = 'native/flutter_v1/test/public_fame_coin_store_contract_test.dart';
if (!fs.existsSync(testPath)) {
  write(
    testPath,
    `import 'dart:io';\n\nimport 'package:flutter_test/flutter_test.dart';\n\nvoid main() {\n  String file(String path) => File(path).readAsStringSync();\n\n  test('public Fame Coin store is wired to Apple IAP and server verification', () {\n    final pubspec = file('pubspec.yaml');\n    final store = file('lib/features/profile/fame_coin_store_screen.dart');\n    final profile = file('lib/features/profile/native_profile_build23.dart');\n    final tray = file('lib/features/live/native_live_components.dart');\n    final viewer = file('lib/features/live/stream_viewer_live_screen.dart');\n\n    expect(pubspec, contains('in_app_purchase: ^3.3.1'));\n    expect(store, contains('InAppPurchase.instance'));\n    expect(store, contains('_store.purchaseStream.listen'));\n    expect(store, contains('_store.buyConsumable'));\n    expect(store, contains('applicationUserName: widget.userId'));\n    expect(store, contains('serverVerificationData'));\n    expect(store, contains("'iap-purchase'"));\n    expect(store, contains('completePurchase(purchase)'));\n    expect(profile, contains("Key('profile-buy-fame-coins')"));\n    expect(profile, contains('FameCoinStoreScreen('));\n    expect(tray, contains("Key('gift-tray-buy-coins')"));\n    expect(viewer, contains('onBuyCoins: ()'));\n    expect(viewer, contains('Your Fame Coin balance is empty.'));\n  });\n\n  test('server purchase ledger is idempotent and verifier is account-bound', () {\n    final migration = file('../../supabase/migrations/20261001_public_fame_coin_store.sql');\n    final function = file('../../supabase/functions/iap-purchase/index.ts');\n\n    expect(migration, contains('unique (platform, transaction_id)'));\n    expect(migration, contains('finalize_fame_coin_store_purchase'));\n    expect(migration, contains('to service_role'));\n    expect(migration, contains("'purchase'"));\n    expect(function, contains('SignedDataVerifier'));\n    expect(function, contains('com.fameverse.live'));\n    expect(function, contains('verified.appAccountToken !== user.id'));\n    expect(function, contains('apple-transaction-verification-failed'));\n    expect(function, contains('finalize_fame_coin_store_purchase'));\n  });\n}\n`,
  );
}

console.log('Public Fame Coin store wiring applied.');

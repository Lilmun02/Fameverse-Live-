import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  String file(String path) => File(path).readAsStringSync();

  test(
    'public Fame Coin store is wired to Apple IAP and server verification',
    () {
      final pubspec = file('pubspec.yaml');
      final store = file('lib/features/profile/fame_coin_store_screen.dart');
      final profile = file('lib/features/profile/native_profile_build23.dart');
      final tray = file('lib/features/live/native_live_components.dart');
      final viewer = file('lib/features/live/stream_viewer_live_screen.dart');

      expect(pubspec, contains('in_app_purchase: ^3.3.1'));
      expect(store, contains('InAppPurchase.instance'));
      expect(store, contains('_store.purchaseStream.listen'));
      expect(store, contains('_store.buyConsumable'));
      expect(store, contains('applicationUserName: widget.userId'));
      expect(store, contains('serverVerificationData'));
      expect(store, contains("'iap-purchase'"));
      expect(store, contains('completePurchase(purchase)'));
      expect(profile, contains("Key('profile-buy-fame-coins')"));
      expect(profile, contains('FameCoinStoreScreen('));
      expect(tray, contains("Key('gift-tray-buy-coins')"));
      expect(viewer, contains('onBuyCoins: ()'));
      expect(viewer, contains('Your Fame Coin balance is empty.'));
    },
  );

  test(
    'server purchase ledger is idempotent and verifier is account-bound',
    () {
      final migration = file(
        '../../supabase/migrations/20261001_public_fame_coin_store.sql',
      );
      final function = file('../../supabase/functions/iap-purchase/index.ts');

      expect(migration, contains('unique (platform, transaction_id)'));
      expect(migration, contains('finalize_fame_coin_store_purchase'));
      expect(migration, contains('to service_role'));
      expect(migration, contains("'purchase'"));
      expect(function, contains('SignedDataVerifier'));
      expect(function, contains('com.fameverse.live'));
      expect(function, contains('verified.appAccountToken !== user.id'));
      expect(function, contains('apple-transaction-verification-failed'));
      expect(function, contains('finalize_fame_coin_store_purchase'));
    },
  );
}

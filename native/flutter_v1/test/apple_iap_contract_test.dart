import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Apple Fame Coin purchases use StoreKit and server verification only', () {
    final store = File(
      'lib/features/profile/fame_coin_store_screen.dart',
    ).readAsStringSync();
    final purchase = File(
      'lib/features/profile/fame_coin_purchase_flow.part.dart',
    ).readAsStringSync();
    final view = File(
      'lib/features/profile/fame_coin_store_view.part.dart',
    ).readAsStringSync();
    final server = File(
      '../../supabase/functions/iap-purchase/index.ts',
    ).readAsStringSync();

    expect(store, contains('InAppPurchase.instance'));
    expect(store, contains('_store.purchaseStream.listen'));
    expect(store, contains('_store.queryProductDetails'));
    expect(store, contains('_store.buyConsumable'));
    expect(store, contains('applicationUserName: widget.userId'));

    expect(purchase, contains('serverVerificationData'));
    expect(purchase, contains("'iap-purchase'"));
    expect(purchase, contains("'platform': 'ios'"));
    expect(purchase, contains("'signed_transaction': signedTransaction"));
    expect(purchase, contains('_store.completePurchase(purchase)'));

    expect(server, contains('SignedDataVerifier'));
    expect(server, contains('Environment.SANDBOX'));
    expect(server, contains('Environment.PRODUCTION'));
    expect(server, contains('verified.appAccountToken !== user.id'));
    expect(server, contains('finalize_fame_coin_store_purchase'));

    expect(store, contains('if (Platform.isIOS)'));
    expect(view, contains('if (!Platform.isIOS) ...['));
    expect(
      view,
      contains(
        'TestFlight and Apple Sandbox purchases add Test Coins. App Store production purchases add Real Coins.',
      ),
    );
  });
}

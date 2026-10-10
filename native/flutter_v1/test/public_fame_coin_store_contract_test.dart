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
      expect(store, contains("'Fameverse Coin Packs'"));
      expect(store, contains('onPressed: anotherPurchaseBusy ? null'));
      expect(store, contains('PurchaseStatus.canceled'));
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

  test('Stripe purchases use hosted Checkout and server-only fulfillment', () {
    final pubspec = file('pubspec.yaml');
    final store = file('lib/features/profile/fame_coin_store_screen.dart');
    final checkout = file(
      '../../supabase/functions/stripe-checkout-session/index.ts',
    );
    final webhook = file('../../supabase/functions/stripe-webhook/index.ts');
    final migration = file(
      '../../supabase/migrations/20261001220728_stripe_checkout_fame_coins.sql',
    );

    expect(pubspec, contains('url_launcher: ^6.3.2'));
    expect(store, contains("'stripe-checkout-session'"));
    expect(store, contains("'action': 'config'"));
    expect(store, contains("'action': 'create'"));
    expect(store, contains("'pack_id': offer.id"));
    expect(store, contains('LaunchMode.externalApplication'));
    expect(store, contains('WidgetsBindingObserver'));
    expect(store, contains('AppLifecycleState.resumed'));
    expect(store, contains('STRIPE TEST'));
    expect(store, contains('STRIPE LIVE'));

    expect(checkout, contains('STRIPE_TEST_SECRET_KEY'));
    expect(checkout, contains('STRIPE_LIVE_SECRET_KEY'));
    expect(checkout, contains('mode", "payment"'));
    expect(checkout, contains('ui_mode", "hosted_page"'));
    expect(checkout, contains('origin_context", "mobile_app"'));
    expect(checkout, contains('line_items[0][price]'));
    expect(checkout, contains('pack_id'));
    expect(checkout, isNot(contains('amount_cents = Number(body')));

    expect(webhook, contains('Stripe-Signature'));
    expect(webhook, contains('STRIPE_TEST_WEBHOOK_SECRET'));
    expect(webhook, contains('STRIPE_LIVE_WEBHOOK_SECRET'));
    expect(webhook, contains('checkout.session.completed'));
    expect(webhook, contains('payment_status'));
    expect(webhook, contains('finalize_coin_recharge'));

    expect(migration, contains("'stripe'::text"));
    expect(migration, contains("'stripe-100'"));
    expect(migration, contains("'stripe-1000'"));
    expect(migration, contains("'stripe-5000'"));
  });

  test('Stripe test discount pricing cannot overwrite live pricing', () {
    final checkout = file(
      '../../supabase/functions/stripe-checkout-session/index.ts',
    );
    final migration = file(
      '../../supabase/migrations/20261001224000_stripe_environment_specific_discount_pricing.sql',
    );

    expect(checkout, contains('stripe_test_price_cents'));
    expect(checkout, contains('stripe_live_price_cents'));
    expect(checkout, contains('priceForEnvironment(pack, environment)'));
    expect(checkout, contains('amount_cents: priceCents'));
    expect(checkout, contains('amount_cents: priceCents'));

    expect(migration, contains('stripe_test_price_cents = 139'));
    expect(migration, contains('stripe_test_price_cents = 909'));
    expect(migration, contains('stripe_test_price_cents = 4199'));
    expect(migration, contains("'price_1ULsXqGeOlZfST4Ee00wiGch'"));
    expect(migration, contains("'price_1ULsXuGeOlZfST4EGJPGeDKe'"));
    expect(migration, contains("'price_1ULsXzGeOlZfST4EUHiURh4p'"));

    // Live price objects stay on the previously validated live catalog until
    // sandbox checkout + webhook + wallet-credit QA passes.
    expect(migration, contains('stripe_live_price_cents = 99'));
    expect(migration, contains('stripe_live_price_cents = 999'));
    expect(migration, contains('stripe_live_price_cents = 4999'));
  });

  test(
    'server purchase ledger is idempotent and Apple verifier is account-bound',
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

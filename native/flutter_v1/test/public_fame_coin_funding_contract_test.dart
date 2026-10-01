import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('paid App Store Fame Coins enter the cash-backed funding bucket', () {
    final migration = File(
      '../../supabase/migrations/20261001_public_fame_coin_store_funding_provenance.sql',
    ).readAsStringSync();

    expect(migration, contains('finalize_fame_coin_store_purchase'));
    expect(migration, contains('public._credit_fame_coins('));
    expect(migration, contains('v_product.coins,'));
    expect(migration, contains("'purchase',"));
    expect(
      migration,
      contains("'store:' || v_platform || ':' || p_transaction_id"),
    );
    expect(
      migration,
      contains('to service_role'),
      reason: 'Only the verified server path may finalize paid purchases.',
    );
    expect(
      migration,
      contains('from public, anon, authenticated'),
      reason: 'Clients must never mint paid coins directly.',
    );
  });
}

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('verified store purchases preserve real versus test funding', () {
    final migration = File(
      '../../supabase/migrations/20261006212000_enforce_real_test_purchase_funding.sql',
    ).readAsStringSync();

    expect(migration, contains('finalize_fame_coin_store_purchase'));
    expect(migration, contains("v_environment='sandbox'"));
    expect(
      migration,
      contains(
        "p_user_id,0,v_product.coins,'store_purchase_test'",
      ),
      reason: 'Apple Sandbox purchases must create Test Coins only.',
    );
    expect(
      migration,
      contains(
        "p_user_id,v_product.coins,0,'store_purchase_real'",
      ),
      reason: 'Apple Production purchases must create Real Coins.',
    );
    expect(migration, contains('environment text not null default'));
    expect(migration, contains("'recharge_test'"));
    expect(migration, contains("'recharge_real'"));
    expect(migration, contains("'refund_test'"));
    expect(migration, contains("'refund_real'"));
  });
}

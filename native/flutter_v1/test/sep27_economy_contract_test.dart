import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

String _readMigration(String name) {
  return File('../../supabase/migrations/$name').readAsStringSync();
}

void main() {
  test('Sep 27 economy stays at 70/30 and 100 coins per dollar', () {
    final sql = _readMigration('20260927_lock_creator_split_70_30.sql');
    expect(sql, contains('creator_share_bps = 7000'));
    expect(sql, contains('platform_share_bps = 3000'));
    expect(sql, contains('coins_per_usd = 100'));
    expect(sql, isNot(contains('creator_share_bps = 8000')));
  });

  test('Coin Exchange is one-way and replay protected', () {
    final economy = _readMigration(
      '20260927_sep27_economy_referrals_exchange.sql',
    );
    final replay = _readMigration(
      '20260927_sep27_economy_idempotency_fix.sql',
    );

    expect(economy, contains('exchange_creator_earnings_for_coins'));
    expect(economy, contains("'coin_exchange'"));
    expect(economy, contains('-p_amount_cents'));
    expect(economy, contains("'creator_earnings_exchange'"));
    expect(economy, contains('unique (user_id, idempotency_key)'));
    expect(
      economy,
      isNot(contains('exchange_coins_for_creator_earnings')),
    );
    expect(replay, contains('if v_key is not null and exists'));
    expect(replay, contains('return coalesce(v_balance, 0)'));
  });

  test('Referral rewards are promotional and never cash-backed', () {
    final economy = _readMigration(
      '20260927_sep27_economy_referrals_exchange.sql',
    );
    final qualification = _readMigration(
      '20260927_sep27_economy_idempotency_fix.sql',
    );

    expect(economy, contains("v_referrer, 0, 100, 'beta_referral_reward'"));
    expect(economy, contains("v_user, 0, 50, 'beta_referral_welcome'"));
    expect(economy, contains('promo_coins'));
    expect(qualification, contains('email_confirmed_at'));
    expect(qualification, contains('complete a Fameverse activity'));
    expect(qualification, contains('self referral is not allowed'));
  });

  test('Visible Fame Coin balance is separate from funding buckets', () {
    final economy = _readMigration(
      '20260927_sep27_economy_referrals_exchange.sql',
    );
    expect(economy, contains('cash_backed_coins'));
    expect(economy, contains('promo_coins'));
    expect(economy, contains('beta_coin_wallets'));
    expect(economy, contains('get_fame_coin_balance'));
  });
}

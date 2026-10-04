import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('backend money integrity contract', () {
    test('PayPal temporary holds remain syncable instead of becoming terminal', () {
      final sync = File(
        '../../supabase/functions/sync-creator-payout/index.ts',
      ).readAsStringSync();
      final queue = File(
        '../../supabase/migrations/20261004224500_keep_paypal_holds_syncable.sql',
      ).readAsStringSync();

      expect(sync, contains('let fameverseStatus = "processing";'));
      expect(sync, contains('itemStatus === "SUCCESS"'));
      expect(sync, isNot(contains('fameverseStatus = "held"')));
      expect(queue, contains("'processing', 'held'"));
    });

    test('verification gates require 100 followers and 500k cash-backed coins', () {
      final migration = File(
        '../../supabase/migrations/20261004224000_creator_verification_eligibility.sql',
      ).readAsStringSync();

      expect(migration, contains('100::bigint'));
      expect(migration, contains('500000::bigint'));
      expect(migration, contains('funding.cash_backed_coins'));
      expect(migration, contains('gift.sender_user_id <> gift.recipient_user_id'));
      expect(migration, contains('v_followers < 100 or v_received < 500000'));
    });

    test('supporter rankings exclude QA and promotional funding', () {
      final migration = File(
        '../../supabase/migrations/20261004223000_exclude_qa_from_fameboard_supporters.sql',
      ).readAsStringSync();

      expect(migration, contains('gift_funding_breakdowns'));
      expect(migration, contains('sum(f.cash_backed_coins)'));
      expect(migration, contains('f.cash_backed_coins > 0'));
      expect(migration, contains('g.sender_user_id <> g.recipient_user_id'));
    });

    test('creator payout reads are not granted to anon', () {
      final migration = File(
        '../../supabase/migrations/20261004224800_lock_creator_payout_reads.sql',
      ).readAsStringSync();

      for (final signature in <String>[
        'get_creator_payout_method()',
        'get_creator_payout_requests(integer)',
        'get_creator_payout_summary()',
      ]) {
        expect(migration, contains('revoke all on function public.$signature from anon;'));
        expect(migration, contains('grant execute on function public.$signature to authenticated;'));
      }
    });
  });
}

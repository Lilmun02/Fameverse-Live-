import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('backend money integrity contract', () {
    test(
      'PayPal temporary holds remain syncable instead of becoming terminal',
      () {
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
      },
    );

    test('PayPal ambiguous submission stays reserved and is idempotent', () {
      final process = File(
        '../../supabase/functions/process-creator-payout/index.ts',
      ).readAsStringSync();
      final sync = File(
        '../../supabase/functions/sync-creator-payout/index.ts',
      ).readAsStringSync();
      final retry = File(
        '../../supabase/migrations/20261004225000_retry_unknown_paypal_submission.sql',
      ).readAsStringSync();

      expect(process, contains(r'const senderBatchId = `fv-${payoutId}`;'));
      expect(process, contains('"PayPal-Request-Id": senderBatchId'));
      expect(process, contains('provider_status: "SUBMISSION_UNKNOWN"'));
      expect(process, contains('status: "processing"'));
      expect(
        process,
        isNot(
          contains('status: "failed",\n      provider_status: "NETWORK_ERROR"'),
        ),
      );
      expect(sync, contains('provider_recovery_failed'));
      expect(sync, contains('/functions/v1/process-creator-payout'));
      expect(retry, contains("'SUBMISSION_UNKNOWN', 'SUBMITTING'"));
      expect(retry, contains('v_request.provider_batch_id is null'));
    });

    test('PayPal duplicate batch recovery scans nested provider links safely', () {
      final process = File(
        '../../supabase/functions/process-creator-payout/index.ts',
      ).readAsStringSync();

      expect(
        process,
        contains('Object.values(value as Record<string, unknown>)'),
      );
      expect(process, contains('providerErrorName === "DUPLICATE_BATCH_ID"'));
      expect(process, contains('const duplicateBatchId = payoutBatchIdFromLinks'));
      expect(
        process,
        contains('provider_status: "SUBMISSION_UNKNOWN"'),
      );
      expect(
        process,
        contains('Keep payout reserved and recover through the idempotent provider flow.'),
      );
    });

    test('unknown PayPal submission cannot be manually released or paid', () {
      final guard = File(
        '../../supabase/migrations/20261005190000_protect_unknown_paypal_submission.sql',
      ).readAsStringSync();

      expect(guard, contains("p_status = 'failed'"));
      expect(guard, contains("'SUBMISSION_UNKNOWN'"));
      expect(guard, contains("'SUBMITTING'"));
      expect(guard, contains('PayPal provider failure confirmation required'));
      expect(guard, contains("p_status = 'paid'"));
      expect(guard, contains("v_provider_status <> 'SUCCESS'"));
      expect(guard, contains('PayPal SUCCESS confirmation required'));
      expect(guard, contains("set status = 'processing'"));
      expect(guard, contains("provider_status = 'SUBMISSION_UNKNOWN'"));
      expect(guard, contains("where status = 'failed'"));
    });

    test(
      'verification gates require 100 followers and 500k cash-backed coins',
      () {
        final migration = File(
          '../../supabase/migrations/20261004224000_creator_verification_eligibility.sql',
        ).readAsStringSync();

        expect(migration, contains('100::bigint'));
        expect(migration, contains('500000::bigint'));
        expect(migration, contains('funding.cash_backed_coins'));
        expect(
          migration,
          contains('gift.sender_user_id <> gift.recipient_user_id'),
        );
        expect(migration, contains('v_followers < 100 or v_received < 500000'));
      },
    );

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
        expect(
          migration,
          contains('revoke all on function public.$signature from anon;'),
        );
        expect(
          migration,
          contains(
            'grant execute on function public.$signature to authenticated;',
          ),
        );
      }
    });
  });
}

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Owner Studio repair contract', () {
    test('owner surfaces use one Owner Studio information architecture', () {
      final owner = File(
        'lib/features/profile/owner_control_center_build23.dart',
      ).readAsStringSync();
      final creator = File(
        'lib/features/profile/creator_studio_build23.dart',
      ).readAsStringSync();
      final profile = File(
        'lib/features/profile/native_profile_build23.dart',
      ).readAsStringSync();

      expect(owner, contains("title: const Text('Owner Studio')"));
      expect(owner, contains("title: 'My Creator Account'"));
      expect(creator, contains("'My Creator Account' : 'Creator Studio'"));
      expect(profile, contains("isOwner ? 'Owner Studio' : 'Creator Studio'"));
      expect(owner, contains("const _Section('CREATOR VERIFICATION')"));
      expect(owner, contains("const _Section('CREATOR PAYOUTS')"));
      expect(owner, contains("const _Section('PLATFORM FINANCES')"));
    });

    test('ambiguous PayPal payouts expose a real recovery action', () {
      final owner = File(
        'lib/features/profile/owner_control_center_build23.dart',
      ).readAsStringSync();
      final migration = File(
        '../../supabase/migrations/20261005214500_owner_payout_recovery_queue_v2.sql',
      ).readAsStringSync();

      expect(owner, contains('get_creator_payout_moderation_queue_v2'));
      expect(owner, contains("payout['provider_status']"));
      expect(owner, contains("payout['provider_batch_id']"));
      expect(owner, contains("providerStatus == 'SUBMISSION_UNKNOWN'"));
      expect(owner, contains("providerStatus == 'SUBMITTING'"));
      expect(owner, contains("Key('owner-payout-recover-provider')"));
      expect(owner, contains('Recover PayPal submission'));
      expect(owner, contains('creator funds remain reserved'));
      expect(migration, contains('provider_status text'));
      expect(migration, contains('provider_batch_id text'));
      expect(migration, contains("'pending_review', 'approved', 'processing', 'held'"));
    });

    test('buyer and creator-facing currency copy is Fame Stones', () {
      final creator = File(
        'lib/features/profile/creator_studio_build23.dart',
      ).readAsStringSync();
      final owner = File(
        'lib/features/profile/owner_control_center_build23.dart',
      ).readAsStringSync();
      final store = File(
        'lib/features/profile/fame_coin_store_screen.dart',
      ).readAsStringSync();
      final giftTray = File(
        'lib/features/live/native_live_components.dart',
      ).readAsStringSync();

      expect(creator, contains('Fame Stones'));
      expect(owner, contains('Fame Stones'));
      expect(store, contains('Fame Stones'));
      expect(giftTray, contains('Fame Stones'));
    });
  });
}

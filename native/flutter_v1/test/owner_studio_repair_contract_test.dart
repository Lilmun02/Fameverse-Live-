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
      expect(
        migration,
        contains("'pending_review', 'approved', 'processing', 'held'"),
      );
    });

    test('payout processing and verification review state stay visible', () {
      final creator = File(
        'lib/features/profile/creator_studio_build23.dart',
      ).readAsStringSync();
      final backend = File(
        'lib/data/fameverse_creator_backend.dart',
      ).readAsStringSync();
      final owner = File(
        'lib/features/profile/owner_control_center_build23.dart',
      ).readAsStringSync();
      final migration = File(
        '../../supabase/migrations/20261006023500_build32_payout_verification_observability.sql',
      ).readAsStringSync();

      expect(backend, contains('providerStatusUpdatedAt'));
      expect(backend, contains("row['provider_status']"));
      expect(backend, contains("row['public_note']"));
      expect(creator, contains("Key('creator-payout-provider-status')"));
      expect(creator, contains('Funds remain reserved'));
      expect(creator, contains("Key('creator-verification-status')"));
      expect(
        creator,
        contains('Verification is processing in Fameverse review'),
      );
      expect(owner, contains('Some owner data could not refresh'));
      expect(owner, contains('verificationResult'));
      expect(migration, contains('provider_status_updated_at timestamptz'));
      expect(migration, contains('public_note text'));
    });

    test('buyer and creator-facing currency copy is Fame Coins', () {
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

      expect(creator, contains('Fame Coins'));
      expect(owner, contains('Fame Coins'));
      expect(store, contains('Fame Coins'));
      expect(giftTray, contains('Fame Coin balance'));
    });
  });
}

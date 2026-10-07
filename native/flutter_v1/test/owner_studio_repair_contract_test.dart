import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Owner web control and native Creator Studio contract', () {
    test('owner operations stay on web while native stays creator-facing', () {
      final shell = File(
        'lib/features/shell/fameverse_shell_build23.dart',
      ).readAsStringSync();
      final creator = File(
        'lib/features/profile/creator_studio_build23.dart',
      ).readAsStringSync();
      final profile = File(
        'lib/features/profile/native_profile_build23.dart',
      ).readAsStringSync();
      final webOwner = File(
        '../../src/components/owner/OwnerControlCenter.jsx',
      ).readAsStringSync();

      expect(shell, contains('Build23CreatorStudioScreen'));
      expect(shell, isNot(contains('Build23OwnerControlCenterScreen')));
      expect(shell, isNot(contains('owner_control_center_build23.dart')));
      expect(creator, contains("title: const Text('Creator Studio')"));
      expect(creator, contains("Key('creator-fam-algorithm-card')"));
      expect(creator, contains("Key('creator-badges-card')"));
      expect(creator, contains("Key('creator-gift-activity-card')"));
      expect(creator, contains("Key('creator-verification-center')"));
      expect(profile, contains("label: 'Creator Studio'"));
      expect(profile, isNot(contains('Owner Studio')));
      expect(webOwner, contains('Control Center'));
      expect(webOwner, contains('Payout Queue'));
      expect(webOwner, contains('Release to PayPal'));
      expect(webOwner, contains('Active Live Sessions'));
    });

    test('ambiguous PayPal payouts expose recovery on the web control path', () {
      final webOwner = File(
        '../../src/components/owner/OwnerControlCenter.jsx',
      ).readAsStringSync();
      final ownerService = File(
        '../../src/services/ownerControl.js',
      ).readAsStringSync();
      final migration = File(
        '../../supabase/migrations/20261005214500_owner_payout_recovery_queue_v2.sql',
      ).readAsStringSync();

      expect(webOwner, contains('syncPayout'));
      expect(
        webOwner,
        contains("['processing', 'held'].includes(payout.status)"),
      );
      expect(webOwner, contains('Sync PayPal'));
      expect(ownerService, contains('get_creator_payout_moderation_queue_v2'));
      expect(ownerService, contains('sync-creator-payout'));
      expect(migration, contains('provider_status text'));
      expect(migration, contains('provider_batch_id text'));
      expect(
        migration,
        contains("'pending_review', 'approved', 'processing', 'held'"),
      );
    });

    test(
      'creator payout and verification state stay visible in native studio',
      () {
        final creator = File(
          'lib/features/profile/creator_studio_build23.dart',
        ).readAsStringSync();
        final backend = File(
          'lib/data/fameverse_creator_backend.dart',
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
        expect(migration, contains('provider_status_updated_at timestamptz'));
        expect(migration, contains('public_note text'));
      },
    );

    test('buyer and creator-facing currency copy is Fame Coins', () {
      final creator = File(
        'lib/features/profile/creator_studio_build23.dart',
      ).readAsStringSync();
      final store = File(
        'lib/features/profile/fame_coin_store_screen.dart',
      ).readAsStringSync();
      final giftTray = File(
        'lib/features/live/native_live_components.dart',
      ).readAsStringSync();

      expect(creator, contains('Fame Coins'));
      expect(store, contains('Fame Coins'));
      expect(giftTray, contains('Fame Coin balance'));
    });
  });
}

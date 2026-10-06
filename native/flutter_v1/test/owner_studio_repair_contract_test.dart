import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  String files(List<String> paths) =>
      paths.map((path) => File(path).readAsStringSync()).join('\n');

  final owner = () => files([
        'lib/features/profile/owner_control_center_build23.dart',
        'lib/features/profile/owner_control_center_dialogs.part.dart',
        'lib/features/profile/owner_control_center_view.part.dart',
        'lib/features/profile/owner_control_center_review_cards.part.dart',
        'lib/features/profile/owner_control_center_widgets.part.dart',
      ]);
  final creator = () => files([
        'lib/features/profile/creator_studio_build23.dart',
        'lib/features/profile/creator_studio_build23_summary.part.dart',
        'lib/features/profile/creator_studio_build23_verification.part.dart',
        'lib/features/profile/creator_studio_build23_payout.part.dart',
        'lib/features/profile/creator_studio_build23_payout_actions.part.dart',
      ]);
  final profile = () => files([
        'lib/features/profile/native_profile_build23.dart',
        'lib/features/profile/native_profile_build23_identity.part.dart',
        'lib/features/profile/native_profile_build23_settings.part.dart',
      ]);
  final giftTray = () => files([
        'lib/features/live/native_live_components.dart',
        'lib/features/live/native_gift_tray.part.dart',
        'lib/features/live/native_gift_balance.part.dart',
      ]);

  group('Owner Studio repair contract', () {
    test('owner surfaces use one Owner Studio information architecture', () {
      final ownerSource = owner();
      final creatorSource = creator();
      final profileSource = profile();

      expect(ownerSource, contains("title: const Text('Owner Studio')"));
      expect(ownerSource, contains("title: 'My Creator Account'"));
      expect(creatorSource, contains("'My Creator Account' : 'Creator Studio'"));
      expect(profileSource, contains("isOwner ? 'Owner Studio' : 'Creator Studio'"));
      expect(ownerSource, contains("const _Section('CREATOR VERIFICATION')"));
      expect(ownerSource, contains("const _Section('CREATOR PAYOUTS')"));
      expect(ownerSource, contains("const _Section('PLATFORM FINANCES')"));
    });

    test('ambiguous PayPal payouts expose a real recovery action', () {
      final ownerSource = owner();
      final migration = File(
        '../../supabase/migrations/20261005214500_owner_payout_recovery_queue_v2.sql',
      ).readAsStringSync();

      expect(ownerSource, contains('get_creator_payout_moderation_queue_v3'));
      expect(ownerSource, contains("payout['provider_status']"));
      expect(ownerSource, contains("payout['provider_batch_id']"));
      expect(ownerSource, contains("providerStatus == 'SUBMISSION_UNKNOWN'"));
      expect(ownerSource, contains("providerStatus == 'SUBMITTING'"));
      expect(ownerSource, contains("Key('owner-payout-recover-provider')"));
      expect(ownerSource, contains('Recover PayPal submission'));
      expect(ownerSource, contains('creator funds remain reserved'));
      expect(migration, contains('provider_status text'));
      expect(migration, contains('provider_batch_id text'));
      expect(
        migration,
        contains("'pending_review', 'approved', 'processing', 'held'"),
      );
    });

    test('payout processing and verification review state stay visible', () {
      final creatorSource = creator();
      final backend = files([
        'lib/data/fameverse_creator_backend.dart',
        'lib/data/fameverse_creator_payout_models.part.dart',
      ]);
      final ownerSource = owner();
      final migration = File(
        '../../supabase/migrations/20261006023500_build32_payout_verification_observability.sql',
      ).readAsStringSync();

      expect(backend, contains('providerStatusUpdatedAt'));
      expect(backend, contains("row['provider_status']"));
      expect(backend, contains("row['public_note']"));
      expect(creatorSource, contains("Key('creator-payout-provider-status')"));
      expect(creatorSource, contains('Funds remain reserved'));
      expect(creatorSource, contains("Key('creator-verification-status')"));
      expect(
        creatorSource,
        contains('Verification is processing in Fameverse review'),
      );
      expect(ownerSource, contains('Some owner data could not refresh'));
      expect(ownerSource, contains('verificationResult'));
      expect(migration, contains('provider_status_updated_at timestamptz'));
      expect(migration, contains('public_note text'));
    });

    test('QA and live payout recipients stay visibly separate', () {
      final creatorSource = creator();
      final backend = files([
        'lib/data/fameverse_creator_backend.dart',
        'lib/data/fameverse_creator_payout_models.part.dart',
      ]);
      final separation = File(
        '../../supabase/migrations/20261006210500_separate_live_payout_recipient_field.sql',
      ).readAsStringSync();

      expect(creatorSource, contains('QA Sandbox payout recipient'));
      expect(creatorSource, contains('Live PayPal payout method'));
      expect(creatorSource, contains('QA payout test balance'));
      expect(creatorSource, contains('sandbox-only'));
      expect(backend, contains('liveRecipientEmail'));
      expect(backend, contains('sandboxRecipientEmail'));
      expect(separation, contains('live_recipient_email'));
      expect(separation, contains('active live payout method required'));
    });

    test('buyer and creator-facing currency copy is Fame Coins', () {
      final creatorSource = creator();
      final ownerSource = owner();
      final store = files([
        'lib/features/profile/fame_coin_store_screen.dart',
        'lib/features/profile/fame_coin_store_view.part.dart',
      ]);
      final tray = giftTray();

      expect(creatorSource, contains('Fame Coins'));
      expect(ownerSource, contains('Fame Coins'));
      expect(store, contains('Fame Coins'));
      expect(tray, contains('Real Coins'));
      expect(tray, contains('Test Coins'));
    });
  });
}

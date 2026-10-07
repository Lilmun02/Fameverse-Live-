import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Build 32 release contract', () {
    test(
      'Fameboard uses authoritative windowed rankings and original terminology',
      () {
        final rankings = File(
          'lib/features/live/native_live_rankings.dart',
        ).readAsStringSync();

        for (final marker in <String>[
          "'get_fameverse_rankings_v2'",
          "'p_window': _window",
          "('24h', '24H')",
          "('7d', '7D')",
          "('supporters', 'Supporters'",
          "('pulse', 'Pulse'",
          "('creators', 'Creators'",
          "Key('fameboard-first-spotlight')",
        ]) {
          expect(rankings, contains(marker));
        }
        for (final rejected in <String>[
          'Daily Ranking',
          'Weekly Ranking',
          'Ranking history',
        ]) {
          expect(rankings, isNot(contains(rejected)));
        }
      },
    );

    test('Discover opens the same Fameboard used in Live', () {
      final discover = File(
        'lib/features/shell/fameverse_discover_screen.dart',
      ).readAsStringSync();
      final host = File(
        'lib/features/live/stream_host_live_screen.dart',
      ).readAsStringSync();
      final viewer = File(
        'lib/features/live/stream_viewer_live_screen.dart',
      ).readAsStringSync();

      expect(discover, contains("Key('discover-fameboard-card')"));
      expect(discover, contains('showNativeLiveRankings(context)'));
      expect(host, contains("Key('host-live-rankings-left')"));
      expect(host, contains('showNativeLiveRankings(context)'));
      expect(viewer, contains("Key('viewer-live-rankings-button')"));
      expect(viewer, contains('showNativeLiveRankings(context)'));
    });

    test(
      'web payout provider wiring cannot regress to database-only processing',
      () {
        final owner = File(
          '../../src/components/owner/OwnerControlCenter.jsx',
        ).readAsStringSync();
        final service = File(
          '../../src/services/ownerControl.js',
        ).readAsStringSync();

        expect(service, contains("'process-creator-payout'"));
        expect(service, contains("'sync-creator-payout'"));
        expect(service, contains('expected_environment: expectedEnvironment'));
        expect(service, contains('get_creator_payout_moderation_queue_v2'));
        expect(owner, contains('Release to PayPal'));
        expect(owner, contains('Recover PayPal submission'));
        expect(owner, contains('Sync PayPal'));
        expect(owner, isNot(contains('Mark paid')));
      },
    );

    test('web owner verification review controls remain wired', () {
      final owner = File(
        '../../src/components/owner/OwnerControlCenter.jsx',
      ).readAsStringSync();
      final service = File(
        '../../src/services/ownerControl.js',
      ).readAsStringSync();

      expect(service, contains('get_creator_verification_moderation_queue'));
      expect(service, contains('review_creator_verification'));
      expect(owner, contains('Verification Queue'));
      expect(owner, contains("verificationAction(request, 'verified')"));
      expect(owner, contains("verificationAction(request, 'needs_info')"));
      expect(owner, contains("verificationAction(request, 'rejected')"));
    });

    test('camera spam and Fame Stones touch fixes remain locked', () {
      final host = File(
        'lib/features/live/stream_host_live_screen.dart',
      ).readAsStringSync();
      final viewer = File(
        'lib/features/live/stream_viewer_live_screen.dart',
      ).readAsStringSync();
      final profile = File(
        'lib/features/profile/native_profile_build23.dart',
      ).readAsStringSync();

      expect(host, contains('bool _flipCameraBusy = false;'));
      expect(viewer, contains('bool _cohostFlipBusy = false;'));
      expect(profile, contains("Key('profile-fame-coins-card')"));
      expect(profile, contains('onTap: _loading ? null : _openStore'));
    });

    test('gift playback and Stripe hosted checkout repairs remain locked', () {
      final live = File(
        'lib/features/live/native_live_components.dart',
      ).readAsStringSync();
      final stripe = File(
        '../../supabase/functions/stripe-checkout-session/index.ts',
      ).readAsStringSync();

      expect(live, contains('onFinished'));
      expect(stripe, contains('managed_payments[enabled]'));
      expect(stripe, contains('"false"'));
    });

    test('Pocket Comet stays retired without overriding other gift assets', () {
      final backend = File(
        'lib/data/fameverse_live_backend.dart',
      ).readAsStringSync();
      final live = File(
        'lib/features/live/native_live_components.dart',
      ).readAsStringSync();
      final poster = File(
        'lib/features/live/native_gift_visual.dart',
      ).readAsStringSync();
      final migration = File(
        '../../supabase/migrations/20261004204000_retire_pocket_comet_gift.sql',
      ).readAsStringSync();

      expect(backend, isNot(contains("id: 'pocket-comet'")));
      expect(live, isNot(contains('NativePocketCometGift')));
      expect(live, isNot(contains('pocket-comet')));
      expect(poster, isNot(contains('PocketComet')));
      expect(poster, isNot(contains('pocket-comet')));
      expect(migration, contains("where id = 'pocket-comet'"));
      expect(migration, contains('active = false'));
    });
  });
}

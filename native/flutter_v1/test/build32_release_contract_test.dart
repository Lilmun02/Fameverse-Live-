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
      expect(host, contains("Key('host-live-rankings-button')"));
      expect(host, contains('showNativeLiveRankings(context)'));
      expect(viewer, contains("Key('viewer-live-rankings-button')"));
      expect(viewer, contains('showNativeLiveRankings(context)'));
    });

    test(
      'real payout provider wiring cannot regress to database-only processing',
      () {
        final owner = File(
          'lib/features/profile/owner_control_center_build23.dart',
        ).readAsStringSync();

        expect(owner, contains("'process-creator-payout'"));
        expect(owner, contains("'sync-creator-payout'"));
        expect(owner, contains("'expected_environment': 'sandbox'"));
        expect(owner, contains("Text('Send with PayPal sandbox')"));
        expect(owner, contains("Key('owner-payout-sync-provider')"));
        expect(owner, isNot(contains("Key('owner-payout-mark-paid')")));
      },
    );

    test('owner verification review controls remain wired', () {
      final owner = File(
        'lib/features/profile/owner_control_center_build23.dart',
      ).readAsStringSync();

      expect(owner, contains("'get_creator_verification_moderation_queue'"));
      expect(owner, contains("'review_creator_verification'"));
      expect(owner, contains("Key('owner-verification-approve')"));
      expect(owner, contains("Key('owner-verification-needs-info')"));
      expect(owner, contains("Key('owner-verification-reject')"));
    });

    test('camera spam and Fame Coins touch fixes remain locked', () {
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
  });
}

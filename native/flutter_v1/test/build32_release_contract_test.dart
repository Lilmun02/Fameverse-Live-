import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

String _files(List<String> paths) =>
    paths.map((path) => File(path).readAsStringSync()).join('\n');

void main() {
  group('Build 32 release contract', () {
    test('Fameboard uses authoritative windowed rankings and original terminology', () {
      final rankings = _files([
        'lib/features/live/native_live_rankings.dart',
        'lib/features/live/native_live_rankings_board.part.dart',
        'lib/features/live/native_live_rankings_rows.part.dart',
      ]);

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
    });

    test('Discover opens the same Fameboard used in Live', () {
      final discover = _files([
        'lib/features/shell/fameverse_discover_screen.dart',
        'lib/features/shell/fameverse_discover_featured.part.dart',
        'lib/features/shell/fameverse_discover_results.part.dart',
      ]);
      final host = _files([
        'lib/features/live/stream_host_live_screen.dart',
        'lib/features/live/stream_host_view.part.dart',
      ]);
      final viewer = _files([
        'lib/features/live/stream_viewer_live_screen.dart',
        'lib/features/live/stream_viewer_view.part.dart',
      ]);

      expect(discover, contains("Key('discover-fameboard-card')"));
      expect(discover, contains('showNativeLiveRankings(context)'));
      expect(host, contains("Key('host-live-rankings-left')"));
      expect(host, contains('showNativeLiveRankings(context)'));
      expect(viewer, contains("Key('viewer-live-rankings-button')"));
      expect(viewer, contains('showNativeLiveRankings(context)'));
    });

    test('real payout provider wiring cannot regress to database-only processing', () {
      final owner = _files([
        'lib/features/profile/owner_control_center_build23.dart',
        'lib/features/profile/owner_control_center_review_cards.part.dart',
      ]);

      expect(owner, contains("'process-creator-payout'"));
      expect(owner, contains("'sync-creator-payout'"));
      expect(owner, contains("'expected_environment': environment"));
      expect(owner, contains('QA · SANDBOX'));
      expect(owner, contains('REAL · LIVE'));
      expect(owner, contains("Key('owner-payout-sync-provider')"));
      expect(owner, isNot(contains("Key('owner-payout-mark-paid')")));
    });

    test('owner verification review controls remain wired', () {
      final owner = _files([
        'lib/features/profile/owner_control_center_build23.dart',
        'lib/features/profile/owner_control_center_review_cards.part.dart',
      ]);

      expect(owner, contains("'get_creator_verification_moderation_queue'"));
      expect(owner, contains("'review_creator_verification'"));
      expect(owner, contains("Key('owner-verification-approve')"));
      expect(owner, contains("Key('owner-verification-needs-info')"));
      expect(owner, contains("Key('owner-verification-reject')"));
    });

    test('camera spam and Fame Coins touch fixes remain locked', () {
      final host = _files([
        'lib/features/live/stream_host_live_screen.dart',
        'lib/features/live/stream_host_session.part.dart',
        'lib/features/live/stream_host_view.part.dart',
      ]);
      final viewer = _files([
        'lib/features/live/stream_viewer_live_screen.dart',
        'lib/features/live/stream_viewer_interactions.part.dart',
      ]);
      final profile = _files([
        'lib/features/profile/native_profile_build23.dart',
        'lib/features/profile/native_profile_build23_identity.part.dart',
      ]);

      expect(host, contains('bool _flipCameraBusy = false;'));
      expect(viewer, contains('bool _cohostFlipBusy = false;'));
      expect(profile, contains("Key('profile-fame-coins-card')"));
      expect(profile, contains('onTap: _loading ? null : _openStore'));
    });

    test('gift playback and Stripe hosted checkout repairs remain locked', () {
      final live = _files([
        'lib/features/live/native_live_components.dart',
        'lib/features/live/native_gift_overlay.part.dart',
      ]);
      final stripe = File(
        '../../supabase/functions/stripe-checkout-session/index.ts',
      ).readAsStringSync();

      expect(live, contains('onFinished'));
      expect(stripe, contains('managed_payments[enabled]'));
      expect(stripe, contains('"false"'));
      expect(stripe, contains('environment,'));
    });

    test('Pocket Comet stays retired without overriding other gift assets', () {
      final backend = _files([
        'lib/data/fameverse_gift_catalog.dart',
        'lib/data/fameverse_gift_catalog_core.dart',
        'lib/data/fameverse_gift_catalog_premium.dart',
      ]);
      final live = _files([
        'lib/features/live/native_live_components.dart',
        'lib/features/live/native_gift_overlay.part.dart',
        'lib/features/live/native_gift_tray.part.dart',
      ]);
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

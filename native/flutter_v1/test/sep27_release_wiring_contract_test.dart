import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

String read(String path) => File(path).readAsStringSync();

void main() {
  test('release startup delegates controls into the product/profile shell', () {
    final app = read('lib/app/fameverse_app.dart');
    final release = read('lib/features/shell/fameverse_release_shell.dart');
    final shell = read('lib/features/shell/fameverse_shell_build16.dart');

    expect(app, contains('FameverseReleaseShell('));
    expect(release, contains('FameverseBuild16Shell('));
    expect(release, isNot(contains('_ReleaseAction')));

    expect(shell, contains("Key('profile-release-rail')"));
    expect(shell, contains("Key('profile-first-verse-entry')"));
    expect(shell, contains("Key('profile-first-verse-progress')"));
    expect(shell, contains("Key('profile-coin-exchange-entry')"));
    expect(shell, contains("Key('profile-owner-control-entry')"));
    expect(shell, contains("Key('home-stories-header')"));
    expect(shell, contains("Key('profile-stories-header')"));
    expect(shell, contains('FirstVerseBetaScreen('));
    expect(shell, contains('economyBackend: _getEconomyBackend()'));
    expect(shell, contains('CoinExchangeScreen('));
    expect(shell, contains('OwnerControlPanel()'));
  });

  test(
    'owner/admin bypass tester locks while creator backend preserves literal roles',
    () {
      final shell = read('lib/features/shell/fameverse_shell_build16.dart');
      final creatorBackend = read('lib/data/fameverse_creator_backend.dart');

      expect(
        shell,
        contains("_accountRole == 'owner' || _accountRole == 'admin'"),
      );
      expect(
        shell,
        contains(
          '_betaStatus.enrolled && !_betaStatus.badgeUnlocked && !_isPrivileged',
        ),
      );
      expect(shell, contains('Complete First Verse to unlock Go Live.'));
      expect(shell, contains('Earn First Verse to unlock Creator Studio.'));
      expect(creatorBackend, contains('Preserve the authoritative role'));
      expect(
        creatorBackend,
        isNot(contains("role == 'admin' ? 'owner' : role")),
      );
    },
  );

  test(
    'First Verse exposes real progress, required missions and referral rules',
    () {
      final screen = read('lib/features/profile/first_verse_beta_screen.dart');
      final backend = read('lib/data/fameverse_beta_backend.dart');

      expect(screen, contains("Key('first-verse-progress-bar')"));
      expect(screen, contains('REQUIRED BETA MISSIONS'));
      expect(screen, contains('BONUS CHECKS'));
      expect(screen, contains('INVITE TO FAMEVERSE'));
      expect(screen, contains('100 promo Fame Coins'));
      expect(screen, contains('50 promo Fame Coins'));
      expect(screen, contains('Promo Fame Coins are gifting-only'));
      expect(screen, contains('do not create creator cash earnings'));
      expect(screen, contains('does not count toward badge progress'));

      for (final mission in <String>[
        'complete_profile',
        'browse_home',
        'browse_discover',
        'open_public_profile',
        'follow_creator',
        'join_live',
        'send_comment',
        'view_story',
      ]) {
        expect(backend, contains("'$mission'"));
      }
      expect(backend, contains("'send_gift'"));
      expect(backend, contains("'cohost_session'"));
      expect(backend, isNot(contains("key: 'payout")));
    },
  );

  test('Live wires comment, gift and cohost First Verse mission telemetry', () {
    final viewer = read('lib/features/live/stream_viewer_live_screen.dart');

    expect(viewer, contains("_recordBetaMission('send_comment')"));
    expect(viewer, contains("_recordBetaMission('send_gift')"));
    expect(viewer, contains("_recordBetaMission('cohost_session')"));
    expect(viewer, contains("'record_beta_test_mission'"));
  });

  test('gift UI stays exclusive to owner/admin beta roles', () {
    final viewer = read('lib/features/live/stream_viewer_live_screen.dart');

    expect(
      viewer,
      contains(
        "bool get _canRefill => _accountRole == 'owner' || _accountRole == 'admin';",
      ),
    );
    expect(
      viewer,
      contains('bool get _giftEnabled => widget.giftAccess && _canRefill;'),
    );
    expect(viewer, contains('if (_giftEnabled) ...['));
    expect(viewer, contains("Key('viewer-gift-button')"));
    expect(viewer, contains('if (!_giftEnabled) return false;'));
    expect(viewer, contains('You cannot gift your own live.'));
  });

  test('promo/test/referral gifts cannot create creator cash earnings', () {
    final migration = read(
      '../../supabase/migrations/20260927_enforce_zero_promo_creator_earnings.sql',
    );

    expect(
      migration,
      contains('promo/test/referral coins create zero creator earnings'),
    );
    expect(migration, contains("'promo_first_zero_promo_earnings'"));
    expect(migration, contains('v_cash_spent > 0'));
    expect(migration, contains('0::bigint'));
    expect(migration, isNot(contains("'owner_promo_bonus'")));
    expect(migration, isNot(contains('cash_reward_reserve')));
  });

  test('Fame Algo is routed through the RPCs the native app already calls', () {
    final backend = read('lib/data/fameverse_backend.dart');
    final activation = read(
      '../../supabase/migrations/20260927_activate_fame_algo_v1.sql',
    );

    expect(backend, contains("'get_recommended_creators_v2'"));
    expect(backend, contains("'get_active_live_rooms_v2'"));
    expect(activation, contains('get_recommended_creators_v3'));
    expect(activation, contains('get_active_live_rooms_v3'));
    expect(
      activation,
      contains('Compatibility alias. Fame Algo v1 is authoritative'),
    );
  });
}

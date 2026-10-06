import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

String _source(String path) => File(path).readAsStringSync();
String _files(List<String> paths) => paths.map(_source).join('\n');

void main() {
  group('Build 23 regression contracts', () {
    test('startup routes Build 23 and restores backend updater', () {
      final app = _files([
        'lib/app/fameverse_app.dart',
        'lib/app/fameverse_app_widgets.part.dart',
      ]);
      expect(app, contains('fameverse_shell_build23.dart'));
      expect(app, contains('FameverseBuild23Shell'));
      expect(app, isNot(contains('FameverseBuild16Shell')));
      expect(app, contains('startup_update_service.dart'));
      expect(app, contains('FvStartupUpdateService'));
      expect(app, contains('fameverse-startup-update-notice'));
    });

    test('Home keeps Stories above Live and exposes two top feed tabs', () {
      final home = _files([
        'lib/features/shell/fameverse_home_build23.dart',
        'lib/features/shell/fameverse_home_build23_feed.part.dart',
        'lib/features/shell/fameverse_home_build23_cards.part.dart',
      ]);
      expect(home, contains("Key('home-feed-switch')"));
      expect(home, contains("keyName: 'home-live-feed-tab'"));
      expect(home, contains("keyName: 'home-story-feed-tab'"));
      expect(home, contains('_StoryRail('));
      expect(home.indexOf('_StoryRail('), lessThan(home.indexOf("'LIVE NOW'")));
    });

    test('First Verse lives in Settings with real progress', () {
      final profile = _files([
        'lib/features/profile/native_profile_build23.dart',
        'lib/features/profile/native_profile_build23_settings.part.dart',
      ]);
      final shell = _source('lib/features/shell/fameverse_shell_build23.dart');
      expect(profile, contains("Key('settings-first-verse-entry')"));
      expect(profile, contains("Key('settings-first-verse-progress')"));
      expect(profile, contains('status.progress'));
      expect(shell, isNot(contains("Key('first-verse-tester-entry')")));
      expect(shell, isNot(contains('_HomeStoryLauncher')));
    });

    test('owner premium surface is not blurred or fake locked', () {
      final profile = _files([
        'lib/features/profile/native_profile_build23.dart',
        'lib/features/profile/native_profile_build23_identity.part.dart',
      ]);
      final studio = _files([
        'lib/features/profile/creator_studio_build23.dart',
        'lib/features/profile/creator_studio_build23_summary.part.dart',
      ]);
      expect(profile, contains('FAMEVERSE OWNER • PREMIUM'));
      expect(profile, contains('Owner Premium'));
      expect(studio, contains('Premium owner access'));
      expect(studio, isNot(contains('ImageFiltered')));
      expect(studio, isNot(contains('ImageFilter.blur')));
      expect(studio, isNot(contains('90% hidden')));
    });

    test('promo QA value stays visibly separate from real cash earnings', () {
      final studio = _files([
        'lib/features/profile/creator_studio_build23.dart',
        'lib/features/profile/creator_studio_build23_summary.part.dart',
        'lib/features/profile/creator_studio_build23_payout.part.dart',
      ]);
      expect(studio, contains('REAL CREATOR EARNINGS'));
      expect(studio, contains('PROMOTIONAL / QA'));
      expect(studio, contains('get_creator_promotional_earnings_summary'));
      expect(studio, contains('no real cash value'));
    });

    test('customer coin purchases never live inside Creator Studio', () {
      final profile = _files([
        'lib/features/profile/native_profile_build23.dart',
        'lib/features/profile/native_profile_build23_identity.part.dart',
      ]);
      final studio = _source('lib/features/profile/creator_studio_build23.dart');
      expect(profile, contains("Key('profile-buy-fame-coins')"));
      expect(profile, contains('FameCoinStoreScreen('));
      expect(studio, isNot(contains('NativeRechargeScreen')));
      expect(studio, isNot(contains('native_recharge_screen.dart')));
      expect(studio, isNot(contains("Key('build23-owner-recharge')")));
      expect(studio, isNot(contains('Owner QA coin purchase flow')));
    });
  });
}

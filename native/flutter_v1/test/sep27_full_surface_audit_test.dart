import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

String read(String path) => File(path).readAsStringSync();

void main() {
  test(
    'Sep27 repair candidate keeps every implemented product surface wired',
    () {
      final shell = read('lib/features/shell/fameverse_shell_build16.dart');
      final home = read('lib/features/shell/fameverse_home_screen.dart');
      final firstVerse = read(
        'lib/features/profile/first_verse_beta_screen.dart',
      );
      final storyRoute = read(
        'lib/features/stories/creator_stories_screen.dart',
      );
      final stories = read(
        'lib/features/stories/creator_stories_screen_v2.dart',
      );
      final creatorStudio = read(
        'lib/features/profile/creator_studio_screen.dart',
      );
      final owner = read('lib/features/profile/owner_control_panel.dart');
      final coinExchange = read(
        'lib/features/profile/coin_exchange_screen.dart',
      );
      final settings = read(
        'lib/features/profile/fameverse_policy_screen.dart',
      );
      final viewer = read('lib/features/live/stream_viewer_live_screen.dart');
      final updater = read('lib/data/startup_update_service.dart');

      expect(shell, contains('FirstVerseBetaScreen('));
      expect(shell, contains('CoinExchangeScreen('));
      expect(shell, contains('OwnerControlPanel()'));
      expect(shell, contains('CreatorStoriesScreen('));
      expect(shell, contains('CreatorStudioScreen('));

      expect(home, contains('FAME ALGO'));
      expect(home, contains("Key('fame-algo-identity')"));

      expect(firstVerse, contains("Key('first-verse-progress-bar')"));
      expect(firstVerse, contains('INVITE TO FAMEVERSE'));
      expect(firstVerse, contains('OWNER / ADMIN PREVIEW · NO FEATURE LOCKS'));

      expect(storyRoute, contains('CreatorStoriesScreenV2('));
      expect(stories, contains("Key('stories-v2-screen')"));
      expect(stories, contains('ImagePicker'));
      expect(stories, contains("Key('post-story-button')"));
      expect(stories, contains("Key('single-story-create-area')"));

      expect(creatorStudio, contains('loadCreatorLiveHistory'));
      expect(creatorStudio, contains('setCreatorModerator'));
      expect(owner, contains('Payout review'));
      expect(coinExchange, contains('Coin Exchange'));

      expect(settings, contains('Privacy, safety & legal'));
      expect(
        settings,
        contains('70% of eligible cash-backed gross gift value'),
      );

      expect(viewer, contains("Key('viewer-gift-button')"));
      expect(
        viewer,
        contains("_accountRole == 'owner' || _accountRole == 'admin'"),
      );

      expect(updater, contains(".from('app_release_state')"));
      expect(updater, contains('backend_revision'));
    },
  );
}

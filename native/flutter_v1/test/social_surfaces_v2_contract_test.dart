import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Fameverse social surfaces V2 contract', () {
    test('Home stays streaming-first and algorithmic', () async {
      final home = await File(
        'lib/features/shell/fameverse_home_screen.dart',
      ).readAsString();

      expect(home, contains("Key('fameverse-algorithmic-home')"));
      expect(home, contains("'LIVE NOW'"));
      expect(home, contains("'For You'"));
      expect(home, contains("'Following'"));
      expect(home, contains("'Rising'"));
      expect(home, contains('widget.network.followingIds.contains'));
      expect(home, contains('room.fameTaps'));
      expect(home, contains('Rising on Fameverse'));
      expect(home, isNot(contains('Your circle')));
      expect(home, isNot(contains('Search creators')));
    });

    test('Discover remains intentional search and exploration', () async {
      final discover = await File(
        'lib/features/shell/fameverse_discover_screen.dart',
      ).readAsString();

      expect(discover, contains("Key('fameverse-intentional-discover')"));
      expect(discover, contains("Key('discover-search')"));
      expect(discover, contains("label: 'All'"));
      expect(discover, contains("label: 'Live'"));
      expect(discover, contains("label: 'Creators'"));
      expect(discover, contains("label: 'Rising'"));
      expect(discover, contains("label: 'Following'"));
      expect(discover, contains('Creators to discover'));
      expect(discover, contains('Streams to explore'));
    });

    test('Profile is public identity and not an admin dashboard', () async {
      final profile = await File(
        'lib/features/profile/native_profile_screen.dart',
      ).readAsString();

      expect(profile, contains("Key('native-profile-screen')"));
      expect(profile, contains("Key('profile-display-name')"));
      expect(profile, contains("Key('profile-handle')"));
      expect(profile, contains("Key('profile-bio')"));
      expect(profile, contains("Key('profile-social-stats')"));
      expect(profile, contains("Key('edit-profile-button')"));
      expect(profile, contains("Key('open-creator-studio')"));
      expect(profile, isNot(contains('OWNER QA')));
      expect(profile, isNot(contains('Recharge Fame Coins')));
      expect(profile, isNot(contains('Signed in as')));
      expect(profile, isNot(contains('Admin - Owner')));
    });

    test('Edit Profile and Settings are full-screen consumer routes', () async {
      final edit = await File(
        'lib/features/profile/fameverse_edit_profile_screen.dart',
      ).readAsString();
      final profile = await File(
        'lib/features/profile/native_profile_screen.dart',
      ).readAsString();
      final policy = await File(
        'lib/features/profile/fameverse_policy_screen.dart',
      ).readAsString();
      final shell = await File(
        'lib/features/shell/fameverse_shell_build16.dart',
      ).readAsString();

      expect(edit, contains("Key('fameverse-fullscreen-edit-profile')"));
      expect(edit, contains("Key('edit-profile-change-photo')"));
      expect(edit, contains("Key('save-profile-button')"));
      expect(shell, contains('MaterialPageRoute('));
      expect(shell, contains('FameverseEditProfileScreen('));
      expect(profile, contains("Key('fameverse-profile-settings-screen')"));
      expect(profile, contains("'PROFILE'"));
      expect(profile, contains("'CREATOR'"));
      expect(profile, contains("'SAFETY & ACCOUNT'"));
      expect(policy, contains("Key('fameverse-policy-safety-screen')"));
      expect(policy, contains("'Community Standards'"));
      expect(policy, contains("'Creator Beta Terms'"));
    });

    test('Build 18 shell wires the new surfaces instead of legacy directory UI', () async {
      final shell = await File(
        'lib/features/shell/fameverse_shell_build16.dart',
      ).readAsString();

      expect(shell, contains('FameverseHomeScreen('));
      expect(shell, contains('FameverseDiscoverScreen('));
      expect(shell, contains('NativeProfileScreen('));
      expect(shell, contains("key: const Key('fameverse-bottom-nav')"));
      expect(shell, isNot(contains('class _Build16HomeScreen')));
      expect(shell, isNot(contains('class _Build16DiscoverScreen')));
      expect(shell, isNot(contains('showModalBottomSheet<void>(')));
    });
  });
}

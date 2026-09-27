import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

String read(String path) => File(path).readAsStringSync();

void main() {
  test('Creator Studio wires analytics, gift activity and moderator tools', () {
    final studio = read('lib/features/profile/creator_studio_screen.dart');

    expect(studio, contains('loadCreatorLiveHistory'));
    expect(studio, contains('loadCreatorGiftActivity'));
    expect(studio, contains(".from('creator_moderators')"));
    expect(studio, contains('setCreatorModerator'));
    expect(studio, contains("Key('creator-live-analytics')"));
    expect(studio, contains("Key('creator-moderators-card')"));
    expect(studio, contains("Key('add-creator-moderator')"));
    expect(studio, contains('Creator moderator limit is 3 during beta.'));
    expect(studio, contains('server-authoritative Live metrics'));
  });

  test('Settings exposes real account security and current economy rules', () {
    final settings = read('lib/features/profile/fameverse_policy_screen.dart');

    expect(settings, contains('Privacy, safety & legal'));
    expect(settings, contains("Key('settings-change-password')"));
    expect(settings, contains('auth.updateUser'));
    expect(settings, contains("Key('settings-signout-others')"));
    expect(settings, contains('SignOutScope.others'));
    expect(settings, contains('70% of eligible cash-backed gross gift value'));
    expect(settings, contains('30% to Fameverse'));
    expect(settings, contains('Promotional, referral, and test Fame Coins'));
    expect(settings, contains('do not create creator cash earnings'));
    expect(settings, contains('100 promotional Fame Coins'));
    expect(settings, contains('50 promotional Fame Coins'));
  });
}

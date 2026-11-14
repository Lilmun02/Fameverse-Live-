import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Main profile keeps wallet and Studio inside Settings only', () {
    final source = File(
      'lib/features/profile/native_profile_build23.dart',
    ).readAsStringSync();
    final profileEnd = source.indexOf('class _PremiumHero');
    final profileSurface = source.substring(0, profileEnd);

    expect(profileSurface, isNot(contains('_WalletCard(userId:')));
    expect(profileSurface, isNot(contains('open-creator-studio')));
    expect(profileSurface, isNot(contains('onPressed: onCreatorStudio')));
    expect(profileSurface, contains("Key('profile-settings-button')"));
    expect(profileSurface, contains("Key('edit-profile-button')"));
  });

  test('Settings routes working actions and searches their labels', () {
    final source = File(
      'lib/features/profile/native_profile_build23.dart',
    ).readAsStringSync();
    expect(source, contains("Key('settings-search-field')"));
    expect(source, contains("_section('ACCOUNT', ["));
    expect(source, contains("_section('CREATOR & WALLET', ["));
    expect(source, contains("_WalletCard(userId: profile.id)"));
    expect(source, contains("onTap: widget.onCreatorStudio"));
    expect(source, contains("onTap: widget.onEdit"));
    expect(source, contains("onTap: widget.onPolicies"));
    expect(source, contains("_FirstVerseSettingsCard("));
    expect(source, contains("Coming soon ·"));
  });

  test('Profile photo is edited inside Edit Profile', () {
    final profile = File(
      'lib/features/profile/native_profile_build23.dart',
    ).readAsStringSync();
    final editor = File(
      'lib/features/profile/fameverse_edit_profile_screen.dart',
    ).readAsStringSync();
    expect(
      profile.substring(
        profile.indexOf('class _PremiumHero'),
        profile.indexOf('class _Avatar'),
      ),
      isNot(contains('onTap: avatarBusy ? null : onChangePhoto')),
    );
    expect(editor, contains("Key('edit-profile-change-photo')"));
  });
}

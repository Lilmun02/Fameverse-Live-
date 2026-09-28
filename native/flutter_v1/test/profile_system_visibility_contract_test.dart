import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

String read(String path) => File(path).readAsStringSync();

void main() {
  test('Settings exposes Fame Algo and backend updater directly', () {
    final profile = read('lib/features/profile/native_profile_screen.dart');

    expect(profile, contains("_SettingsSectionTitle('FAMEVERSE SYSTEM')"));
    expect(profile, contains("label: 'Fame Algo'"));
    expect(profile, contains("label: 'App & backend updates'"));
    expect(profile, contains("_openSystem(context, 'algo')"));
    expect(profile, contains("_openSystem(context, 'updates')"));
    expect(profile, contains("label: 'Privacy, safety & legal'"));
  });

  test('public profile does not grant every account a fake verified badge', () {
    final profile = read('lib/features/profile/native_profile_screen.dart');
    final identityStart = profile.indexOf('class _ProfileIdentity');
    final statsStart = profile.indexOf('class _ConnectionStats');
    expect(identityStart, greaterThanOrEqualTo(0));
    expect(statsStart, greaterThan(identityStart));

    final identity = profile.substring(identityStart, statsStart);
    expect(identity, isNot(contains('Icons.verified_rounded')));
  });
}

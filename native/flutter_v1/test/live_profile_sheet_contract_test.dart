import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

String read(String path) => File(path).readAsStringSync();

void main() {
  test('Live profile sheet exposes social, FameTap and gifting identity', () {
    final sheet = read('lib/features/live/fameverse_live_profile_sheet.dart');
    final shared = read('lib/features/live/stream_live_shared.dart');
    final components = read('lib/features/live/native_live_components.dart');

    expect(sheet, contains("Key('live-profile-sheet')"));
    expect(sheet, contains("Key('live-profile-social-stats')"));
    expect(sheet, contains('Followers'));
    expect(sheet, contains('Following'));
    expect(sheet, contains('Friends'));
    expect(sheet, contains('FameTaps'));
    expect(sheet, contains('Gift coins sent'));
    expect(sheet, contains("Key('live-profile-gifter-level')"));
    expect(sheet, contains('Follow back'));
    expect(sheet, contains('Friends'));
    expect(sheet, contains("'get_live_profile_sheet_summary'"));

    expect(shared, contains('showFameverseLiveProfileSheet'));
    expect(components, contains("Key('live-profile-avatar')"));
    expect(components, contains('showFameverseLiveProfileSheet'));
  });

  test('Live profile backend never exposes private owner or payout fields', () {
    final migration = read(
      '../../supabase/migrations/20260927_live_profile_sheet_summary.sql',
    );

    expect(migration, contains('get_live_profile_sheet_summary'));
    expect(migration, contains('eligible_tap_count'));
    expect(migration, contains('total_coins_sent'));
    expect(migration, contains('gifter_level'));
    expect(migration, contains('viewer_follows'));
    expect(migration, contains('target_follows_viewer'));
    expect(migration, isNot(contains('account_roles')));
    expect(migration, isNot(contains('recipient_email')));
    expect(migration, isNot(contains('payout')));
  });
}

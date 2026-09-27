import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

String read(String path) => File(path).readAsStringSync();

void main() {
  test('native startup checks backend revision before product shell', () {
    final app = read('lib/app/fameverse_app.dart');
    final service = read('lib/data/startup_update_service.dart');

    expect(app, contains('Checking for updates…'));
    expect(app, contains('Updating Fameverse…'));
    expect(app, contains('You’re all set!'));
    expect(app, contains('FvStartupUpdateService'));
    expect(app, contains('FvBackendRuntime.manifest'));
    expect(app, contains("'app_enabled'"));

    expect(service, contains(".from('app_release_state')"));
    expect(service, contains('backend_revision'));
    expect(service, contains('release_label'));
    expect(service, contains('manifest'));
    expect(service, contains('SharedPreferences.getInstance'));
    expect(service, contains('backendChanged'));
  });

  test('server manifest documents supported Sep27 runtime contracts', () {
    final migration = read(
      '../../supabase/migrations/20260927_native_backend_updater_manifest.sql',
    );

    for (final feature in <String>[
      'stories',
      'first_verse',
      'coin_exchange',
      'creator_studio',
      'owner_control_panel',
      'fame_algo_v1',
      'backend_updater',
    ]) {
      expect(migration, contains("'$feature'"));
    }
    expect(migration, contains("'creator_share_bps', 7000"));
    expect(migration, contains("'platform_share_bps', 3000"));
    expect(migration, contains("'referrer_reward_coins', 100"));
    expect(migration, contains("'referred_reward_coins', 50"));
    expect(migration, contains("'promo_creator_earnings', false"));
  });
}

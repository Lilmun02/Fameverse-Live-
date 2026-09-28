import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

String read(String path) => File(path).readAsStringSync();

void main() {
  test('Settings exposes Fame Algo and backend updater status', () {
    final policy = read('lib/features/profile/fameverse_policy_screen.dart');
    final status = read(
      'lib/features/profile/fameverse_system_status_screen.dart',
    );

    expect(policy, contains("Key('settings-fame-algo-entry')"));
    expect(policy, contains("Key('settings-backend-updater-entry')"));
    expect(policy, contains('FameverseSystemStatusScreen'));

    expect(status, contains("Key('settings-fame-algo-title')"));
    expect(status, contains('FAME ALGO V1'));
    expect(status, contains("Key('settings-backend-updater-title')"));
    expect(status, contains("Key('backend-update-check-now')"));
    expect(status, contains('FvStartupUpdateService'));
    expect(status, contains('Backend revision'));
    expect(status, contains('Release label'));
  });

  test('Discover exposes rankings backed by the ranking RPC', () {
    final discover = read('lib/features/shell/fameverse_discover_screen.dart');
    final migration = read(
      '../../supabase/migrations/20260927_discover_rankings.sql',
    );

    expect(discover, contains("Key('discover-view-rankings')"));
    expect(discover, contains("Key('discover-rankings-surface')"));
    expect(discover, contains('Top Tappers'));
    expect(discover, contains('Top Gifters'));
    expect(discover, contains('Creators'));
    expect(discover, contains("'get_fameverse_rankings'"));
    expect(discover, contains('eligible FameTaps'));
    expect(
      discover,
      contains('All/Live/Following preserve the backend Fame Algo order'),
    );

    expect(migration, contains('get_fameverse_rankings'));
    expect(migration, contains("v_kind = 'tappers'"));
    expect(migration, contains("v_kind = 'gifters'"));
    expect(migration, contains("v_kind = 'creators'"));
    expect(migration, contains('eligible_tap_count'));
    expect(migration, contains('total_coins_sent'));
  });
}

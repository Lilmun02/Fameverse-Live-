import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Home and Live browsing use one-round-trip server RPCs', () {
    final backend = File('lib/data/fameverse_backend.dart').readAsStringSync();
    expect(backend, contains("'get_recommended_creators_v2'"));
    expect(backend, contains("'get_active_live_rooms_v2'"));
    expect(backend, isNot(contains("from('live_tap_totals')")));
    expect(backend, isNot(contains("from('profiles')\n        .select(_profileFields)\n        .order('created_at'")));
  });

  test('performance migration keeps hot RLS auth lookups in initplans', () {
    final sql = File(
      '../../supabase/migrations/20260927_performance_maintenance.sql',
    ).readAsStringSync();
    expect(sql, contains('(select auth.uid())'));
    expect(sql, contains('follows_following_follower_idx'));
    expect(sql, contains('beta_coin_ledger_gift_event_idx'));
    expect(sql, contains('get_recommended_creators_v2'));
    expect(sql, contains('get_active_live_rooms_v2'));
  });

  test('maintenance pass is additive and does not drop performance indexes', () {
    final sql = File(
      '../../supabase/migrations/20260927_performance_maintenance.sql',
    ).readAsStringSync();
    expect(sql.toLowerCase(), isNot(contains('drop index')));
    expect(sql, contains('create index if not exists'));
  });
}

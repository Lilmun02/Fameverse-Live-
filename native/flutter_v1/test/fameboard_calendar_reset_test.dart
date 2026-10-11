import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:fameverse_live/features/live/fameboard_period.dart';

void main() {
  group('Fameboard calendar resets', () {
    test('daily keeps points until midnight and then starts a new period', () {
      final before = DateTime.utc(2026, 10, 10, 23, 59, 59);
      final next = DateTime.utc(2026, 10, 11);
      expect(fameboardStartUtc('24h', before), DateTime.utc(2026, 10, 10));
      expect(fameboardEndUtc('24h', before), next);
      expect(fameboardStartUtc('24h', next), next);
      expect(fameboardEndUtc('24h', next), DateTime.utc(2026, 10, 12));
    });

    test('weekly keeps points until Monday and then starts fresh', () {
      final before = DateTime.utc(2026, 10, 11, 23, 59, 59);
      final next = DateTime.utc(2026, 10, 12);
      expect(fameboardStartUtc('7d', before), DateTime.utc(2026, 10, 5));
      expect(fameboardEndUtc('7d', before), next);
      expect(fameboardStartUtc('7d', next), next);
      expect(fameboardEndUtc('7d', next), DateTime.utc(2026, 10, 19));
    });

    test('local offsets do not move the UTC reset', () {
      final instant = DateTime.parse('2026-10-10T20:15:00-04:00');
      expect(fameboardStartUtc('24h', instant), DateTime.utc(2026, 10, 11));
    });

    test('countdown clamps to zero and shows hours, minutes and seconds', () {
      expect(fameboardCountdown(const Duration(seconds: 62)), '00:01:02');
      expect(
        fameboardCountdown(const Duration(days: 2, seconds: 5)),
        '2d 00:00:05',
      );
      expect(fameboardCountdown(const Duration(seconds: -1)), '00:00:00');
    });

    test('old leaderboard results cannot appear after reset or tab switch', () {
      final source = File(
        'lib/features/live/native_live_rankings.dart',
      ).readAsStringSync();
      expect(source, contains('requestedResetUtc != _resetAtUtc'));
      expect(source, contains('requestId != _loadRequestId'));
      expect(source, contains('_rows = const [];'));
      expect(source, contains('fameboard-reset-countdown'));
      expect(source, contains("'get_fameverse_rankings_v2'"));
    });

    test('all ranking categories use backend half-open period boundaries', () {
      final sql = File(
        '../../supabase/migrations/20261010223000_fameboard_calendar_reset.sql',
      ).readAsStringSync();
      expect(sql, contains("date_trunc('day', now() at time zone 'UTC')"));
      expect(sql, contains("date_trunc('week', now() at time zone 'UTC')"));
      expect('and g.created_at < v_until'.allMatches(sql).length, 1);
      expect('and b.created_at < v_until'.allMatches(sql).length, 2);
      expect('and f.created_at < v_until'.allMatches(sql).length, 1);
      expect(sql, isNot(contains("now() - interval '24 hours'")));
      expect(sql, isNot(contains("now() - interval '7 days'")));
      expect(sql, contains('f.cash_backed_coins > 0'));
      expect(sql, contains('authentication required'));
    });
  });
}

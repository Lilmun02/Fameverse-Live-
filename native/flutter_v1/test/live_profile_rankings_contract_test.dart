import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Native Live profile and Fameboard contract', () {
    test('earned gifter badge stays tied to real gifting progression', () {
      final profile = File(
        'lib/features/live/native_live_profile_sheet.dart',
      ).readAsStringSync();
      expect(profile, contains('totalCoinsSent <= 0'));
      expect(profile, contains("label: 'Spark Gifter'"));
      expect(profile, contains("label: 'Silver Gifter'"));
      expect(profile, contains("label: 'Fame Icon'"));
      expect(profile, contains('LinearProgressIndicator'));
      expect(profile, contains("return 'Follow Back'"));
      expect(profile, contains("return 'Friends'"));
      expect(profile, contains('loadViewerIdentityStats'));
    });

    test('Fameboard uses the authoritative windowed backend', () {
      final rankings = File(
        'lib/features/live/native_live_rankings.dart',
      ).readAsStringSync();
      expect(rankings, contains("'get_fameverse_rankings_v2'"));
      expect(rankings, contains("('supporters', 'Supporters'"));
      expect(rankings, contains("('pulse', 'Pulse'"));
      expect(rankings, contains("('creators', 'Creators'"));
      // Legacy RPC window params are unchanged for backward compatibility.
      // The approved new backend windows are calendar UTC boundaries.
      expect(rankings, contains("('24h', 'Daily')"));
      expect(rankings, contains("('7d', 'Weekly')"));
      expect(rankings, contains('Daily ranking · resets at 00:00 UTC'));
      expect(rankings, contains('Weekly ranking · resets Sunday at 00:00 UTC'));
      expect(rankings, isNot(contains('Momentum from the last 24 hours')));
      expect(rankings, isNot(contains('Momentum from the last 7 days')));
      expect(rankings, contains("Key('fameboard-window-24h')"));
      expect(rankings, contains("Key('fameboard-window-7d')"));
      expect(rankings, contains("'supporters' => '${_compact(entry.score)} coins sent'"));
      expect(rankings, contains("'pulse' => '${_compact(entry.score)} Fame taps'"));
      expect(rankings, contains("'creators' => '${_compact(entry.score)} live taps'"));
      expect(rankings, contains("'p_limit': 100"));
      expect(rankings, isNot(contains("'p_limit': 50")));
      expect(rankings, isNot(contains('fake')));
    });

    test('Discover has a top-bar Fameboard shortcut without a banner', () {
      final discover = File(
        'lib/features/shell/fameverse_discover_screen.dart',
      ).readAsStringSync();
      final rankingControl = discover.indexOf(
        "key: const Key('discover-fameboard-card')",
      );
      expect(
        rankingControl,
        greaterThan(discover.indexOf('class _DiscoverTopBar')),
      );
      expect(rankingControl, lessThan(discover.indexOf('class _FilterChip')));
      expect(discover, isNot(contains('class _DiscoverFameboardCard')));
      expect(discover, contains('showNativeLiveRankings(context)'));
    });

    test('host and viewer keep Live profile and Fameboard entry points', () {
      final host = File(
        'lib/features/live/stream_host_live_screen.dart',
      ).readAsStringSync();
      final viewer = File(
        'lib/features/live/stream_viewer_live_screen.dart',
      ).readAsStringSync();
      expect(host, contains('showNativeLiveProfileSheet'));
      expect(viewer, contains('showNativeLiveProfileSheet'));
      expect(host, contains("Key('host-live-rankings-left')"));
      expect(viewer, contains("Key('viewer-live-rankings-button')"));
      expect(host, contains('showNativeLiveRankings'));
      expect(viewer, contains('showNativeLiveRankings'));
    });
  });
}

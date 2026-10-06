import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

String _files(List<String> paths) =>
    paths.map((path) => File(path).readAsStringSync()).join('\n');

void main() {
  group('Native Live profile and Fameboard contract', () {
    test('earned gifter badge stays tied to shared gifting progression', () {
      final badge = _files([
        'lib/features/badges/gifter_badge_system.dart',
        'lib/features/badges/gifter_badge_widgets.dart',
        'lib/features/badges/gifter_profile_section.dart',
      ]);
      final profile = File(
        'lib/features/live/native_live_profile_sheet.dart',
      ).readAsStringSync();

      expect(badge, contains("name: 'Spark Gifter'"));
      expect(badge, contains("name: 'Silver Gifter'"));
      expect(badge, contains("name: 'Fame Icon'"));
      expect(badge, contains('LinearProgressIndicator'));
      expect(profile, contains("return 'Follow Back'"));
      expect(profile, contains("return 'Friends'"));
      expect(profile, contains('loadViewerIdentityStats'));
      expect(profile, contains('FvGifterBadge('));
    });

    test('Fameboard uses the authoritative windowed backend', () {
      final rankings = _files([
        'lib/features/live/native_live_rankings.dart',
        'lib/features/live/native_live_rankings_board.part.dart',
        'lib/features/live/native_live_rankings_rows.part.dart',
      ]);
      expect(rankings, contains("'get_fameverse_rankings_v2'"));
      expect(rankings, contains("('supporters', 'Supporters'"));
      expect(rankings, contains("('pulse', 'Pulse'"));
      expect(rankings, contains("('creators', 'Creators'"));
      expect(rankings, contains("('24h', '24H')"));
      expect(rankings, contains("('7d', '7D')"));
      expect(rankings, contains("'p_limit': 50"));
      expect(rankings, isNot(contains('fake')));
    });

    test('host and viewer keep Live profile and Fameboard entry points', () {
      final host = _files([
        'lib/features/live/stream_host_live_screen.dart',
        'lib/features/live/stream_host_sheets.part.dart',
        'lib/features/live/stream_host_view.part.dart',
      ]);
      final viewer = _files([
        'lib/features/live/stream_viewer_live_screen.dart',
        'lib/features/live/stream_viewer_sheets.part.dart',
        'lib/features/live/stream_viewer_view.part.dart',
      ]);
      expect(host, contains('showNativeLiveProfileSheet'));
      expect(viewer, contains('showNativeLiveProfileSheet'));
      expect(host, contains("Key('host-live-rankings-left')"));
      expect(viewer, contains("Key('viewer-live-rankings-button')"));
      expect(host, contains('showNativeLiveRankings'));
      expect(viewer, contains('showNativeLiveRankings'));
    });
  });
}

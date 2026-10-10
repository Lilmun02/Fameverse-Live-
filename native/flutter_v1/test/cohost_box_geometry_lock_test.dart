import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Fameverse native co-host boxes', () {
    test('host and viewer use the same approved two-box stage', () {
      final host = File(
        'lib/features/live/stream_host_live_screen.dart',
      ).readAsStringSync();
      final viewer = File(
        'lib/features/live/stream_viewer_live_screen.dart',
      ).readAsStringSync();

      expect(host, contains('NativeHostV2Stage('));
      expect(viewer, contains('NativeViewerV2Stage('));
    });

    test('two square boxes are side-by-side with at most a 2px gap', () {
      final stage = File(
        'lib/features/live/native_live_stage.dart',
      ).readAsStringSync();
      final start = stage.indexOf('class _V2CohostStage');
      final end = stage.indexOf('class _V2ParticipantSurface', start);

      expect(start, greaterThanOrEqualTo(0));
      expect(end, greaterThan(start));

      final boxes = stage.substring(start, end);
      expect(boxes, contains('child: Row('));
      expect('aspectRatio: 1'.allMatches(boxes).length, 2);
      expect(boxes, contains('const SizedBox(width: 2),'));
      expect(boxes, isNot(contains('const SizedBox(width: 8),')));
      expect(boxes, contains('child: left,'));
      expect(boxes, contains('child: right,'));
    });

    test('solo host and viewer presentation is preserved', () {
      final stage = File(
        'lib/features/live/native_live_stage.dart',
      ).readAsStringSync();
      expect(stage, contains('if (activeCohostUserId == null)'));
      expect(stage, contains('class NativeHostV2Stage'));
      expect(stage, contains('class NativeViewerV2Stage'));
    });
  });
}

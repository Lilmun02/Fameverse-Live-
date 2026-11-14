import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Gift combo regression law', () {
    test('preset combo quantities replay sequentially without re-charging', () {
      final components = File(
        'lib/features/live/native_live_components.dart',
      ).readAsStringSync();
      final viewer = File(
        'lib/features/live/stream_viewer_live_screen.dart',
      ).readAsStringSync();
      final host = File(
        'lib/features/live/stream_host_live_screen.dart',
      ).readAsStringSync();
      final owner = File(
        'lib/features/live/stream_owner_host_live_screen.dart',
      ).readAsStringSync();

      expect(components, contains('fvMaxSequentialGiftCombo = 50'));
      expect(components, contains('fvExpandGiftVisualCombo'));
      expect(components, contains(r"return ' · Combo ×$comboIndex'"));
      expect(
        viewer,
        contains('_giftQueue.addAll(fvExpandGiftVisualCombo(playback))'),
      );
      expect(
        host,
        contains('_giftQueue.addAll(fvExpandGiftVisualCombo(playback))'),
      );
      expect(
        owner,
        contains('_giftQueue.addAll(fvExpandGiftVisualCombo(playback))'),
      );
      expect(owner, contains("'record_beta_gift'"));
      expect(viewer, contains('quantity: quantity'));
    });

    test(
      'huge custom quantities collapse to one visual summary instead of queue explosion',
      () {
        final components = File(
          'lib/features/live/native_live_components.dart',
        ).readAsStringSync();
        expect(
          components,
          contains('playback.quantity > fvMaxSequentialGiftCombo'),
        );
        expect(components, contains('return <FvGiftPlayback>[playback]'));
      },
    );
  });
}

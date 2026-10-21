import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:fameverse_live/data/fameverse_live_backend.dart';

void main() {
  test('every existing under-100 gift is noncinematic and silent', () {
    final gifts = fvGiftCatalog.where((gift) => gift.cost < 100).toList();
    expect(gifts, isNotEmpty);
    for (final gift in gifts) {
      expect(gift.cinematic, isFalse, reason: gift.id);
      expect(gift.videoUrl, isNull, reason: gift.id);
    }
  });

  test(
    'native lightweight gift uses tiny mid-left art, not a full overlay',
    () {
      final source = File(
        'lib/features/live/native_live_components.dart',
      ).readAsStringSync();

      expect(source, contains('Widget _lightweightGift('));
      expect(source, contains('width: 56,'));
      expect(source, contains('height: 48,'));
      expect(source, contains('Alignment(-0.85, 0.1)'));
      expect(source, contains('if (playback.gift.cost < 100)'));
      expect(source, contains('if (gift.cost < 100 || !gift.cinematic'));
      expect(source, contains('return _lightweightGift(playback);'));
      expect(source, contains("Key('lightweight-gift-"));
      expect(source, contains('child: Semantics('));
    },
  );
}

import 'dart:io';

import 'package:flutter/material.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:fameverse_live/features/live/native_live_components.dart';
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

  test('native lightweight gift uses tiny mid-left art, not a full overlay', () {
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
  });
  testWidgets('cheap gifts render 56 by 48 symbol with no video player', (
    tester,
  ) async {
    final cheapGift = fvGiftCatalog.firstWhere((gift) => gift.cost < 100);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NativeGiftOverlay(
            playback: FvGiftPlayback(
              gift: cheapGift,
              quantity: 1,
              sender: 'Tester',
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final smallGift = find.byKey(Key('lightweight-gift-${cheapGift.id}'));
    expect(smallGift, findsOneWidget);
    expect(tester.getSize(smallGift), const Size(56, 48));
    expect(find.text(cheapGift.symbol), findsOneWidget);
    expect(
      find.byKey(Key('cinematic-gift-presentation-${cheapGift.id}')),
      findsNothing,
    );
  });

}

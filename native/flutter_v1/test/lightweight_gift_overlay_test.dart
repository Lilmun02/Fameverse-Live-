import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_player/video_player.dart';

import 'package:fameverse_live/data/fameverse_live_backend.dart';
import 'package:fameverse_live/features/live/native_live_components.dart';

void main() {
  testWidgets('under-100 gifts never cover the Live stage or start video', (
    tester,
  ) async {
    final gift = fvGiftCatalog.firstWhere((item) => item.cost < 100);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              const SizedBox.expand(),
              NativeGiftOverlay(
                playback: FvGiftPlayback(
                  gift: gift,
                  quantity: 1,
                  sender: 'Viewer',
                ),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump();
    final glyph = find.byKey(Key('lightweight-gift-${gift.id}'));
    expect(glyph, findsOneWidget);
    expect(tester.getSize(glyph), const Size(56, 48));
    expect(find.byType(VideoPlayer), findsNothing);
    expect(find.byKey(Key('cinematic-gift-presentation-${gift.id}')), findsNothing);
    expect(find.text('Loading premium gift…'), findsNothing);
    expect(find.text(gift.label), findsNothing);
  });

  testWidgets('even miscategorized cheap cinematic gifts stay lightweight', (
    tester,
  ) async {
    const gift = FvGiftDefinition(
      id: 'misconfigured-cheap',
      label: 'Tiny',
      cost: 5,
      category: 'test',
      emoji: '✦',
      cinematic: true,
      videoUrl: 'https://example.invalid/not-loaded.mp4',
    );
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: NativeGiftOverlay(
            playback: FvGiftPlayback(
              gift: gift,
              quantity: 1,
              sender: 'Tester',
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.byKey(const Key('lightweight-gift-misconfigured-cheap')), findsOneWidget);
    expect(find.byType(VideoPlayer), findsNothing);
  });
}

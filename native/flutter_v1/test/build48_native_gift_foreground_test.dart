import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fameverse_live/data/fameverse_live_backend.dart';
import 'package:fameverse_live/features/live/native_live_components.dart';

void main() {
  testWidgets('one-coin gift keeps sender visible without an opaque panel', (
    tester,
  ) async {
    const gift = FvGiftDefinition(
      id: 'test-rose',
      label: 'Rose',
      cost: 1,
      category: 'support',
      emoji: '🌹',
    );
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: NativeGiftOverlay(
            playback: FvGiftPlayback(
              gift: gift,
              quantity: 1,
              sender: 'Sender A',
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    final surface = find.byKey(const Key('lightweight-gift-test-rose'));
    expect(surface, findsOneWidget);
    expect(tester.widget<Container>(surface).decoration, isNull);
    expect(find.text('Sender A sent Rose'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('non-video premium gift has sender and no backplate', (
    tester,
  ) async {
    const gift = FvGiftDefinition(
      id: 'test-premium',
      label: 'Universe',
      cost: 200,
      category: 'fameverse',
      activityEmoji: '✦',
    );
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: NativeGiftOverlay(
            playback: FvGiftPlayback(
              gift: gift,
              quantity: 1,
              sender: 'Sender B',
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(
      find.byKey(const Key('native-gift-presentation-test-premium')),
      findsOneWidget,
    );
    expect(find.text('Sender B sent Universe'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}

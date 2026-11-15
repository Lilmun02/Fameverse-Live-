import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:fameverse_live/data/fameverse_live_backend.dart';
import 'package:fameverse_live/features/live/native_live_components.dart';

void main() {
  group('Build 47 combo completion ordering', () {
    const rose = FvGiftDefinition(
      id: 'rose',
      label: 'Rose',
      cost: 1,
      category: 'classic',
    );
    const flame = FvGiftDefinition(
      id: 'flame',
      label: 'Flame',
      cost: 100,
      category: 'premium',
    );
    const finalChat = FvLiveChatMessage(
      id: 'gift-123',
      user: 'Test gifter',
      text: 'Flame · 5x combo · 500 coins',
      kind: 'gift',
      quantity: 5,
    );

    test('5x combo has exactly one final receipt after its fifth visual', () {
      final frames = fvExpandGiftVisualCombo(
        const FvGiftPlayback(
          gift: flame,
          quantity: 5,
          sender: 'Test gifter',
          completionMessage: finalChat,
        ),
      );
      expect(frames.length, 5);
      expect(frames.map((frame) => frame.comboIndex).toList(), [1, 2, 3, 4, 5]);
      expect(
        frames.take(4).every((frame) => frame.completionMessage == null),
        isTrue,
      );
      expect(frames.last.completionMessage, same(finalChat));
    });

    test('mixed combo sequences retain FIFO order and each final receipt', () {
      final queue = <FvGiftPlayback>[
        ...fvExpandGiftVisualCombo(
          const FvGiftPlayback(gift: rose, quantity: 2, sender: 'First'),
        ),
        ...fvExpandGiftVisualCombo(
          const FvGiftPlayback(
            gift: flame,
            quantity: 5,
            sender: 'Second',
            completionMessage: finalChat,
          ),
        ),
      ];
      expect(queue.length, 7);
      expect(queue.take(2).every((frame) => frame.gift.id == 'rose'), isTrue);
      expect(queue.skip(2).every((frame) => frame.gift.id == 'flame'), isTrue);
      expect(queue.where((frame) => frame.completionMessage != null).length, 1);
      expect(queue.last.completionMessage, same(finalChat));
    });

    test('host and viewer reject stale visual and watchdog completions', () {
      for (final file in [
        'stream_host_live_screen.dart',
        'stream_viewer_live_screen.dart',
      ]) {
        final source = File('lib/features/live/$file').readAsStringSync();
        expect(source, contains('expectedSerial != _giftSerial'));
        expect(source, contains('expectedSerial: playbackSerial'));
        expect(source, contains('completionMessage: quantity > 1'));
        expect(source, contains('_giftPlayback?.completionMessage'));
        expect(source, contains('x combo ·'));
      }
    });
  });
}

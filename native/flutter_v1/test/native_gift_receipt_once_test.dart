import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:fameverse_live/data/fameverse_live_backend.dart';
import 'package:fameverse_live/features/live/native_live_components.dart';
import 'package:fameverse_live/features/live/native_gift_receipt_gate.dart';

void main() {
  test('one receipt ID can render only once on a device', () {
    final gate = FvGiftReceiptGate();
    expect(gate.shouldRender('gift-100'), isTrue);
    expect(gate.shouldRender('gift-100'), isFalse);
    expect(gate.shouldRender('gift-100'), isFalse);
  });

  test('two legitimate one-coin sends of the same gift both render', () {
    final gate = FvGiftReceiptGate();
    expect(gate.shouldRender('rose-event-1'), isTrue);
    expect(gate.shouldRender('rose-event-2'), isTrue);
    expect(gate.shouldRender('rose-event-1'), isFalse);
  });

  test('combo receipts with independent IDs do not get suppressed', () {
    final gate = FvGiftReceiptGate();
    for (var index = 1; index <= 5; index++) {
      expect(gate.shouldRender('combo-$index'), isTrue);
    }
  });

  test('bounded cache evicts old IDs and tolerates legacy events', () {
    final gate = FvGiftReceiptGate(maxEntries: 2);
    expect(gate.shouldRender('a'), isTrue);
    expect(gate.shouldRender('b'), isTrue);
    expect(gate.shouldRender('c'), isTrue);
    expect(gate.shouldRender('b'), isFalse);
    expect(gate.shouldRender('a'), isTrue);
    expect(gate.shouldRender(null), isTrue);
    expect(gate.shouldRender(''), isTrue);
  });

  test('five premium Dragons queue five separate combo movies in order', () {
    final premium = fvGiftCatalog.firstWhere((gift) => gift.cinematic);
    final playback = FvGiftPlayback(
      gift: premium,
      quantity: 5,
      sender: 'Combo tester',
    );
    final queue = fvExpandGiftVisualCombo(playback);
    expect(queue, hasLength(5));
    expect(queue.every((item) => item.gift.id == premium.id), isTrue);
    expect(queue.every((item) => item.quantity == 1), isTrue);
    expect(queue.map((item) => item.comboIndex), [1, 2, 3, 4, 5]);
    expect(queue.every((item) => item.comboTotal == 5), isTrue);
    expect(queue.first.visualCountLabel, contains('Combo 1/5'));
    expect(queue.last.visualCountLabel, contains('Combo 5/5'));
    expect(fvGiftPlaybackWatchdog(queue.first), const Duration(seconds: 90));
  });

  test('three premium combo receipts queue all 15 movies FIFO', () {
    final premium = fvGiftCatalog.where((gift) => gift.cinematic).take(3);
    final queue = <FvGiftPlayback>[];
    final expectedGiftIds = <String>[];
    for (final gift in premium) {
      final playback = FvGiftPlayback(
        gift: gift,
        quantity: 5,
        sender: 'Tester',
      );
      queue.addAll(fvExpandGiftVisualCombo(playback));
      expectedGiftIds.addAll(List<String>.filled(5, gift.id));
    }
    expect(queue, hasLength(15));
    expect(queue.map((item) => item.gift.id).toList(), expectedGiftIds);
    expect(queue.map((item) => item.comboIndex).toList(), [
      1, 2, 3, 4, 5,
      1, 2, 3, 4, 5,
      1, 2, 3, 4, 5,
    ]);
    expect(queue.every((item) => item.quantity == 1), isTrue);
  });

  test('lightweight gifts preserve incremental 5x combo presentation', () {
    final cheapGift = fvGiftCatalog.firstWhere((gift) => gift.cost < 100);
    final playback = FvGiftPlayback(
      gift: cheapGift,
      quantity: 5,
      sender: 'Tester',
    );
    final queue = fvExpandGiftVisualCombo(playback);
    final timeout = fvGiftPlaybackWatchdog(queue.first);
    expect(queue, hasLength(5));
    expect(queue.map((item) => item.comboIndex), [1, 2, 3, 4, 5]);
    expect(timeout, const Duration(seconds: 8));
  });

  testWidgets('identical combo gifts play one at a time with visible progress', (
    tester,
  ) async {
    const dragon = FvGiftDefinition(
      id: 'test-dragon',
      label: 'Dragon',
      cost: 1000,
      category: 'fameverse',
      emoji: '🐉',
    );
    final queue = fvExpandGiftVisualCombo(
      const FvGiftPlayback(gift: dragon, quantity: 5, sender: 'Tester'),
    );
    final completed = <int>[];
    var active = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setStage) => Stack(
              children: [
                if (active < queue.length)
                  NativeGiftOverlay(
                    key: ValueKey('stage-$active'),
                    playback: queue[active],
                    onFinished: () {
                      completed.add(active + 1);
                      setStage(() => active++);
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    for (var stage = 1; stage <= 5; stage++) {
      expect(
        find.byKey(Key('gift-combo-stage-$stage-of-5')),
        findsOneWidget,
      );
      expect(find.text('COMBO $stage/5'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 3100));
    }
    expect(completed, [1, 2, 3, 4, 5]);
    expect(find.byType(NativeGiftOverlay), findsNothing);
  });

  test('owner host shows chat but skips its duplicate local QA overlay', () {
    final host = File(
      'lib/features/live/stream_host_live_screen.dart',
    ).readAsStringSync();
    final viewer = File(
      'lib/features/live/stream_viewer_live_screen.dart',
    ).readAsStringSync();

    expect(host, contains("payload['qaHostPreview'] == true"));
    expect(host, contains("payload['senderId'] == widget.identity.id"));
    expect(host, contains('if (!ownerLocalPreview)'));
    expect(host, contains('_appendChat('));
    expect(host, contains('_giftEventGate.shouldRender'));
    expect(viewer, contains('_giftEventGate.shouldRender(eventId)'));
    expect(
      viewer,
      contains("_giftEventGate.shouldRender(payload['id']?.toString())"),
    );
  });

  test('three distinct gifts with 5x combos keep every receipt unique', () {
    final catalog = fvGiftCatalog.where((gift) => gift.cinematic).take(3).toList();
    expect(catalog.length, 3);
    final gate = FvGiftReceiptGate();
    final queue = <FvGiftPlayback>[];

    for (var giftIndex = 0; giftIndex < catalog.length; giftIndex++) {
      final receiptId = 'room-1-gift-$giftIndex-combo-5';
      expect(gate.shouldRender(receiptId), isTrue);
      expect(gate.shouldRender(receiptId), isFalse);
      queue.addAll(
        fvExpandGiftVisualCombo(
          FvGiftPlayback(
            gift: catalog[giftIndex],
            quantity: 5,
            sender: 'viewer-$giftIndex',
          ),
        ),
      );
    }

    expect(queue.length, 15);
    expect(queue.where((item) => item.comboIndex == 5).length, 3);
    expect(queue.every((item) => item.comboTotal == 5), isTrue);
    expect(queue.map((item) => item.gift.id).toSet().length, 3);
  });
}

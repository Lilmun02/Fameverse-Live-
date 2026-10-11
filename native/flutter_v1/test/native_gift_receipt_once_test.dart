import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
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
    expect(host, contains('_chat.add('));
    expect(host, contains('_giftEventGate.shouldRender'));
    expect(viewer, contains('_giftEventGate.shouldRender(eventId)'));
    expect(
      viewer,
      contains("_giftEventGate.shouldRender(payload['id']?.toString())"),
    );
  });
}

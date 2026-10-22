import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:fameverse_live/features/live/native_gift_receipt_gate.dart';
import 'package:fameverse_live/features/live/native_live_components.dart';
import 'package:fameverse_live/data/fameverse_live_backend.dart';

void main() {
  test('premium videos have enough time to finish before emergency fallback', () {
    final cinematic = fvGiftCatalog.firstWhere(
      (gift) => gift.cinematic && (gift.videoUrl?.isNotEmpty ?? false),
    );
    final staticGift = fvGiftCatalog.firstWhere((gift) => gift.cost < 100);
    expect(
      fvGiftPlaybackWatchdog(
        FvGiftPlayback(gift: cinematic, quantity: 1, sender: 'QA'),
      ),
      const Duration(seconds: 90),
    );
    expect(
      fvGiftPlaybackWatchdog(
        FvGiftPlayback(gift: staticGift, quantity: 1, sender: 'QA'),
      ),
      const Duration(seconds: 8),
    );
  });

  test('host, viewer and QA wrapper use completion-safe gift watchdogs', () {
    for (final path in [
      'lib/features/live/stream_host_live_screen.dart',
      'lib/features/live/stream_viewer_live_screen.dart',
      'lib/features/live/stream_owner_host_live_screen.dart',
    ]) {
      final source = File(path).readAsStringSync();
      expect(source, contains('fvGiftPlaybackWatchdog(next)'));
      expect(source, isNot(contains('Timer(const Duration(seconds: 20), _playNext')));
    }
  });


  test('an authoritative receipt renders once even when delivered repeatedly', () {
    final gate = FvGiftReceiptGate();
    expect(gate.shouldRender('receipt-1'), isTrue);
    expect(gate.shouldRender('receipt-1'), isFalse);
    expect(gate.shouldRender(' receipt-1 '), isFalse);
  });

  test('legitimate separate gifts are not suppressed by matching names', () {
    final gate = FvGiftReceiptGate();
    for (var i = 1; i <= 15; i++) {
      expect(gate.shouldRender('dragon-gift-$i'), isTrue);
    }
    expect(gate.shouldRender('dragon-gift-1'), isFalse);
  });

  test('bounded cache tolerates legacy receipts while rejecting known echoes', () {
    final gate = FvGiftReceiptGate(maxEntries: 2);
    expect(gate.shouldRender(null), isTrue);
    expect(gate.shouldRender(''), isTrue);
    expect(gate.shouldRender('a'), isTrue);
    expect(gate.shouldRender('b'), isTrue);
    expect(gate.shouldRender('b'), isFalse);
    expect(gate.shouldRender('c'), isTrue);
    expect(gate.shouldRender('a'), isTrue);
  });

  test('both host and viewer gate inbound gift receipt IDs', () {
    final host = File('lib/features/live/stream_host_live_screen.dart')
        .readAsStringSync();
    final viewer = File('lib/features/live/stream_viewer_live_screen.dart')
        .readAsStringSync();
    expect(host, contains("_giftEventGate.shouldRender(payload['id']?.toString())"));
    expect(viewer, contains("_giftEventGate.shouldRender(payload['id']?.toString())"));
    expect(viewer, contains('_giftEventGate.shouldRender(eventId);'));
    expect(host, contains("payload['qaHostPreview'] == true"));
    expect(host, contains('if (!ownerLocalPreview)'));
  });
}

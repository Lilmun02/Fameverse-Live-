import 'package:flutter_test/flutter_test.dart';
import 'package:fameverse_live/data/fameverse_live_backend.dart';
import 'package:fameverse_live/features/live/native_gift_receipt_gate.dart';
import 'package:fameverse_live/features/live/native_live_components.dart';

void main() {
  test('one receipt cannot render twice', () {
    final gate = FvGiftReceiptGate();
    expect(gate.shouldRender('receipt-1'), isTrue);
    expect(gate.shouldRender('receipt-1'), isFalse);
    expect(gate.shouldRender(' receipt-1 '), isFalse);
  });

  test('fifteen different gift receipts remain distinct', () {
    final gate = FvGiftReceiptGate();
    for (var index = 1; index <= 15; index++) {
      expect(gate.shouldRender('dragon-$index'), isTrue);
    }
    expect(gate.shouldRender('dragon-1'), isFalse);
  });

  test('legacy IDs and cache eviction remain safe', () {
    final gate = FvGiftReceiptGate(maxEntries: 2);
    expect(gate.shouldRender(null), isTrue);
    expect(gate.shouldRender(''), isTrue);
    expect(gate.shouldRender('a'), isTrue);
    expect(gate.shouldRender('b'), isTrue);
    expect(gate.shouldRender('b'), isFalse);
    expect(gate.shouldRender('c'), isTrue);
    expect(gate.shouldRender('a'), isTrue);
  });

  test('premium video watchdog allows full playback', () {
    final premium = fvGiftCatalog.firstWhere((gift) => gift.videoUrl != null);
    final playback = FvGiftPlayback(gift: premium, quantity: 1, sender: 'QA');
    expect(fvGiftPlaybackWatchdog(playback).inSeconds, 90);
  });

  test('lightweight gift has short fallback watchdog', () {
    final gift = fvGiftCatalog.firstWhere((gift) => gift.cost < 100);
    final playback = FvGiftPlayback(gift: gift, quantity: 1, sender: 'QA');
    expect(fvGiftPlaybackWatchdog(playback).inSeconds, 8);
  });
}

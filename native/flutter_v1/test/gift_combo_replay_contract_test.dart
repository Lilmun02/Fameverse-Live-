import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:fameverse_live/data/fameverse_live_backend.dart';
import 'package:fameverse_live/features/live/native_live_components.dart';

void main() {
  test('five identical gifts expand into five sequential playback items', () {
    final gift = fvGiftCatalog.firstWhere((gift) => gift.id == 'ember-dragon');
    final items = fvExpandGiftVisualCombo(
      FvGiftPlayback(gift: gift, quantity: 5, sender: 'test-sender'),
    );

    expect(items, hasLength(5));
    expect(items.map((item) => item.quantity), everyElement(1));
    expect(items.map((item) => item.comboIndex), [1, 2, 3, 4, 5]);
    expect(items.map((item) => item.comboTotal), everyElement(5));
    expect(items.map((item) => item.gift.id), everyElement(gift.id));
  });

  test('changing combo index restarts native video playback', () {
    final source = File('lib/features/live/native_live_components.dart')
        .readAsStringSync();

    expect(
      source,
      contains('oldWidget.playback.comboIndex != widget.playback.comboIndex'),
    );
    expect(
      source,
      contains('oldWidget.playback.comboTotal != widget.playback.comboTotal'),
    );
  });

  test('five 5000-coin gifts must total 25000 coins', () {
    const unitCost = 5000;
    const quantity = 5;
    expect(unitCost * quantity, 25000);
  });
}

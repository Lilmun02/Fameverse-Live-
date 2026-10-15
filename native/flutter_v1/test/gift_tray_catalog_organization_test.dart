import 'package:flutter_test/flutter_test.dart';
import 'package:fameverse_live/data/fameverse_live_backend.dart';
import 'package:fameverse_live/features/live/native_live_components.dart';

void main() {
  test('the All gifts tab never silently omits catalog gifts', () {
    final all = fvGiftsForTrayCategory('all');
    expect(all.length, fvGiftCatalog.length);
    expect(all.map((gift) => gift.id).toSet().length, fvGiftCatalog.length);
  });

  test('small and premium tabs partition the entire gift catalog', () {
    final small = fvGiftsForTrayCategory('small');
    final premium = fvGiftsForTrayCategory('premium');
    expect(small, isNotEmpty);
    expect(premium, isNotEmpty);
    expect(small.every((gift) => gift.cost < 100), isTrue);
    expect(premium.every((gift) => gift.cost >= 100), isTrue);
    expect(small.length + premium.length, fvGiftCatalog.length);
  });

  test('Fameverse collection is accessible regardless of gift price', () {
    final branded = fvGiftsForTrayCategory('fameverse');
    final expected = fvGiftCatalog
        .where((gift) => gift.category == 'fameverse')
        .toList();
    expect(branded.map((gift) => gift.id).toSet(),
        expected.map((gift) => gift.id).toSet());
  });

  test('all tabs are sorted low to high and preserve gift prices', () {
    final originals = {for (final gift in fvGiftCatalog) gift.id: gift.cost};
    for (final tab in ['all', 'small', 'premium', 'fameverse']) {
      final gifts = fvGiftsForTrayCategory(tab);
      for (var index = 0; index < gifts.length; index++) {
        final gift = gifts[index];
        expect(gift.cost, originals[gift.id]);
        if (index > 0) {
          expect(gifts[index - 1].cost <= gift.cost, isTrue);
        }
      }
    }
  });
}

import 'fameverse_gift_catalog_core.dart';
import 'fameverse_gift_catalog_premium.dart';
import 'fameverse_live_models.dart';

const fvGiftCatalog = <FvGiftDefinition>[
  ...fvCoreGiftCatalog,
  ...fvPremiumGiftCatalog,
];

FvGiftDefinition? fvGiftById(String? id) {
  if (id == null) return null;
  for (final gift in fvGiftCatalog) {
    if (gift.id == id) return gift;
  }
  return null;
}

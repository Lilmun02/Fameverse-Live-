/// One visual/audio gift presentation per authoritative Live receipt ID.
/// A new ID always represents a new gift, even for the same gift catalog item.
class FvGiftReceiptGate {
  FvGiftReceiptGate({this.maxEntries = 256})
    : assert(maxEntries > 0);

  final int maxEntries;
  final Set<String> _seen = <String>{};
  final List<String> _order = <String>[];

  /// Returns false only for a duplicate of the same receipt ID.
  /// Legacy events without IDs remain visible rather than hiding real gifts.
  bool shouldRender(String? receiptId) {
    final id = receiptId?.trim();
    if (id == null || id.isEmpty) return true;
    if (!_seen.add(id)) return false;
    _order.add(id);
    if (_order.length > maxEntries) {
      _seen.remove(_order.removeAt(0));
    }
    return true;
  }
}

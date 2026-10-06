part of 'fame_coin_store_screen.dart';

class _StoreUnavailableCard extends StatelessWidget {
  const _StoreUnavailableCard({
    required this.missingCount,
    required this.isIos,
  });

  final int missingCount;
  final bool isIos;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: const Color(0xFF17111B),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF45334D)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.storefront_outlined, color: Color(0xFFC895F5)),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              isIos
                  ? missingCount > 0
                        ? 'The Fame Coin store is wired, but these packs are not available from App Store Connect yet. No charge can occur until Apple returns an active product.'
                        : 'The App Store is unavailable right now. Pull down to retry.'
                  : 'Google Play Fame Coin purchases are not enabled in this beta build yet.',
              style: const TextStyle(
                color: Color(0xFFB8ACBC),
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StripeUnavailableCard extends StatelessWidget {
  const _StripeUnavailableCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('stripe-checkout-unavailable'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF17111B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF45334D)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.lock_outline_rounded,
            color: Color(0xFFC895F5),
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFFB8ACBC),
                fontSize: 11,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StripeOfferCard extends StatelessWidget {
  const _StripeOfferCard({
    required this.offer,
    required this.enabled,
    required this.busy,
    required this.onBuy,
  });

  final _StripeOffer offer;
  final bool enabled;
  final bool busy;
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: Key('stripe-pack-${offer.id}'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF17111B),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF493057)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: Color(0xFF2D1B39),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.credit_card_rounded,
              color: Color(0xFFD4A2FF),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  offer.label,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${offer.coins} Fame Coins · ${offer.priceLabel}',
                  style: const TextStyle(
                    color: Color(0xFFA99DAC),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          FilledButton(
            key: Key('stripe-buy-${offer.id}'),
            onPressed: enabled && !busy ? onBuy : null,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF8E46DE),
            ),
            child: Text(busy ? 'Opening…' : 'Buy'),
          ),
        ],
      ),
    );
  }
}

class _PurchaseSafetyNote extends StatelessWidget {
  const _PurchaseSafetyNote();

  @override
  Widget build(BuildContext context) {
    return const Text(
      'Fame Coins are consumable digital currency for gifting inside Fameverse. Apple purchases are credited only after server-side Apple verification. Stripe purchases are credited only after a signed Stripe webhook confirms payment. Creator earnings and owner reward reserves are separate balances.',
      textAlign: TextAlign.center,
      style: TextStyle(color: Color(0xFF817785), fontSize: 10, height: 1.45),
    );
  }
}

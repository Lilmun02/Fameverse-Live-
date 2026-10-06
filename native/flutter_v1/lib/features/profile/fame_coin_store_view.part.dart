part of 'fame_coin_store_screen.dart';

extension _FameCoinStoreView on _FameCoinStoreScreenState {
  Widget buildView(BuildContext context) {
    return Scaffold(
      key: const Key('public-fame-coin-store'),
      backgroundColor: const Color(0xFF0C0810),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0C0810),
        title: const Text('Buy Fame Coins'),
        actions: [
          IconButton(
            onPressed: _loading || _verifying || _stripeLoading
                ? null
                : _refreshAll,
            tooltip: 'Refresh store',
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshAll,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 38),
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: const Color(0xFF693B80)),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF321643), Color(0xFF17101E)],
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF51276B),
                      ),
                      child: const Icon(
                        Icons.toll_rounded,
                        color: Color(0xFFDCAEFF),
                        size: 27,
                      ),
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Your Fame Coins',
                            style: TextStyle(
                              color: Color(0xFFBDAFC2),
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            '$_balance',
                            key: const Key('public-fame-coin-balance'),
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'SECURE STORE',
                          style: TextStyle(
                            color: Color(0xFFC98BFF),
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'Verified checkout',
                          style: TextStyle(
                            color: Color(0xFF9F94A4),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (_notice != null) ...[
                const SizedBox(height: 12),
                Container(
                  key: const Key('fame-coin-store-notice'),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF201627),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF513260)),
                  ),
                  child: Text(
                    _notice!,
                    style: const TextStyle(
                      color: Color(0xFFD5C8DA),
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 22),
              const Text(
                'App Store packs',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 5),
              const Text(
                'Apple shows the localized purchase price and handles the App Store checkout. Applicable taxes are reflected by Apple where required.',
                style: TextStyle(
                  color: Color(0xFFA79BAA),
                  fontSize: 11,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 14),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 54),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (!_storeAvailable || _products.isEmpty)
                _StoreUnavailableCard(
                  missingCount: _missingProductIds.length,
                  isIos: Platform.isIOS,
                )
              else
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _products.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: .94,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemBuilder: (context, index) {
                    final product = _products[index];
                    final coins = _coins(product);
                    final busy = _busyProductId == product.id || _verifying;
                    return Container(
                      key: Key('fame-coin-pack-${product.id}'),
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: const Color(0xFF17111B),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFF493057)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.toll_rounded,
                            color: Color(0xFFD4A2FF),
                          ),
                          const Spacer(),
                          Text(
                            '$coins',
                            style: const TextStyle(
                              fontSize: 25,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const Text(
                            'Fame Coins',
                            style: TextStyle(
                              color: Color(0xFFA99DAC),
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(height: 8),
                          FilledButton(
                            key: Key('buy-${product.id}'),
                            onPressed: busy ? null : () => _buy(product),
                            style: FilledButton.styleFrom(
                              minimumSize: const Size.fromHeight(42),
                              backgroundColor: const Color(0xFF8E46DE),
                            ),
                            child: Text(
                              busy ? 'Processing…' : product.price,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              const SizedBox(height: 28),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Stripe Checkout',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Container(
                    key: const Key('stripe-environment-badge'),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2B1A34),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: const Color(0xFF68407B)),
                    ),
                    child: Text(
                      _stripeEnvironment == 'live'
                          ? 'STRIPE LIVE'
                          : 'STRIPE TEST',
                      style: const TextStyle(
                        color: Color(0xFFCFA1F2),
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              const Text(
                'Stripe opens its hosted Checkout page in your browser. Fameverse never collects your card number and only credits coins after the signed Stripe webhook is verified on the server.',
                style: TextStyle(
                  color: Color(0xFFA79BAA),
                  fontSize: 11,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 14),
              if (_stripeLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_stripeOffers.isEmpty)
                const _StripeUnavailableCard(
                  message:
                      'Stripe Checkout packs could not be loaded right now.',
                )
              else ...[
                if (!_stripeCheckoutEnabled)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 10),
                    child: _StripeUnavailableCard(
                      message:
                          'Stripe Checkout is wired but disabled until the matching test/live Stripe secrets are configured on the Fameverse backend.',
                    ),
                  ),
                for (final offer in _stripeOffers) ...[
                  _StripeOfferCard(
                    offer: offer,
                    enabled: _stripeCheckoutEnabled,
                    busy: _stripeBusyPackId == offer.id,
                    onBuy: () => _buyWithStripe(offer),
                  ),
                  const SizedBox(height: 10),
                ],
              ],
              const SizedBox(height: 8),
              const _PurchaseSafetyNote(),
            ],
          ),
        ),
      ),
    );
  }
}

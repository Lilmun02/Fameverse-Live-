import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class FameCoinStoreScreen extends StatefulWidget {
  const FameCoinStoreScreen({
    required this.userId,
    this.onBalanceChanged,
    super.key,
  });

  final String userId;
  final ValueChanged<int>? onBalanceChanged;

  @override
  State<FameCoinStoreScreen> createState() => _FameCoinStoreScreenState();
}

class _StripeOffer {
  const _StripeOffer({
    required this.id,
    required this.label,
    required this.coins,
    required this.priceCents,
    required this.currency,
  });

  final String id;
  final String label;
  final int coins;
  final int priceCents;
  final String currency;

  String get priceLabel {
    final amount = (priceCents / 100).toStringAsFixed(2);
    return currency.toUpperCase() == 'USD'
        ? '\$$amount'
        : '${currency.toUpperCase()} $amount';
  }
}

class _FameCoinStoreScreenState extends State<FameCoinStoreScreen>
    with WidgetsBindingObserver {
  final InAppPurchase _store = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;

  bool _loading = true;
  bool _storeAvailable = false;
  bool _verifying = false;
  bool _stripeLoading = true;
  bool _stripeCheckoutEnabled = false;
  bool _awaitingStripeReturn = false;
  String _stripeEnvironment = 'test';
  String? _busyProductId;
  String? _stripeBusyPackId;
  String? _notice;
  int _balance = 0;
  Map<String, int> _coinByProduct = const {};
  List<ProductDetails> _products = const [];
  Set<String> _missingProductIds = const {};
  List<_StripeOffer> _stripeOffers = const [];

  SupabaseClient get _client => Supabase.instance.client;
  String get _platform => Platform.isIOS ? 'ios' : 'android';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _purchaseSubscription = _store.purchaseStream.listen(
      _handlePurchases,
      onError: (_) {
        if (!mounted) return;
        setState(() {
          _busyProductId = null;
          _verifying = false;
          _notice = 'The App Store purchase connection was interrupted.';
        });
      },
    );
    unawaited(_refreshAll());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_purchaseSubscription?.cancel());
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _awaitingStripeReturn) {
      _awaitingStripeReturn = false;
      unawaited(_refreshWalletAfterStripe());
    }
  }

  Future<void> _refreshAll() async {
    await Future.wait<void>([_load(), _loadStripeConfig()]);
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _notice = null;
    });

    try {
      final catalogRaw = await _client.rpc(
        'get_fame_coin_store_products',
        params: {'p_platform': _platform},
      );
      final catalogRows = catalogRaw is List
          ? catalogRaw.whereType<Map>().map(Map<String, dynamic>.from).toList()
          : <Map<String, dynamic>>[];
      final coinMap = <String, int>{
        for (final row in catalogRows)
          if ((row['product_id']?.toString() ?? '').isNotEmpty)
            row['product_id'].toString(): (row['coins'] as num?)?.toInt() ?? 0,
      }..removeWhere((_, coins) => coins <= 0);

      final wallet = await _client
          .from('beta_coin_wallets')
          .select('balance')
          .eq('user_id', widget.userId)
          .maybeSingle();
      final balance = (wallet?['balance'] as num?)?.toInt() ?? 0;

      if (!Platform.isIOS) {
        if (!mounted) return;
        setState(() {
          _coinByProduct = coinMap;
          _balance = balance;
          _storeAvailable = false;
          _products = const [];
          _missingProductIds = coinMap.keys.toSet();
          _loading = false;
          _notice =
              'Google Play Fame Coin purchases are not enabled in this beta build yet.';
        });
        return;
      }

      final available = await _store.isAvailable();
      if (!available) {
        if (!mounted) return;
        setState(() {
          _coinByProduct = coinMap;
          _balance = balance;
          _storeAvailable = false;
          _products = const [];
          _missingProductIds = coinMap.keys.toSet();
          _loading = false;
          _notice = 'The App Store is unavailable on this device right now.';
        });
        return;
      }

      final response = await _store.queryProductDetails(coinMap.keys.toSet());
      final products =
          response.productDetails
              .where((product) => coinMap.containsKey(product.id))
              .toList()
            ..sort(
              (a, b) => (coinMap[a.id] ?? 0).compareTo(coinMap[b.id] ?? 0),
            );

      if (!mounted) return;
      setState(() {
        _coinByProduct = coinMap;
        _balance = balance;
        _storeAvailable = true;
        _products = products;
        _missingProductIds = response.notFoundIDs.toSet();
        _loading = false;
        if (response.error != null) {
          _notice = 'The App Store could not load every Fame Coin pack.';
        } else if (products.isEmpty && coinMap.isNotEmpty) {
          _notice =
              'Fame Coin packs are not available from App Store Connect yet.';
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _notice = 'Fameverse could not load the coin store right now.';
      });
    }
  }

  Future<void> _loadStripeConfig() async {
    if (!mounted) return;
    setState(() => _stripeLoading = true);

    try {
      final response = await _client.functions.invoke(
        'stripe-checkout-session',
        body: {'action': 'config'},
      );
      if (response.data is! Map) {
        throw StateError('invalid-stripe-config');
      }
      final result = Map<String, dynamic>.from(response.data as Map);
      if (result['error'] != null) {
        throw StateError(result['error'].toString());
      }
      final rawPacks = result['packs'];
      final offers = <_StripeOffer>[];
      if (rawPacks is List) {
        for (final raw in rawPacks.whereType<Map>()) {
          final row = Map<String, dynamic>.from(raw);
          final id = row['id']?.toString() ?? '';
          final label = row['label']?.toString() ?? '';
          final coins = (row['coins'] as num?)?.toInt() ?? 0;
          final priceCents = (row['price_cents'] as num?)?.toInt() ?? 0;
          final currency = row['currency']?.toString() ?? 'USD';
          if (id.isEmpty || coins <= 0 || priceCents <= 0) continue;
          offers.add(
            _StripeOffer(
              id: id,
              label: label.isEmpty ? '$coins Fame Coins' : label,
              coins: coins,
              priceCents: priceCents,
              currency: currency,
            ),
          );
        }
      }

      if (!mounted) return;
      setState(() {
        _stripeOffers = offers;
        _stripeCheckoutEnabled = result['checkout_enabled'] == true;
        _stripeEnvironment = result['environment']?.toString() == 'live'
            ? 'live'
            : 'test';
        _stripeLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _stripeOffers = const [];
        _stripeCheckoutEnabled = false;
        _stripeLoading = false;
      });
    }
  }

  Future<void> _buy(ProductDetails product) async {
    if (_busyProductId != null || _verifying || _stripeBusyPackId != null) {
      return;
    }
    if (!Platform.isIOS) {
      setState(() {
        _notice =
            'This beta build currently supports Apple purchases on iPhone.';
      });
      return;
    }

    setState(() {
      _busyProductId = product.id;
      _notice = null;
    });

    try {
      final started = await _store.buyConsumable(
        purchaseParam: PurchaseParam(
          productDetails: product,
          applicationUserName: widget.userId,
        ),
        autoConsume: true,
      );
      if (!started && mounted) {
        setState(() {
          _busyProductId = null;
          _notice = 'The App Store did not start that purchase.';
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _busyProductId = null;
        _notice = 'The App Store could not start that purchase.';
      });
    }
  }

  Future<void> _buyWithStripe(_StripeOffer offer) async {
    if (_stripeBusyPackId != null || _busyProductId != null || _verifying) {
      return;
    }
    if (!_stripeCheckoutEnabled) {
      setState(() {
        _notice =
            'Stripe Checkout is wired but not enabled for this environment yet.';
      });
      return;
    }

    setState(() {
      _stripeBusyPackId = offer.id;
      _notice = null;
    });

    try {
      final response = await _client.functions.invoke(
        'stripe-checkout-session',
        body: {'action': 'create', 'pack_id': offer.id},
      );
      if (response.data is! Map) {
        throw StateError('invalid-stripe-checkout-response');
      }
      final result = Map<String, dynamic>.from(response.data as Map);
      if (result['error'] != null) {
        throw StateError(result['error'].toString());
      }
      final checkoutUrl = result['checkout_url']?.toString() ?? '';
      final uri = Uri.tryParse(checkoutUrl);
      if (uri == null || uri.scheme != 'https') {
        throw StateError('invalid-stripe-checkout-url');
      }

      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) throw StateError('stripe-checkout-launch-failed');

      if (!mounted) return;
      setState(() {
        _awaitingStripeReturn = true;
        _notice =
            'Stripe Checkout opened in your browser. Fame Coins are credited only after Stripe confirms payment with Fameverse.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _stripeBusyPackId = null;
        _awaitingStripeReturn = false;
        _notice =
            'Stripe Checkout could not start. No Fame Coins were charged.';
      });
    }
  }

  Future<void> _refreshWalletAfterStripe() async {
    final previousBalance = _balance;
    try {
      final wallet = await _client
          .from('beta_coin_wallets')
          .select('balance')
          .eq('user_id', widget.userId)
          .maybeSingle();
      final balance = (wallet?['balance'] as num?)?.toInt() ?? previousBalance;
      if (!mounted) return;
      if (balance != previousBalance) widget.onBalanceChanged?.call(balance);
      setState(() {
        _balance = balance;
        _stripeBusyPackId = null;
        _notice = balance > previousBalance
            ? '${balance - previousBalance} Fame Coins added through Stripe. Balance: $balance.'
            : 'Stripe payment confirmation is still processing. Pull down to refresh your Fame Coin balance.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _stripeBusyPackId = null;
        _notice =
            'Fameverse could not refresh your balance yet. Pull down to retry; Stripe Checkout never credits coins from the browser alone.';
      });
    }
  }

  Future<void> _handlePurchases(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      if (!_coinByProduct.containsKey(purchase.productID)) continue;

      switch (purchase.status) {
        case PurchaseStatus.pending:
          if (mounted) {
            setState(() {
              _busyProductId = purchase.productID;
              _notice = 'Waiting for the App Store to finish the purchase…';
            });
          }
          break;
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          await _verifyAndCredit(purchase);
          break;
        case PurchaseStatus.error:
          if (mounted) {
            setState(() {
              _busyProductId = null;
              _verifying = false;
              _notice = purchase.error?.message.isNotEmpty == true
                  ? purchase.error!.message
                  : 'The purchase did not complete.';
            });
          }
          break;
        case PurchaseStatus.canceled:
          if (mounted) {
            setState(() {
              _busyProductId = null;
              _verifying = false;
              _notice = 'Purchase canceled. No Fame Coins were charged.';
            });
          }
          break;
      }
    }
  }

  Future<void> _verifyAndCredit(PurchaseDetails purchase) async {
    if (_verifying) return;
    if (!Platform.isIOS) return;

    final signedTransaction = purchase.verificationData.serverVerificationData
        .trim();
    if (signedTransaction.isEmpty) {
      if (mounted) {
        setState(() {
          _busyProductId = null;
          _notice = 'Apple did not provide purchase verification data.';
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        _verifying = true;
        _busyProductId = purchase.productID;
        _notice = 'Verifying purchase with Apple…';
      });
    }

    try {
      final response = await _client.functions.invoke(
        'iap-purchase',
        body: {'platform': 'ios', 'signed_transaction': signedTransaction},
      );
      if (response.data is! Map) {
        throw StateError('invalid-iap-response');
      }
      final result = Map<String, dynamic>.from(response.data as Map);
      if (result['error'] != null || result['status'] != 'completed') {
        throw StateError(result['error']?.toString() ?? 'iap-not-completed');
      }

      final balance = (result['wallet_balance'] as num?)?.toInt() ?? _balance;
      final credited =
          (result['credited_coins'] as num?)?.toInt() ??
          (_coinByProduct[purchase.productID] ?? 0);

      // Only finish the StoreKit transaction after Fameverse's server has
      // verified Apple's signature and committed the wallet credit.
      if (purchase.pendingCompletePurchase) {
        await _store
            .completePurchase(purchase)
            .timeout(const Duration(seconds: 8), onTimeout: () {});
      }

      if (!mounted) return;
      widget.onBalanceChanged?.call(balance);
      setState(() {
        _balance = balance;
        _busyProductId = null;
        _verifying = false;
        _notice = result['already_completed'] == true
            ? 'This Apple purchase was already credited. Balance: $balance Fame Coins.'
            : '$credited Fame Coins added. Balance: $balance.';
      });
    } catch (_) {
      if (!mounted) return;
      // Do not complete the StoreKit transaction here. Apple will redeliver an
      // unfinished purchase so Fameverse can verify it again instead of losing
      // a customer's paid coins.
      setState(() {
        _busyProductId = null;
        _verifying = false;
        _notice =
            'Your purchase was not credited yet. Fameverse will retry verification before finishing the Apple transaction.';
      });
    }
  }

  int _coins(ProductDetails product) => _coinByProduct[product.id] ?? 0;

  @override
  Widget build(BuildContext context) {
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
                'Fameverse Coin Packs',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 5),
              const Text(
                'Fameverse coins are purchased using Apple in-app purchases. Apple processes the App Store transaction and shows your local price and applicable taxes.',
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
                    final anotherPurchaseBusy = _busyProductId != null || _verifying || _stripeBusyPackId != null;
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
                            onPressed: anotherPurchaseBusy ? null : () => _buy(product),
                            style: FilledButton.styleFrom(
                              minimumSize: const Size.fromHeight(42),
                              backgroundColor: const Color(0xFF8E46DE),
                            ),
                            child: Text(
                              busy ? 'Processing…' : anotherPurchaseBusy ? 'Wait…' : product.price,
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

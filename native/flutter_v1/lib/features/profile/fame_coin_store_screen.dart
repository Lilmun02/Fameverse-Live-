import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
part 'fame_coin_purchase_flow.part.dart';
part 'fame_coin_store_view.part.dart';
part 'fame_coin_store_widgets.part.dart';


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
      _FameCoinPurchaseFlow(this).handlePurchases,
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

  int _coins(ProductDetails product) => _coinByProduct[product.id] ?? 0;

  @override
  Widget build(BuildContext context) {
    return _FameCoinStoreView(this).buildView(context);
  }
}

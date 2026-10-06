part of 'fame_coin_store_screen.dart';

extension _FameCoinPurchaseFlow on _FameCoinStoreScreenState {
Future<void> handlePurchases(List<PurchaseDetails> purchases) async {
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
          await verifyAndCredit(purchase);
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

  Future<void> verifyAndCredit(PurchaseDetails purchase) async {
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
}

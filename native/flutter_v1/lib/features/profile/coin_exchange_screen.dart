import 'package:flutter/material.dart';

import '../../data/fameverse_creator_backend.dart';
import '../../data/fameverse_economy_backend.dart';
part 'coin_exchange_widgets.part.dart';


class CoinExchangeScreen extends StatefulWidget {
  const CoinExchangeScreen({
    required this.creatorBackend,
    required this.economyBackend,
    super.key,
  });

  final SupabaseFameverseCreatorBackend creatorBackend;
  final SupabaseFameverseEconomyBackend economyBackend;

  @override
  State<CoinExchangeScreen> createState() => _CoinExchangeScreenState();
}

class _CoinExchangeScreenState extends State<CoinExchangeScreen> {
  bool _loading = true;
  bool _busy = false;
  String? _error;
  FvCreatorPayoutSummary _summary = FvCreatorPayoutSummary.empty;
  int _coinBalance = 0;
  List<FvCoinExchangeItem> _history = const [];

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final results = await Future.wait<dynamic>([
        widget.creatorBackend.loadPayoutSummary(),
        widget.economyBackend.loadFameCoinBalance(),
        widget.economyBackend.loadExchangeHistory(),
      ]);
      if (!mounted) return;
      setState(() {
        _summary = results[0] as FvCreatorPayoutSummary;
        _coinBalance = results[1] as int;
        _history = results[2] as List<FvCoinExchangeItem>;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Coin Exchange could not refresh right now.';
      });
    }
  }

  void _message(String value) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(value)));
  }

  Future<void> _chooseCustom() async {
    final controller = TextEditingController();
    final dollars = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exchange creator earnings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Available earnings: ${_money(_summary.withdrawableCents)}',
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('coin-exchange-custom-amount'),
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Amount',
                prefixText: r'$ ',
                helperText: r'$1.00 = 100 Fame Coins',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (dollars == null) return;
    final parsed = double.tryParse(dollars);
    final cents = parsed == null ? 0 : (parsed * 100).round();
    if (cents < 1) {
      _message(r'Enter at least $0.01.');
      return;
    }
    await _confirmExchange(cents);
  }

  Future<void> _confirmExchange(int amountCents) async {
    if (_busy) return;
    if (amountCents > _summary.withdrawableCents) {
      _message('That amount is higher than your available creator earnings.');
      return;
    }

    final approved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Coin Exchange'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ConfirmRow(
              label: 'Creator earnings',
              value: '-${_money(amountCents)}',
            ),
            const SizedBox(height: 8),
            _ConfirmRow(label: 'Fame Coins', value: '+$amountCents'),
            const Divider(height: 28),
            _ConfirmRow(
              label: 'Earnings after',
              value: _money(_summary.withdrawableCents - amountCents),
            ),
            const SizedBox(height: 14),
            const Text(
              'This exchange is one-way. Fame Coins cannot be converted back into Creator Earnings or cashed out.',
              style: TextStyle(color: Color(0xFFB8ACBF), height: 1.4),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const Key('confirm-coin-exchange'),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Exchange ${_money(amountCents)}'),
          ),
        ],
      ),
    );
    if (approved != true) return;

    setState(() => _busy = true);
    try {
      final result = await widget.economyBackend.exchangeCreatorEarnings(
        amountCents: amountCents,
      );
      if (!mounted) return;
      setState(() {
        _coinBalance = result.fameCoinBalance;
      });
      _message('${result.coinsCredited} Fame Coins added.');
      await _refresh();
    } catch (error) {
      final text = error.toString().toLowerCase();
      _message(
        text.contains('insufficient')
            ? 'Those earnings are no longer available to exchange.'
            : 'Coin Exchange could not complete. Your balances were not partially changed.',
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('creator-coin-exchange-screen'),
      backgroundColor: const Color(0xFF0C0810),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0C0810),
        title: const Text('Coin Exchange'),
        actions: [
          IconButton(
            onPressed: _loading || _busy ? null : _refresh,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 36),
            children: [
              const _ExchangeHero(),
              const SizedBox(height: 16),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 52),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_error != null)
                _ExchangeCard(
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Color(0xFFB9AEC1)),
                  ),
                )
              else ...[
                Row(
                  children: [
                    Expanded(
                      child: _Balance(
                        label: 'Available earnings',
                        value: _money(_summary.withdrawableCents),
                        icon: Icons.account_balance_wallet_outlined,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _Balance(
                        label: 'Fame Coins',
                        value: '$_coinBalance',
                        icon: Icons.toll_rounded,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                const Text(
                  'Choose an amount',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 5),
                const Text(
                  r'$1.00 of Available Creator Earnings becomes 100 Fame Coins. There is no second creator split.',
                  style: TextStyle(color: Color(0xFFAFA3B6), height: 1.4),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 9,
                  runSpacing: 9,
                  children: [100, 500, 1000, 2500]
                      .map(
                        (cents) => OutlinedButton(
                          key: Key('coin-exchange-$cents'),
                          onPressed: _busy || cents > _summary.withdrawableCents
                              ? null
                              : () => _confirmExchange(cents),
                          child: Text('${_money(cents)} → $cents coins'),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  key: const Key('coin-exchange-custom'),
                  onPressed: _busy || _summary.withdrawableCents <= 0
                      ? null
                      : _chooseCustom,
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Custom amount'),
                ),
                const SizedBox(height: 26),
                const Text(
                  'Exchange history',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 10),
                if (_history.isEmpty)
                  const _ExchangeCard(
                    child: Text(
                      'No Coin Exchanges yet.',
                      style: TextStyle(color: Color(0xFFAFA3B6)),
                    ),
                  )
                else
                  ..._history.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _HistoryTile(item: item),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

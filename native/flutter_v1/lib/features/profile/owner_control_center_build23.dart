import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class Build23OwnerControlCenterScreen extends StatefulWidget {
  const Build23OwnerControlCenterScreen({
    this.onOpenCreatorStudio,
    super.key,
  });

  final VoidCallback? onOpenCreatorStudio;

  @override
  State<Build23OwnerControlCenterScreen> createState() =>
      _Build23OwnerControlCenterScreenState();
}

class _Build23OwnerControlCenterScreenState
    extends State<Build23OwnerControlCenterScreen> {
  bool _loading = true;
  bool _busy = false;
  String? _error;
  Map<String, dynamic> _summary = const {};
  Map<String, dynamic> _wallet = const {};

  SupabaseClient get _client => Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  int _int(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  Map<String, dynamic> _firstRow(dynamic value) {
    if (value is List && value.isNotEmpty && value.first is Map) {
      return Map<String, dynamic>.from(value.first as Map);
    }
    if (value is Map) return Map<String, dynamic>.from(value);
    return const {};
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
        _client.rpc('get_owner_finance_control_summary'),
        _client.rpc('get_my_coin_funding_breakdown'),
      ]);
      if (!mounted) return;
      setState(() {
        _summary = _firstRow(results[0]);
        _wallet = _firstRow(results[1]);
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Owner finance controls could not refresh right now.';
      });
    }
  }

  void _message(String value) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(value)));
  }

  Future<void> _openPayPal() async {
    final uri = Uri.parse('https://www.paypal.com/myaccount/money/');
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched) _message('Could not open PayPal.');
  }

  Future<int?> _askDollars({
    required String title,
    required String body,
    required String action,
  }) async {
    final controller = TextEditingController();
    final text = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(body),
            const SizedBox(height: 14),
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Amount (USD)',
                prefixText: r'$ ',
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
            child: Text(action),
          ),
        ],
      ),
    );
    controller.dispose();
    if (text == null) return null;
    final dollars = double.tryParse(text);
    final cents = dollars == null ? 0 : (dollars * 100).round();
    if (cents <= 0) {
      _message('Enter an amount greater than $0.');
      return null;
    }
    return cents;
  }

  Future<void> _recordSettledReserve() async {
    if (_busy) return;
    final cents = await _askDollars(
      title: 'Record settled PayPal reserve',
      body:
          'Only record money after the real USD has settled in the PayPal Business balance or other business account you are using to fund creator rewards. This does not move money by itself.',
      action: 'Record reserve',
    );
    if (cents == null) return;
    setState(() => _busy = true);
    try {
      await _client.rpc(
        'owner_allocate_reward_reserve',
        params: {
          'p_amount_cents': cents,
          'p_note': 'Owner recorded settled PayPal reward reserve',
        },
      );
      _message('Reward reserve recorded.');
      await _refresh();
    } catch (_) {
      _message('Could not record that reserve.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _issueCashRewardCoins() async {
    if (_busy) return;
    final coinsController = TextEditingController();
    final text = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create cash-backed reward coins'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'These are real-liability coins. The backend will refuse to create them unless the recorded reward reserve is large enough.',
            ),
            const SizedBox(height: 14),
            TextField(
              controller: coinsController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Fame Coins',
                prefixIcon: Icon(Icons.toll_rounded),
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
            onPressed: () => Navigator.of(context).pop(coinsController.text),
            child: const Text('Create'),
          ),
        ],
      ),
    );
    coinsController.dispose();
    if (text == null) return;
    final coins = int.tryParse(text.trim()) ?? 0;
    if (coins <= 0) {
      _message('Enter a valid coin amount.');
      return;
    }
    setState(() => _busy = true);
    try {
      await _client.rpc(
        'owner_issue_cash_backed_reward_coins',
        params: {
          'p_coins': coins,
          'p_note': 'Owner created cash-backed promotional reward coins',
        },
      );
      _message('Cash-backed reward coins created.');
      await _refresh();
    } catch (error) {
      final text = error.toString().toLowerCase();
      _message(
        text.contains('insufficient funded cash reward reserve')
            ? 'Not enough recorded cash reserve for that reward.'
            : 'Could not create cash-backed reward coins.',
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('build23-owner-control-center'),
      backgroundColor: const Color(0xFF0C0810),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0C0810),
        title: const Text('Owner Control Center'),
        actions: [
          IconButton(
            onPressed: _loading ? null : _refresh,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 40),
            children: [
              const _Hero(),
              if (widget.onOpenCreatorStudio != null) ...[
                const SizedBox(height: 12),
                _Action(
                  key: const Key('owner-open-personal-creator-studio'),
                  icon: Icons.workspace_premium_rounded,
                  title: 'Creator earnings & payout',
                  body:
                      'Open your personal creator earnings, verification, PayPal payout method and payout history.',
                  label: 'Open',
                  onTap: widget.onOpenCreatorStudio,
                ),
              ],
              const SizedBox(height: 20),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 52),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_error != null)
                _Notice(
                  icon: Icons.cloud_off_rounded,
                  title: 'Finance controls unavailable',
                  body: _error!,
                )
              else ...[
                const _Section('BUSINESS MONEY'),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _Metric(
                        label: 'Platform share earned',
                        value: _money(
                          _int(_summary['platform_share_earned_cents']),
                        ),
                        icon: Icons.trending_up_rounded,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _Metric(
                        label: 'Cash-backed gifts',
                        value: _money(
                          _int(_summary['cash_backed_gifts_gross_cents']),
                        ),
                        icon: Icons.card_giftcard_rounded,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _Metric(
                        label: 'Creator share earned',
                        value: _money(
                          _int(_summary['creator_share_earned_cents']),
                        ),
                        icon: Icons.people_alt_rounded,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _Metric(
                        label: 'Payouts in review',
                        value: _money(
                          _int(_summary['creator_payouts_in_review_cents']),
                        ),
                        icon: Icons.fact_check_outlined,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const _Section('MONEY TO PROTECT'),
                const SizedBox(height: 10),
                _LiabilityCard(
                  reserveCents: _int(_summary['reward_reserve_cents']),
                  cashBackedOutstandingCents: _int(
                    _summary['cash_backed_value_outstanding_cents'],
                  ),
                  creatorUnpaidCents: _int(
                    _summary['creator_earnings_unpaid_cents'],
                  ),
                ),
                const SizedBox(height: 20),
                const _Section('YOUR OWNER WALLET'),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _Metric(
                        label: 'Testing / promo coins',
                        value: '${_int(_wallet['promo_coins'])}',
                        icon: Icons.science_outlined,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _Metric(
                        label: 'Cash-backed reward coins',
                        value: '${_int(_wallet['cash_backed_coins'])}',
                        icon: Icons.attach_money_rounded,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const _Section('PAYPAL FUNDING & WITHDRAWAL'),
                const SizedBox(height: 10),
                _Action(
                  key: const Key('owner-open-paypal-funding'),
                  icon: Icons.paypal_outlined,
                  title: 'Add money in PayPal',
                  body:
                      'Open your PayPal Business balance and fund it from your linked bank or eligible debit card.',
                  label: 'Open PayPal',
                  onTap: _openPayPal,
                ),
                const SizedBox(height: 10),
                _Action(
                  key: const Key('owner-record-settled-reserve'),
                  icon: Icons.account_balance_wallet_outlined,
                  title: 'Record settled reward reserve',
                  body:
                      'After real money has settled, mirror that amount in Fameverse so cash-backed promotional rewards cannot exceed funded cash.',
                  label: 'Record',
                  onTap: _busy ? null : _recordSettledReserve,
                ),
                const SizedBox(height: 10),
                _Action(
                  key: const Key('owner-issue-cash-reward-coins'),
                  icon: Icons.toll_rounded,
                  title: 'Create cash-backed reward coins',
                  body:
                      'Use only when you intentionally want gifts to create real creator earnings.',
                  label: 'Create',
                  onTap: _busy ? null : _issueCashRewardCoins,
                ),
                const SizedBox(height: 10),
                _Action(
                  key: const Key('owner-open-paypal-withdrawal'),
                  icon: Icons.account_balance_rounded,
                  title: 'Transfer owner earnings to bank',
                  body:
                      'Fameverse does not pretend to move PayPal funds. Open PayPal and transfer only settled business cash that is not needed for creator/user liabilities.',
                  label: 'Open PayPal',
                  onTap: _openPayPal,
                ),
                const SizedBox(height: 12),
                const _Notice(
                  icon: Icons.info_outline_rounded,
                  title: 'Provider balance is separate',
                  body:
                      'Platform share earned is an internal Fameverse ledger number, not your live PayPal balance. Provider fees, taxes, refunds, disputes and store settlement can reduce real cash available.',
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFB27A36)),
        gradient: const LinearGradient(
          colors: [Color(0xFF4A2B16), Color(0xFF25152C), Color(0xFF100B15)],
        ),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'OWNER MONEY CONTROL',
            style: TextStyle(
              color: Color(0xFFFFD38E),
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Revenue, reserve & payouts',
            style: TextStyle(fontSize: 25, fontWeight: FontWeight.w900),
          ),
          SizedBox(height: 7),
          Text(
            'Testing coins stay fake. Cash-backed rewards stay funded. Creator liabilities stay visible before you move owner money.',
            style: TextStyle(color: Color(0xFFC8BBCB), height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _LiabilityCard extends StatelessWidget {
  const _LiabilityCard({
    required this.reserveCents,
    required this.cashBackedOutstandingCents,
    required this.creatorUnpaidCents,
  });

  final int reserveCents;
  final int cashBackedOutstandingCents;
  final int creatorUnpaidCents;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF704F32)),
        color: const Color(0xFF1B1514),
      ),
      child: Column(
        children: [
          _Line(label: 'Promo reward reserve', value: _money(reserveCents)),
          const SizedBox(height: 10),
          _Line(
            label: 'Unspent cash-backed coin value',
            value: _money(cashBackedOutstandingCents),
          ),
          const SizedBox(height: 10),
          _Line(
            label: 'Unpaid creator earnings',
            value: _money(creatorUnpaidCents),
          ),
          const SizedBox(height: 12),
          const Text(
            'Do not treat these protected buckets as owner profit. Payout requests may overlap unpaid creator earnings, so they are displayed separately rather than double-counted here.',
            style: TextStyle(
              color: Color(0xFFB6A9AC),
              fontSize: 11,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: Color(0xFFB7AAB9)),
          ),
        ),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w900)),
      ],
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value, required this.icon});
  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF3E2E46)),
        color: const Color(0xFF151018),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: const Color(0xFFC98BFF)),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: const TextStyle(color: Color(0xFFA195A5), fontSize: 10),
          ),
        ],
      ),
    );
  }
}

class _Action extends StatelessWidget {
  const _Action({
    required super.key,
    required this.icon,
    required this.title,
    required this.body,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String body;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF3B2B43)),
        color: const Color(0xFF151018),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFC88BFF)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: const TextStyle(
                    color: Color(0xFFA99DAD),
                    fontSize: 11,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          FilledButton.tonal(onPressed: onTap, child: Text(label)),
        ],
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.icon, required this.title, required this.body});
  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF3A2B42)),
        color: const Color(0xFF151018),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFFC58AFA)),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: const TextStyle(
                    color: Color(0xFFA99DAD),
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section(this.value);
  final String value;

  @override
  Widget build(BuildContext context) {
    return Text(
      value,
      style: const TextStyle(
        color: Color(0xFF8D7F94),
        fontSize: 10,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.45,
      ),
    );
  }
}

String _money(int cents) => '\$${(cents / 100).toStringAsFixed(2)}';

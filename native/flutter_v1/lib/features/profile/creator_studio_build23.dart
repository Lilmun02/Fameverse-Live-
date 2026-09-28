import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/fameverse_backend.dart';
import '../../data/fameverse_creator_backend.dart';
import 'native_recharge_screen.dart';

class Build23CreatorStudioScreen extends StatefulWidget {
  const Build23CreatorStudioScreen({
    required this.backend,
    required this.identity,
    required this.profile,
    required this.isOwner,
    super.key,
  });

  final SupabaseFameverseCreatorBackend backend;
  final FvIdentity identity;
  final FvProfile profile;
  final bool isOwner;

  @override
  State<Build23CreatorStudioScreen> createState() =>
      _Build23CreatorStudioScreenState();
}

class _Build23CreatorStudioScreenState
    extends State<Build23CreatorStudioScreen> {
  bool _loading = true;
  bool _busy = false;
  String? _error;
  FvCreatorPayoutSummary _summary = FvCreatorPayoutSummary.empty;
  FvCreatorPayoutMethod? _payoutMethod;
  List<FvCreatorPayoutRequest> _requests = const [];
  int _promoGrossCoins = 0;
  int _promoCreatorEquivalentCents = 0;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  List<Map<String, dynamic>> _rows(dynamic response) {
    if (response is! List) return const [];
    return response
        .whereType<Map>()
        .map((row) => Map<String, dynamic>.from(row))
        .toList();
  }

  int _intValue(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
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
        widget.backend.loadPayoutSummary(),
        widget.backend.listPayoutRequests(),
        widget.backend.loadPayoutMethod(),
        Supabase.instance.client.rpc(
          'get_creator_promotional_earnings_summary',
        ),
      ]);
      final promoRows = _rows(results[3]);
      if (!mounted) return;
      setState(() {
        _summary = results[0] as FvCreatorPayoutSummary;
        _requests = results[1] as List<FvCreatorPayoutRequest>;
        _payoutMethod = results[2] as FvCreatorPayoutMethod?;
        if (promoRows.isNotEmpty) {
          _promoGrossCoins = _intValue(promoRows.first['promo_gross_coins']);
          _promoCreatorEquivalentCents = _intValue(
            promoRows.first['creator_promo_equivalent_cents'],
          );
        }
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Creator Studio could not refresh right now.';
      });
    }
  }

  void _message(String value) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(value)));
  }

  void _openOwnerRecharge() {
    if (!widget.isOwner) return;
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => const NativeRechargeScreen(),
      ),
    );
  }

  Future<void> _requestVerification() async {
    if (_busy || _summary.isVerified) return;
    setState(() => _busy = true);
    try {
      final status = await widget.backend.requestVerification();
      _message(
        status == 'pending'
            ? 'Verification request submitted.'
            : 'Verification status updated.',
      );
      await _refresh();
    } catch (_) {
      _message('Could not submit verification right now.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _editPayoutMethod() async {
    if (_busy) return;
    final controller = TextEditingController(
      text: _payoutMethod?.recipientEmail ?? '',
    );
    final email = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('PayPal payout email'),
        content: TextField(
          key: const Key('build23-paypal-payout-email'),
          controller: controller,
          keyboardType: TextInputType.emailAddress,
          autocorrect: false,
          textCapitalization: TextCapitalization.none,
          decoration: const InputDecoration(
            labelText: 'PayPal email',
            prefixIcon: Icon(Icons.paypal_outlined),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (email == null) return;
    final at = email.indexOf('@');
    if (at <= 0 || !email.substring(at + 1).contains('.')) {
      _message('Enter a valid PayPal email address.');
      return;
    }
    setState(() => _busy = true);
    try {
      await widget.backend.setPayoutMethod(recipientEmail: email);
      _message('PayPal payout method saved.');
      await _refresh();
    } catch (_) {
      _message('Could not save that payout method.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _requestPayout() async {
    if (!_summary.canRequestPayout || _busy) return;
    final controller = TextEditingController(
      text: (_summary.withdrawableCents / 100).toStringAsFixed(2),
    );
    final text = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Request payout'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Available: ${_money(_summary.withdrawableCents)}',
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            TextField(
              key: const Key('build23-payout-amount'),
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
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('Submit'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (text == null) return;
    final dollars = double.tryParse(text.trim());
    final cents = dollars == null ? 0 : (dollars * 100).round();
    if (cents < _summary.minimumPayoutCents) {
      _message('Minimum payout is ${_money(_summary.minimumPayoutCents)}.');
      return;
    }
    if (cents > _summary.withdrawableCents) {
      _message('That amount is higher than your available balance.');
      return;
    }
    setState(() => _busy = true);
    try {
      await widget.backend.requestPayout(cents);
      _message('Payout request submitted for review.');
      await _refresh();
    } catch (error) {
      final value = error.toString().toLowerCase();
      _message(
        value.contains('verification')
            ? 'Complete creator verification first.'
            : value.contains('payout method')
            ? 'Add a payout method first.'
            : 'Could not submit payout request.',
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('build23-creator-studio'),
      backgroundColor: const Color(0xFF0C0810),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0C0810),
        title: Text(widget.isOwner ? 'Owner Creator Studio' : 'Creator Studio'),
        actions: [
          IconButton(
            onPressed: _loading ? null : _refresh,
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 42),
            children: [
              _Hero(isOwner: widget.isOwner),
              if (widget.isOwner) ...[
                const SizedBox(height: 12),
                const _OwnerPremiumCard(),
              ],
              const SizedBox(height: 22),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 48),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_error != null)
                _InfoCard(
                  icon: Icons.cloud_off_rounded,
                  title: 'Creator Studio unavailable',
                  body: _error!,
                )
              else ...[
                const _SectionLabel('REAL CREATOR EARNINGS'),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _BalanceCard(
                        label: 'Withdrawable',
                        value: _money(_summary.withdrawableCents),
                        icon: Icons.account_balance_wallet_rounded,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _BalanceCard(
                        label: 'Pending',
                        value: _money(_summary.pendingCents),
                        icon: Icons.schedule_rounded,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _BalanceCard(
                        label: 'In review',
                        value: _money(_summary.reservedCents),
                        icon: Icons.fact_check_outlined,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _BalanceCard(
                        label: 'Paid out',
                        value: _money(_summary.paidCents),
                        icon: Icons.check_circle_outline_rounded,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                const _SectionLabel('PROMOTIONAL / QA'),
                const SizedBox(height: 10),
                _PromoCard(
                  grossCoins: _promoGrossCoins,
                  creatorEquivalentCents: _promoCreatorEquivalentCents,
                ),
                if (widget.isOwner) ...[
                  const SizedBox(height: 12),
                  _OwnerRechargeCard(onTap: _openOwnerRecharge),
                ],
                const SizedBox(height: 26),
                const _SectionLabel('PAYOUT SETUP'),
                const SizedBox(height: 10),
                _VerificationCard(
                  summary: _summary,
                  busy: _busy,
                  onRequest: _requestVerification,
                ),
                const SizedBox(height: 10),
                _PayoutMethodCard(
                  method: _payoutMethod,
                  busy: _busy,
                  onEdit: _editPayoutMethod,
                ),
                const SizedBox(height: 10),
                _PayoutCard(
                  summary: _summary,
                  hasMethod: _payoutMethod?.enabled == true,
                  busy: _busy,
                  onRequest: _requestPayout,
                ),
                const SizedBox(height: 26),
                const _SectionLabel('PAYOUT HISTORY'),
                const SizedBox(height: 10),
                if (_requests.isEmpty)
                  const _InfoCard(
                    icon: Icons.receipt_long_outlined,
                    title: 'No payout requests yet',
                    body: 'Approved creator payout requests will appear here.',
                  )
                else
                  ..._requests.map((request) => _PayoutTile(request: request)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.isOwner});
  final bool isOwner;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isOwner ? const Color(0xFFAA7436) : const Color(0xFF5A3973),
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isOwner
              ? const [Color(0xFF472B17), Color(0xFF24132A), Color(0xFF110B17)]
              : const [Color(0xFF482164), Color(0xFF21112D), Color(0xFF110B17)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isOwner ? 'FAMEVERSE OWNER PREMIUM' : 'FAMEVERSE CREATOR',
            style: TextStyle(
              color: isOwner
                  ? const Color(0xFFFFD69A)
                  : const Color(0xFFD6B7FF),
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 9),
          const Text(
            'Build. Earn. Grow.',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          const Text(
            'Real payout money and promotional QA value are shown separately so test gifts can never be mistaken for withdrawable cash.',
            style: TextStyle(color: Color(0xFFC4B8CC), height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _OwnerPremiumCard extends StatelessWidget {
  const _OwnerPremiumCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('owner-premium-unlocked-card'),
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF9C6B36)),
        color: const Color(0xFF201518),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.workspace_premium_rounded, color: Color(0xFFFFD17A)),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Premium owner access',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                SizedBox(height: 4),
                Text(
                  'Owner-facing previews stay readable. Build 23 removes the blurred/locked Creator Studio preview from the owner experience.',
                  style: TextStyle(
                    color: Color(0xFFC2B4C5),
                    fontSize: 12,
                    height: 1.35,
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

class _PromoCard extends StatelessWidget {
  const _PromoCard({
    required this.grossCoins,
    required this.creatorEquivalentCents,
  });

  final int grossCoins;
  final int creatorEquivalentCents;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('promotional-non-withdrawable-earnings'),
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF5E4770)),
        color: const Color(0xFF17121B),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.science_outlined, color: Color(0xFFC68AFF)),
              SizedBox(width: 9),
              Expanded(
                child: Text(
                  'Promotional (non-withdrawable)',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _Metric(
                  label: 'Promo gifts received',
                  value: '$grossCoins coins',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _Metric(
                  label: 'Creator test value',
                  value: _money(creatorEquivalentCents),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'This balance proves promo/test gifting is being recorded. It is not cash-backed, cannot be withdrawn, and is never added to real Creator Earnings.',
            style: TextStyle(
              color: Color(0xFFA99DAE),
              fontSize: 11,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        color: const Color(0xFF211829),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: const TextStyle(color: Color(0xFF9E91A3), fontSize: 10),
          ),
        ],
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF3C2B45)),
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
            style: const TextStyle(color: Color(0xFFA195A5), fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _VerificationCard extends StatelessWidget {
  const _VerificationCard({
    required this.summary,
    required this.busy,
    required this.onRequest,
  });

  final FvCreatorPayoutSummary summary;
  final bool busy;
  final VoidCallback onRequest;

  @override
  Widget build(BuildContext context) {
    final status = summary.verificationStatus;
    final verified = summary.isVerified;
    return _ActionCard(
      icon: verified ? Icons.verified_rounded : Icons.verified_outlined,
      title: 'Creator verification',
      subtitle: verified
          ? 'Verified for creator payout eligibility.'
          : 'Status: ${status.replaceAll('_', ' ')}',
      trailing: verified
          ? const Icon(Icons.check_circle_rounded, color: Color(0xFF72D49B))
          : FilledButton(
              onPressed: busy || status == 'pending' ? null : onRequest,
              child: Text(status == 'pending' ? 'Pending' : 'Request'),
            ),
    );
  }
}

class _PayoutMethodCard extends StatelessWidget {
  const _PayoutMethodCard({
    required this.method,
    required this.busy,
    required this.onEdit,
  });

  final FvCreatorPayoutMethod? method;
  final bool busy;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final email = method?.recipientEmail.trim() ?? '';
    return _ActionCard(
      icon: Icons.paypal_outlined,
      title: 'PayPal payout method',
      subtitle: email.isEmpty ? 'No payout email saved' : email,
      trailing: TextButton(
        onPressed: busy ? null : onEdit,
        child: Text(email.isEmpty ? 'Add' : 'Edit'),
      ),
    );
  }
}

class _PayoutCard extends StatelessWidget {
  const _PayoutCard({
    required this.summary,
    required this.hasMethod,
    required this.busy,
    required this.onRequest,
  });

  final FvCreatorPayoutSummary summary;
  final bool hasMethod;
  final bool busy;
  final VoidCallback onRequest;

  @override
  Widget build(BuildContext context) {
    final canRequest = summary.canRequestPayout && hasMethod && !busy;
    return _ActionCard(
      icon: Icons.payments_outlined,
      title: 'Request payout',
      subtitle:
          'Minimum ${_money(summary.minimumPayoutCents)} · available ${_money(summary.withdrawableCents)}',
      trailing: FilledButton(
        key: const Key('build23-request-payout'),
        onPressed: canRequest ? onRequest : null,
        child: const Text('Request'),
      ),
    );
  }
}

class _OwnerRechargeCard extends StatelessWidget {
  const _OwnerRechargeCard({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _ActionCard(
      icon: Icons.account_balance_wallet_rounded,
      title: 'PayPal sandbox recharge',
      subtitle: 'Owner QA coin purchase flow',
      trailing: IconButton(
        key: const Key('build23-owner-recharge'),
        onPressed: onTap,
        icon: const Icon(Icons.chevron_right_rounded),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF3A2B42)),
        color: const Color(0xFF151018),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFC78BFA)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFFA99DAD),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          trailing,
        ],
      ),
    );
  }
}

class _PayoutTile extends StatelessWidget {
  const _PayoutTile({required this.request});
  final FvCreatorPayoutRequest request;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFF34283A)),
          color: const Color(0xFF151018),
        ),
        child: Row(
          children: [
            const Icon(Icons.receipt_long_outlined, color: Color(0xFFC68AFF)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _money(request.amountCents),
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    request.status.replaceAll('_', ' '),
                    style: const TextStyle(
                      color: Color(0xFFA99DAD),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF3B2C43)),
        color: const Color(0xFF151018),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFFC78AFF)),
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
                    height: 1.35,
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

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFF8D7F94),
        fontSize: 10,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.5,
      ),
    );
  }
}

String _money(int cents) => '\$${(cents / 100).toStringAsFixed(2)}';

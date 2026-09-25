import 'package:flutter/material.dart';

import '../../data/fameverse_backend.dart';
import '../../data/fameverse_creator_backend.dart';
import 'native_recharge_screen.dart';

/// Creator-facing business surface.
///
/// External beta law: internal owner QA, moderation controls, and one-tap
/// verification shortcuts must never appear in the tester-facing UI.
class CreatorStudioScreen extends StatefulWidget {
  const CreatorStudioScreen({
    required this.backend,
    required this.identity,
    required this.profile,
    super.key,
  });

  final SupabaseFameverseCreatorBackend backend;
  final FvIdentity identity;
  final FvProfile profile;

  @override
  State<CreatorStudioScreen> createState() => _CreatorStudioScreenState();
}

class _CreatorStudioScreenState extends State<CreatorStudioScreen> {
  bool _loading = true;
  bool _busy = false;
  String? _error;
  String? _accountRole;
  FvCreatorPayoutSummary _summary = FvCreatorPayoutSummary.empty;
  List<FvCreatorPayoutRequest> _requests = const [];

  bool get _isOwner => _accountRole == 'owner';

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
        widget.backend.loadPayoutSummary(),
        widget.backend.listPayoutRequests(),
        widget.backend.loadRole(widget.identity.id),
      ]);
      if (!mounted) return;
      setState(() {
        _summary = results[0] as FvCreatorPayoutSummary;
        _requests = results[1] as List<FvCreatorPayoutRequest>;
        _accountRole = results[2] as String?;
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
    if (!_isOwner) return;
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => const NativeRechargeScreen(),
      ),
    );
  }

  Future<void> _openPayoutRequest() async {
    if (!_summary.canRequestPayout || _busy) return;
    final controller = TextEditingController(
      text: (_summary.withdrawableCents / 100).toStringAsFixed(2),
    );
    final dollars = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Request payout'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Available: ${_money(_summary.withdrawableCents)}',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            const Text(
              r'Minimum payout is $25.00. Requests remain pending until Fameverse review is complete.',
              style: TextStyle(color: Color(0xFFB5A9BE), height: 1.35),
            ),
            const SizedBox(height: 16),
            TextField(
              key: const Key('creator-payout-amount'),
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
    if (dollars == null) return;

    final parsed = double.tryParse(dollars.trim());
    final amountCents = parsed == null ? 0 : (parsed * 100).round();
    if (amountCents < _summary.minimumPayoutCents) {
      _message('Minimum payout is ${_money(_summary.minimumPayoutCents)}.');
      return;
    }
    if (amountCents > _summary.withdrawableCents) {
      _message('That amount is higher than your cleared available balance.');
      return;
    }

    setState(() => _busy = true);
    try {
      await widget.backend.requestPayout(amountCents);
      _message('Payout request submitted for review.');
      await _refresh();
    } catch (error) {
      final text = error.toString().toLowerCase();
      _message(
        text.contains('verification') || text.contains('eligibility')
            ? 'Complete payout setup before requesting a payout.'
            : text.contains('minimum')
            ? r'Minimum payout is $25.00.'
            : text.contains('payout method')
            ? 'Add a payout method before requesting a payout.'
            : 'Could not submit payout request.',
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('creator-studio-screen'),
      backgroundColor: const Color(0xFF0C0810),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0C0810),
        title: const Text('Creator Studio'),
        actions: [
          IconButton(
            onPressed: _loading ? null : _refresh,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 42),
            children: [
              const _StudioHero(),
              const SizedBox(height: 22),
              if (_loading)
                const _StudioLoading()
              else if (_error != null)
                _StudioInfoCard(
                  icon: Icons.cloud_off_rounded,
                  title: 'Creator Studio unavailable',
                  body: _error!,
                )
              else ...[
                if (_isOwner) ...[
                  const _SectionLabel('OWNER QA'),
                  const SizedBox(height: 10),
                  _OwnerRechargeCard(onTap: _openOwnerRecharge),
                  const SizedBox(height: 26),
                ],
                const _SectionLabel('EARNINGS'),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _BalanceCard(
                        label: 'Available',
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
                const SizedBox(height: 26),
                const _SectionLabel('PAYOUT SETUP'),
                const SizedBox(height: 10),
                _PayoutEligibilityCard(status: _summary.verificationStatus),
                const SizedBox(height: 12),
                _PayoutCard(
                  summary: _summary,
                  busy: _busy,
                  onRequest: _openPayoutRequest,
                ),
                const SizedBox(height: 28),
                const _SectionLabel('PAYOUT HISTORY'),
                const SizedBox(height: 10),
                if (_requests.isEmpty)
                  const _StudioInfoCard(
                    icon: Icons.receipt_long_outlined,
                    title: 'No payout requests yet',
                    body:
                        'Payout requests and their review status will appear here when payout setup is complete.',
                  )
                else
                  ..._requests.map((item) => _PayoutRequestTile(item: item)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StudioHero extends StatelessWidget {
  const _StudioHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF5A3973)),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF482164), Color(0xFF21112D), Color(0xFF110B17)],
        ),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'FAMEVERSE CREATOR',
            style: TextStyle(
              color: Color(0xFFD6B7FF),
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
          SizedBox(height: 9),
          Text(
            'Build. Earn. Grow.',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
          ),
          SizedBox(height: 6),
          Text(
            'Manage creator earnings and payout setup without mixing account verification or internal QA into your public profile.',
            style: TextStyle(color: Color(0xFFC4B8CC), height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _OwnerRechargeCard extends StatelessWidget {
  const _OwnerRechargeCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: const Key('owner-native-paypal-recharge'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.all(17),
          decoration: _panelDecoration(),
          child: const Row(
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: Color(0xFF342047),
                  borderRadius: BorderRadius.all(Radius.circular(14)),
                ),
                child: Padding(
                  padding: EdgeInsets.all(11),
                  child: Icon(
                    Icons.account_balance_wallet_rounded,
                    color: Color(0xFFC69BFF),
                    size: 22,
                  ),
                ),
              ),
              SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PayPal sandbox recharge',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Owner QA · native Fameverse checkout · no Vercel page',
                      style: TextStyle(color: Color(0xFF9F93A8), fontSize: 12),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: Color(0xFFBBAFC4)),
            ],
          ),
        ),
      ),
    );
  }
}

class _PayoutEligibilityCard extends StatelessWidget {
  const _PayoutEligibilityCard({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final normalized = status.trim().toLowerCase();
    final title = switch (normalized) {
      'verified' => 'Payout eligibility approved',
      'pending' => 'Payout setup under review',
      'needs_info' => 'Payout setup needs information',
      'rejected' => 'Payout setup not approved',
      'suspended' => 'Payout access suspended',
      _ => 'Payout setup not started',
    };
    final body = switch (normalized) {
      'verified' =>
        'Your creator payout eligibility is approved. This is separate from any public profile verification badge.',
      'pending' =>
        'Your payout eligibility is being reviewed. This review is separate from public account verification.',
      'needs_info' =>
        'Fameverse needs additional payout information. The external beta does not collect that information on this screen yet.',
      'rejected' =>
        'Payout eligibility was not approved. A future payout setup flow will show the required next steps.',
      'suspended' =>
        'Payout requests are currently disabled for this creator account.',
      _ =>
        'Payout onboarding is not open in this external beta yet. We will not ask you to press a vague verification button or submit incomplete information.',
    };
    final icon = normalized == 'verified'
        ? Icons.check_circle_rounded
        : normalized == 'pending'
        ? Icons.schedule_rounded
        : Icons.account_balance_outlined;

    return Container(
      key: const Key('payout-eligibility-card'),
      padding: const EdgeInsets.all(18),
      decoration: _panelDecoration(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFFB784FF)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  body,
                  style: const TextStyle(color: Color(0xFFB7ACBF), height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PayoutCard extends StatelessWidget {
  const _PayoutCard({
    required this.summary,
    required this.busy,
    required this.onRequest,
  });

  final FvCreatorPayoutSummary summary;
  final bool busy;
  final VoidCallback onRequest;

  @override
  Widget build(BuildContext context) {
    final disabledReason = !summary.isVerified
        ? 'Payout setup required'
        : summary.withdrawableCents < summary.minimumPayoutCents
        ? '${_money(summary.minimumPayoutCents)} minimum'
        : null;
    return Container(
      key: const Key('creator-payout-card'),
      padding: const EdgeInsets.all(18),
      decoration: _panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.payments_outlined),
              SizedBox(width: 10),
              Text(
                'Payouts',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            r'Minimum payout: $25.00',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          const Text(
            'Only cleared creator earnings can be requested. Every payout enters review before processing.',
            style: TextStyle(color: Color(0xFFB7ACBF), height: 1.4),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              key: const Key('request-creator-payout'),
              onPressed: busy || !summary.canRequestPayout ? null : onRequest,
              child: Text(disabledReason ?? 'Request payout'),
            ),
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
      decoration: _panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 19, color: const Color(0xFFB784FF)),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(color: Color(0xFFAFA4B8), fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _PayoutRequestTile extends StatelessWidget {
  const _PayoutRequestTile({required this.item});

  final FvCreatorPayoutRequest item;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.all(14),
      decoration: _panelDecoration(),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFF38224B),
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(Icons.payments_outlined, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _money(item.amountCents),
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 2),
                Text(
                  _dateLabel(item.requestedAt),
                  style: const TextStyle(
                    color: Color(0xFFAFA4B8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          _StatusPill(status: item.status),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF30203D),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        _label(status),
        style: const TextStyle(
          color: Color(0xFFD9C1F2),
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _StudioInfoCard extends StatelessWidget {
  const _StudioInfoCard({
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
      decoration: _panelDecoration(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFFB784FF)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 5),
                Text(
                  body,
                  style: const TextStyle(color: Color(0xFFAFA4B8), height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StudioLoading extends StatelessWidget {
  const _StudioLoading();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 52),
      child: Center(child: CircularProgressIndicator()),
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
        color: Color(0xFF96899F),
        fontSize: 10,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.25,
      ),
    );
  }
}

BoxDecoration _panelDecoration() {
  return BoxDecoration(
    color: const Color(0xFF17111D),
    borderRadius: BorderRadius.circular(18),
    border: Border.all(color: const Color(0xFF35283E)),
  );
}

String _money(int cents) => '\$${(cents / 100).toStringAsFixed(2)}';

String _dateLabel(DateTime? value) {
  if (value == null) return 'Pending date';
  final local = value.toLocal();
  final month = local.month.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');
  return '$month/$day/${local.year}';
}

String _label(String value) {
  return value
      .split('_')
      .where((part) => part.isNotEmpty)
      .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');
}

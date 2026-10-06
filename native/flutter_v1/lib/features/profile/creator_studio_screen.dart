import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../data/fameverse_backend.dart';
import '../../data/fameverse_creator_backend.dart';
import 'native_recharge_screen.dart';
part 'creator_studio_header.part.dart';
part 'creator_studio_badges.part.dart';
part 'creator_studio_payout.part.dart';
part 'creator_studio_history.part.dart';


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
  FvCreatorPayoutMethod? _payoutMethod;
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
        widget.backend.loadPayoutMethod(),
        widget.backend.loadRole(widget.identity.id),
      ]);
      if (!mounted) return;
      setState(() {
        _summary = results[0] as FvCreatorPayoutSummary;
        _requests = results[1] as List<FvCreatorPayoutRequest>;
        _payoutMethod = results[2] as FvCreatorPayoutMethod?;
        _accountRole = results[3] as String?;
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

  Future<void> _openPayoutMethod() async {
    if (_busy) return;
    final controller = TextEditingController(
      text: _payoutMethod?.recipientEmail ?? '',
    );
    final email = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('PayPal payout email'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter the email attached to the PayPal account where Fameverse should send approved creator payouts.',
              style: TextStyle(color: Color(0xFFB5A9BE), height: 1.35),
            ),
            const SizedBox(height: 16),
            TextField(
              key: const Key('creator-paypal-payout-email'),
              controller: controller,
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              textCapitalization: TextCapitalization.none,
              decoration: const InputDecoration(
                labelText: 'PayPal email',
                prefixIcon: Icon(Icons.paypal_outlined),
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
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (email == null) return;
    if (!email.contains('@') ||
        !email.substring(email.indexOf('@') + 1).contains('.')) {
      _message('Enter a valid PayPal email address.');
      return;
    }

    setState(() => _busy = true);
    try {
      final method = await widget.backend.setPayoutMethod(
        recipientEmail: email,
      );
      if (mounted) setState(() => _payoutMethod = method);
      _message('PayPal payout method saved.');
      await _refresh();
    } catch (_) {
      _message('Could not save that PayPal payout email.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
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
              const SizedBox(height: 16),
              const _ProLivePreviewCard(),
              const SizedBox(height: 12),
              const _BadgeTransferPreviewCard(),
              const SizedBox(height: 24),
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
                _PayoutMethodCard(
                  method: _payoutMethod,
                  busy: _busy,
                  onEdit: _openPayoutMethod,
                ),
                const SizedBox(height: 12),
                _PayoutCard(
                  summary: _summary,
                  hasPayoutMethod: _payoutMethod?.enabled == true,
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

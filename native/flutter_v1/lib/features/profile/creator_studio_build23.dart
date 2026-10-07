import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/fameverse_backend.dart';
import '../../data/fameverse_creator_backend.dart';

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
  FvCreatorVerificationProgress _verificationProgress =
      FvCreatorVerificationProgress.empty;
  FvCreatorPayoutMethod? _payoutMethod;
  List<FvCreatorPayoutRequest> _requests = const [];
  List<Map<String, dynamic>> _giftActivity = const [];
  int _gifterLevel = 1;
  int _gifterTotalCoinsSent = 0;
  int _gifterGiftCount = 0;
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

    FvCreatorPayoutSummary? summary;
    List<FvCreatorPayoutRequest>? requests;
    FvCreatorPayoutMethod? payoutMethod;
    FvCreatorVerificationProgress? verificationProgress;
    dynamic promoResult;
    dynamic giftActivityResult;
    Map<String, dynamic>? gifterStats;
    var payoutMethodLoaded = false;
    final failures = <String>[];

    try {
      summary = await widget.backend.loadPayoutSummary();
    } catch (_) {
      failures.add('earnings summary');
    }
    try {
      requests = await widget.backend.listPayoutRequests();
    } catch (_) {
      failures.add('payout history');
    }
    try {
      payoutMethod = await widget.backend.loadPayoutMethod();
      payoutMethodLoaded = true;
    } catch (_) {
      failures.add('payout method');
    }
    try {
      promoResult = await Supabase.instance.client.rpc(
        'get_creator_promotional_earnings_summary',
      );
    } catch (_) {
      failures.add('promotional earnings');
    }
    try {
      verificationProgress = await widget.backend.loadVerificationProgress();
    } catch (_) {
      failures.add('verification progress');
    }
    try {
      giftActivityResult = await Supabase.instance.client.rpc(
        'get_creator_gift_activity',
        params: {'p_limit': 8},
      );
    } catch (_) {
      // Gift activity is additive and must not block earnings or payouts.
    }
    try {
      final row = await Supabase.instance.client
          .from('gifter_stats')
          .select('total_coins_sent, gift_count, level')
          .eq('user_id', widget.identity.id)
          .maybeSingle();
      if (row != null) gifterStats = Map<String, dynamic>.from(row);
    } catch (_) {
      // Badge progress is additive and must not block Creator Studio.
    }

    final promoRows = _rows(promoResult);
    final giftRows = _rows(giftActivityResult);
    if (!mounted) return;
    setState(() {
      if (summary != null) _summary = summary;
      if (requests != null) _requests = requests;
      if (payoutMethodLoaded) _payoutMethod = payoutMethod;
      if (verificationProgress != null) {
        _verificationProgress = verificationProgress;
      }
      _giftActivity = giftRows;
      if (gifterStats != null) {
        _gifterLevel = _intValue(gifterStats!['level']).clamp(1, 99);
        _gifterTotalCoinsSent = _intValue(gifterStats!['total_coins_sent']);
        _gifterGiftCount = _intValue(gifterStats!['gift_count']);
      }
      if (promoRows.isNotEmpty) {
        _promoGrossCoins = _intValue(promoRows.first['promo_gross_coins']);
        _promoCreatorEquivalentCents = _intValue(
          promoRows.first['creator_promo_equivalent_cents'],
        );
      }
      _loading = false;
      if (failures.isEmpty) {
        _error = null;
      } else {
        _error =
            'Some Creator Studio data could not refresh: '
            '${failures.join(', ')}.';
      }
    });
  }

  void _message(String value) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(value)));
  }

  Future<void> _requestVerification() async {
    if (_busy || _summary.isVerified || !_verificationProgress.eligible) {
      if (!_summary.isVerified && !_verificationProgress.eligible) {
        _message('Complete both verification requirements first.');
      }
      return;
    }
    setState(() => _busy = true);
    try {
      final status = await widget.backend.requestVerification();
      _message(
        status == 'pending'
            ? 'Verification request submitted.'
            : 'Verification status updated.',
      );
      await _refresh();
    } catch (error) {
      final value = error.toString().toLowerCase();
      _message(
        value.contains('eligibility') || value.contains('500000')
            ? 'Complete both verification requirements first.'
            : 'Could not submit verification right now.',
      );
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
        title: const Text('Creator Studio'),
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
              else ...[
                if (_error != null) ...[
                  _InfoCard(
                    icon: Icons.sync_problem_rounded,
                    title: 'Some Creator Studio data needs a refresh',
                    body: _error!,
                  ),
                  const SizedBox(height: 18),
                ],
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
                const SizedBox(height: 26),
                const _SectionLabel('CREATOR TOOLS'),
                const SizedBox(height: 10),
                const _FamAlgorithmCard(),
                const SizedBox(height: 10),
                _BadgeProgressCard(
                  level: _gifterLevel,
                  totalCoinsSent: _gifterTotalCoinsSent,
                  giftCount: _gifterGiftCount,
                ),
                const SizedBox(height: 10),
                _GiftActivityCard(rows: _giftActivity),
                const SizedBox(height: 10),
                _VerificationCard(
                  summary: _summary,
                  progress: _verificationProgress,
                  busy: _busy,
                  onRequest: _requestVerification,
                ),
                const SizedBox(height: 26),
                const _SectionLabel('PROMOTIONAL / QA'),
                const SizedBox(height: 10),
                _PromoCard(
                  grossCoins: _promoGrossCoins,
                  creatorEquivalentCents: _promoCreatorEquivalentCents,
                ),
                const SizedBox(height: 26),
                const _SectionLabel('PAYOUT SETUP'),
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
                  'Your creator account',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                SizedBox(height: 4),
                Text(
                  'Creator tools stay here. Owner and admin operations are intentionally kept out of the native app and belong on the Fameverse web dashboard.',
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

class _FamAlgorithmCard extends StatelessWidget {
  const _FamAlgorithmCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('creator-fam-algorithm-card'),
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF513862)),
        color: const Color(0xFF17111B),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_graph_rounded, color: Color(0xFFC78BFA)),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'FAM Algorithm 1.2',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                ),
              ),
              Chip(label: Text('Ranking OFF')),
            ],
          ),
          SizedBox(height: 10),
          Text(
            'Verse Momentum keeps three discovery lanes visible: Audience, Taps and Gift Coins. Discovery ranking stays separate from creator payout calculations.',
            style: TextStyle(
              color: Color(0xFFB8ACBC),
              fontSize: 12,
              height: 1.4,
            ),
          ),
          SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Chip(label: Text('Audience')),
              Chip(label: Text('Taps')),
              Chip(label: Text('Gift Coins')),
            ],
          ),
        ],
      ),
    );
  }
}

class _BadgeProgressCard extends StatelessWidget {
  const _BadgeProgressCard({
    required this.level,
    required this.totalCoinsSent,
    required this.giftCount,
  });

  final int level;
  final int totalCoinsSent;
  final int giftCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('creator-badges-card'),
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF513862)),
        color: const Color(0xFF17111B),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.workspace_premium_outlined, color: Color(0xFFD3A0FF)),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Badges & levels',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _Metric(label: 'Gifter level', value: '$level')),
              const SizedBox(width: 10),
              Expanded(
                child: _Metric(
                  label: 'Gifts sent',
                  value: '$giftCount',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '$totalCoinsSent Fame Coins sent toward badge progression.',
            style: const TextStyle(
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

class _GiftActivityCard extends StatelessWidget {
  const _GiftActivityCard({required this.rows});

  final List<Map<String, dynamic>> rows;

  int _coins(Map<String, dynamic> row) {
    final value = row['coins_spent'];
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('creator-gift-activity-card'),
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF513862)),
        color: const Color(0xFF17111B),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.card_giftcard_rounded, color: Color(0xFFD3A0FF)),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Gift activity',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (rows.isEmpty)
            const Text(
              'No recent gifts received yet.',
              style: TextStyle(color: Color(0xFFA99DAE), fontSize: 12),
            )
          else
            ...rows.take(5).map((row) {
              final sender =
                  (row['sender_display_name']?.toString().trim().isNotEmpty ??
                          false)
                      ? row['sender_display_name'].toString().trim()
                      : 'Fameverse supporter';
              final giftId = row['gift_id']?.toString().trim() ?? 'gift';
              final quantity = row['quantity'] is num
                  ? (row['quantity'] as num).toInt()
                  : int.tryParse(row['quantity']?.toString() ?? '') ?? 1;
              return Padding(
                padding: const EdgeInsets.only(top: 9),
                child: Row(
                  children: [
                    const Icon(
                      Icons.favorite_rounded,
                      size: 16,
                      color: Color(0xFFC78BFA),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        '$sender sent $quantity × $giftId',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFFD8CEDC),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${_coins(row)} coins',
                      style: const TextStyle(
                        color: Color(0xFFB79AC7),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              );
            }),
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

String _creatorStatusTime(DateTime? value) {
  if (value == null) return '';
  final local = value.toLocal();
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '${local.month}/${local.day}/${local.year} $hour:$minute';
}

class _VerificationCard extends StatelessWidget {
  const _VerificationCard({
    required this.summary,
    required this.progress,
    required this.busy,
    required this.onRequest,
  });

  final FvCreatorPayoutSummary summary;
  final FvCreatorVerificationProgress progress;
  final bool busy;
  final VoidCallback onRequest;

  @override
  Widget build(BuildContext context) {
    final status = progress.verificationStatus.isEmpty
        ? summary.verificationStatus
        : progress.verificationStatus;
    final verified = status == 'verified';
    final pending = status == 'pending';
    final needsInfo = status == 'needs_info';
    final rejected = status == 'rejected';
    final canRequest = progress.eligible && !busy && !pending && !verified;
    final statusTime =
        progress.reviewedAt ?? progress.requestedAt ?? progress.updatedAt;
    final statusLabel = switch (status) {
      'verified' => 'Verified',
      'pending' => 'Under review',
      'needs_info' => 'Needs information',
      'rejected' => 'Not approved',
      'suspended' => 'Suspended',
      _ => 'Not submitted',
    };
    var statusMessage =
        'Complete both requirements below to unlock the verification request.';
    if (verified) {
      statusMessage = 'Your creator account is verified.';
    } else if (pending) {
      statusMessage =
          'Verification is processing in Fameverse review. '
          'You do not need to submit it again.';
    } else if (needsInfo) {
      statusMessage =
          'Fameverse needs more information before verification can be approved.';
    } else if (rejected) {
      statusMessage =
          'The last verification request was not approved. '
          'You can submit again after the requirements are met.';
    }
    final statusTimeText = statusTime == null
        ? ''
        : '${pending ? 'Submitted' : 'Updated'} '
              '${_creatorStatusTime(statusTime)}';

    return Container(
      key: const Key('creator-verification-center'),
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF513862)),
        color: const Color(0xFF17111B),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                verified ? Icons.verified_rounded : Icons.verified_outlined,
                color: verified
                    ? const Color(0xFF72D49B)
                    : const Color(0xFFC78BFA),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Creator verification',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                ),
              ),
              if (verified)
                const Icon(
                  Icons.check_circle_rounded,
                  color: Color(0xFF72D49B),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            statusMessage,
            style: const TextStyle(
              color: Color(0xFFB8ACBC),
              fontSize: 12,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          Chip(
            key: const Key('creator-verification-status'),
            label: Text(statusLabel),
          ),
          if (statusTime != null) ...[
            const SizedBox(height: 6),
            Text(
              statusTimeText,
              key: const Key('creator-verification-status-time'),
              style: const TextStyle(color: Color(0xFF96899C), fontSize: 10),
            ),
          ],
          if ((progress.publicNote ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              progress.publicNote!.trim(),
              key: const Key('creator-verification-review-note'),
              style: const TextStyle(
                color: Color(0xFFC7B8CD),
                fontSize: 11,
                height: 1.35,
              ),
            ),
          ],
          const SizedBox(height: 16),
          _VerificationProgressLine(
            key: const Key('creator-verification-followers-progress'),
            label: 'Followers',
            value: progress.followerCount,
            requirement: progress.followerRequirement,
          ),
          const SizedBox(height: 14),
          _VerificationProgressLine(
            key: const Key('creator-verification-coins-progress'),
            label: 'Eligible Fame Coins received',
            value: progress.eligibleReceivedCoins,
            requirement: progress.receivedCoinsRequirement,
          ),
          const SizedBox(height: 10),
          const Text(
            'Only legitimate cash-backed gifts count. Promotional, referral, owner-QA and self-gifts do not count toward verification.',
            style: TextStyle(
              color: Color(0xFF96899C),
              fontSize: 10,
              height: 1.4,
            ),
          ),
          if (!verified) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                key: const Key('creator-verification-request'),
                onPressed: canRequest ? onRequest : null,
                child: Text(
                  pending
                      ? 'Under review'
                      : needsInfo
                      ? 'Resubmit verification'
                      : 'Request verification',
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _VerificationProgressLine extends StatelessWidget {
  const _VerificationProgressLine({
    required this.label,
    required this.value,
    required this.requirement,
    super.key,
  });

  final String label;
  final int value;
  final int requirement;

  @override
  Widget build(BuildContext context) {
    final safeRequirement = requirement <= 0 ? 1 : requirement;
    final ratio = (value / safeRequirement).clamp(0.0, 1.0).toDouble();
    final complete = value >= safeRequirement;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ),
            Text(
              '$value / $requirement',
              style: TextStyle(
                color: complete
                    ? const Color(0xFF72D49B)
                    : const Color(0xFFC7B8CD),
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 8,
            backgroundColor: const Color(0xFF2A2030),
          ),
        ),
      ],
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
    final providerStatus = (request.providerStatus ?? '').trim().toUpperCase();
    final processing = request.status == 'processing';
    final missingProviderBatch =
        processing && (request.providerBatchId ?? '').trim().isEmpty;
    final statusText = request.status.replaceAll('_', ' ');
    var providerText = '';
    if (processing &&
        missingProviderBatch &&
        (providerStatus == 'SUBMISSION_UNKNOWN' ||
            providerStatus == 'SUBMITTING')) {
      providerText =
          'PayPal submission is being recovered. Funds remain reserved.';
    } else if (processing && providerStatus.isNotEmpty) {
      providerText = 'PayPal: ${providerStatus.replaceAll('_', ' ')}';
    } else if (processing) {
      providerText = 'PayPal processing is waiting for a provider update.';
    }
    final providerStatusTime = request.providerStatusUpdatedAt;
    final providerStatusTimeText = providerStatusTime == null
        ? ''
        : 'Provider update ${_creatorStatusTime(providerStatusTime)}';

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
                    statusText,
                    key: const Key('creator-payout-status'),
                    style: const TextStyle(
                      color: Color(0xFFA99DAD),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (providerText.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      providerText,
                      key: const Key('creator-payout-provider-status'),
                      style: const TextStyle(
                        color: Color(0xFFC7B8CD),
                        fontSize: 10,
                        height: 1.3,
                      ),
                    ),
                    if (request.providerStatusUpdatedAt != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        providerStatusTimeText,
                        key: const Key('creator-payout-provider-status-time'),
                        style: const TextStyle(
                          color: Color(0xFF96899C),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ],
                  if ((request.moderationNote ?? '').trim().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      request.moderationNote!.trim(),
                      style: const TextStyle(
                        color: Color(0xFF96899C),
                        fontSize: 10,
                        height: 1.3,
                      ),
                    ),
                  ],
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

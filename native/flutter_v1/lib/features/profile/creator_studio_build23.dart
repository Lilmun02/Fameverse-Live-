import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/fameverse_backend.dart';
import '../../data/fameverse_creator_backend.dart';
part 'creator_studio_build23_summary.part.dart';
part 'creator_studio_build23_verification.part.dart';
part 'creator_studio_build23_payout.part.dart';
part 'creator_studio_build23_payout_actions.part.dart';


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
  FvCreatorQaPayoutSummary _qaSummary = FvCreatorQaPayoutSummary.empty;
  FvCreatorVerificationProgress _verificationProgress =
      FvCreatorVerificationProgress.empty;
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

    FvCreatorPayoutSummary? summary;
    FvCreatorQaPayoutSummary? qaSummary;
    List<FvCreatorPayoutRequest>? requests;
    FvCreatorPayoutMethod? payoutMethod;
    FvCreatorVerificationProgress? verificationProgress;
    dynamic promoResult;
    var payoutMethodLoaded = false;
    final failures = <String>[];

    try {
      summary = await widget.backend.loadPayoutSummary();
    } catch (_) {
      failures.add('earnings summary');
    }
    try {
      qaSummary = await widget.backend.loadQaPayoutSummary();
    } catch (_) {
      failures.add('QA payout summary');
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

    final promoRows = _rows(promoResult);
    if (!mounted) return;
    setState(() {
      if (summary != null) _summary = summary;
      if (qaSummary != null) _qaSummary = qaSummary;
      if (requests != null) _requests = requests;
      if (payoutMethodLoaded) _payoutMethod = payoutMethod;
      if (verificationProgress != null) {
        _verificationProgress = verificationProgress;
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


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('build23-creator-studio'),
      backgroundColor: const Color(0xFF0C0810),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0C0810),
        title: Text(widget.isOwner ? 'My Creator Account' : 'Creator Studio'),
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
                const SizedBox(height: 10),
                _SandboxPayoutMethodCard(
                  method: _payoutMethod,
                  busy: _busy,
                  onEdit: _editSandboxPayoutMethod,
                ),
                const SizedBox(height: 10),
                _QaPayoutCard(
                  summary: _qaSummary,
                  hasMethod:
                      (_payoutMethod?.sandboxRecipientEmail.trim().isNotEmpty ??
                          false),
                  busy: _busy,
                  onRequest: _requestQaPayout,
                ),
                const SizedBox(height: 26),
                const _SectionLabel('PAYOUT SETUP'),
                const SizedBox(height: 10),
                _VerificationCard(
                  summary: _summary,
                  progress: _verificationProgress,
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
                  hasMethod:
                      _payoutMethod?.enabled == true &&
                      (_payoutMethod?.liveRecipientEmail.trim().isNotEmpty ??
                          false),
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

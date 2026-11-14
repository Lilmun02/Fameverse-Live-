import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class Build23OwnerControlCenterScreen extends StatefulWidget {
  const Build23OwnerControlCenterScreen({this.onOpenCreatorStudio, super.key});

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
  List<Map<String, dynamic>> _payouts = const [];
  List<Map<String, dynamic>> _verificationQueue = const [];

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

  List<Map<String, dynamic>> _rows(dynamic value) {
    if (value is! List) return const [];
    return value
        .whereType<Map>()
        .map((row) => Map<String, dynamic>.from(row))
        .toList();
  }

  Future<void> _refresh() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    dynamic summaryResult;
    dynamic walletResult;
    dynamic payoutResult;
    dynamic verificationResult;
    final failures = <String>[];

    try {
      summaryResult = await _client.rpc('get_owner_finance_control_summary');
    } catch (_) {
      failures.add('finance summary');
    }
    try {
      walletResult = await _client.rpc('get_my_coin_funding_breakdown');
    } catch (_) {
      failures.add('coin balances');
    }
    try {
      payoutResult = await _client.rpc(
        'get_creator_payout_moderation_queue_v2',
        params: const {'p_limit': 50},
      );
    } catch (_) {
      failures.add('payout review');
    }
    try {
      verificationResult = await _client.rpc(
        'get_creator_verification_moderation_queue',
        params: const {'p_limit': 50},
      );
    } catch (_) {
      failures.add('verification review');
    }

    if (!mounted) return;
    setState(() {
      if (summaryResult != null) _summary = _firstRow(summaryResult);
      if (walletResult != null) _wallet = _firstRow(walletResult);
      if (payoutResult != null) _payouts = _rows(payoutResult);
      if (verificationResult != null) {
        _verificationQueue = _rows(verificationResult);
      }
      _loading = false;
      _error = failures.isEmpty
          ? null
          : 'Some owner data could not refresh: ${failures.join(', ')}.';
    });
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
      _message(r'Enter an amount greater than $0.');
      return null;
    }
    return cents;
  }

  Future<({String note, String reference})?> _askPayoutReview({
    required String title,
    required String body,
    required String action,
    bool requireReference = false,
  }) async {
    final noteController = TextEditingController();
    final referenceController = TextEditingController();
    final result = await showDialog<({String note, String reference})>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(body),
              const SizedBox(height: 14),
              TextField(
                controller: noteController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Moderation note (optional)',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: referenceController,
                decoration: InputDecoration(
                  labelText: requireReference
                      ? 'Provider reference / transaction ID'
                      : 'Provider reference (optional)',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final reference = referenceController.text.trim();
              if (requireReference && reference.isEmpty) return;
              Navigator.of(
                context,
              ).pop((note: noteController.text.trim(), reference: reference));
            },
            child: Text(action),
          ),
        ],
      ),
    );
    noteController.dispose();
    referenceController.dispose();
    return result;
  }

  Future<void> _reviewVerification(
    Map<String, dynamic> request,
    String status,
  ) async {
    if (_busy) return;
    final userId = request['user_id']?.toString();
    if (userId == null || userId.isEmpty) return;
    setState(() => _busy = true);
    try {
      await _client.rpc(
        'review_creator_verification',
        params: {
          'p_user_id': userId,
          'p_status': status,
          'p_public_note': status == 'verified'
              ? 'Creator verification approved by Fameverse review.'
              : status == 'needs_info'
              ? 'More information is required before verification can be approved.'
              : 'Verification request was not approved.',
        },
      );
      _message('Verification updated to ${status.replaceAll('_', ' ')}.');
      await _refresh();
    } catch (_) {
      _message('Could not update creator verification.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _reviewPayout(Map<String, dynamic> payout, String status) async {
    if (_busy) return;
    final payoutId = payout['payout_id']?.toString();
    if (payoutId == null || payoutId.isEmpty) return;
    final title = switch (status) {
      'approved' => 'Approve payout',
      'held' => 'Hold payout',
      'rejected' => 'Reject payout',
      'paid' => 'Mark payout paid',
      'failed' => 'Mark payout failed',
      _ => 'Update payout',
    };
    final result = await _askPayoutReview(
      title: title,
      body: status == 'paid'
          ? 'Only mark this paid after the real provider payment has succeeded. Fameverse will debit the creator earnings ledger when this is confirmed.'
          : 'This action changes the payout moderation status. It does not move money through PayPal by itself.',
      action: status == 'paid' ? 'Confirm paid' : 'Confirm',
      requireReference: status == 'paid',
    );
    if (result == null) return;
    setState(() => _busy = true);
    try {
      await _client.rpc(
        'review_creator_payout',
        params: {
          'p_payout_id': payoutId,
          'p_status': status,
          'p_moderation_note': result.note,
          'p_external_reference': result.reference,
        },
      );
      _message('Payout status updated to ${status.replaceAll('_', ' ')}.');
      await _refresh();
    } catch (error) {
      final text = error.toString().toLowerCase();
      if (text.contains('verified creator required')) {
        _message(
          'This creator must be verified before a payout can be marked paid.',
        );
      } else {
        _message('Could not update that payout.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _beginPayoutProcessing(Map<String, dynamic> payout) async {
    if (_busy) return;
    final payoutId = payout['payout_id']?.toString();
    if (payoutId == null || payoutId.isEmpty) return;
    setState(() => _busy = true);
    try {
      final response = await _client.functions.invoke(
        'process-creator-payout',
        body: {'payout_id': payoutId, 'expected_environment': 'sandbox'},
      );
      final data = response.data is Map
          ? Map<String, dynamic>.from(response.data as Map)
          : const <String, dynamic>{};
      final ok =
          response.status >= 200 && response.status < 300 && data['ok'] == true;
      if (!ok) {
        final code = data['error']?.toString() ?? 'provider_submission_failed';
        throw StateError(code);
      }
      final providerStatus = data['provider_status']?.toString() ?? 'PENDING';
      _message('PayPal sandbox payout submitted: $providerStatus.');
      await _refresh();
    } catch (error) {
      final text = error.toString();
      final code = text.contains('paypal_credentials_missing')
          ? 'PayPal sandbox credentials are not configured.'
          : text.contains('paypal_environment_mismatch')
          ? 'PayPal payout environment does not match sandbox QA.'
          : text.contains('paypal_auth_failed')
          ? 'PayPal sandbox authentication failed.'
          : text.contains('paypal_payout_failed')
          ? 'PayPal rejected the sandbox payout.'
          : text.contains('paypal_submission_unknown') ||
                text.contains('paypal_batch_id_missing')
          ? 'PayPal submission is still unresolved. The creator funds remain reserved; use Recover PayPal submission again after refresh.'
          : text.contains('payout_not_processable')
          ? 'This payout is not approved for processing or recovery.'
          : 'Provider submission failed.';
      _message(code);
      await _refresh();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _syncPayoutStatus(Map<String, dynamic> payout) async {
    if (_busy) return;
    final payoutId = payout['payout_id']?.toString();
    if (payoutId == null || payoutId.isEmpty) return;
    setState(() => _busy = true);
    try {
      final response = await _client.functions.invoke(
        'sync-creator-payout',
        body: {'payout_id': payoutId, 'expected_environment': 'sandbox'},
      );
      final data = response.data is Map
          ? Map<String, dynamic>.from(response.data as Map)
          : const <String, dynamic>{};
      final ok =
          response.status >= 200 && response.status < 300 && data['ok'] == true;
      if (!ok) {
        final code = data['error']?.toString() ?? 'provider_sync_failed';
        throw StateError(code);
      }
      final fameverseStatus =
          data['fameverse_status']?.toString() ?? 'processing';
      final providerStatus = data['provider_status']?.toString() ?? 'PENDING';
      _message('PayPal status: $providerStatus · Fameverse: $fameverseStatus.');
      await _refresh();
    } catch (error) {
      final text = error.toString();
      final message = text.contains('provider_batch_missing')
          ? 'This payout has no PayPal batch ID. Submit it to PayPal first.'
          : text.contains('paypal_auth_failed')
          ? 'PayPal sandbox authentication failed.'
          : text.contains('paypal_status_failed')
          ? 'PayPal could not return the payout status.'
          : 'Could not sync this payout with PayPal.';
      _message(message);
      await _refresh();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _recordSettledReserve() async {
    if (_busy) return;
    final cents = await _askDollars(
      title: 'Record Reward Funds',
      body:
          'Enter real business cash that has already settled and that you are intentionally setting aside for Fameverse rewards. This records the amount inside Fameverse; it does not transfer money from PayPal.',
      action: 'Record funds',
    );
    if (cents == null) return;
    setState(() => _busy = true);
    try {
      await _client.rpc(
        'owner_allocate_reward_reserve',
        params: {
          'p_amount_cents': cents,
          'p_note': 'Owner recorded settled reward funds',
        },
      );
      _message('Reward Reserve funds recorded.');
      await _refresh();
    } catch (_) {
      _message('Could not record those Reward Reserve funds.');
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
        title: const Text('Create Cash-Backed Fame Coins'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Cash-Backed Fame Coins use real money from the Reward Reserve and can create real creator earnings. Promo Fame Coins are separate and do not use this reserve.',
            ),
            const SizedBox(height: 14),
            TextField(
              controller: coinsController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Cash-Backed Fame Coins',
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
      _message('Enter a valid cash-backed coin amount.');
      return;
    }
    setState(() => _busy = true);
    try {
      await _client.rpc(
        'owner_issue_cash_backed_reward_coins',
        params: {
          'p_coins': coins,
          'p_note': 'Owner created cash-backed reward coins',
        },
      );
      _message('Cash-Backed Fame Coins created.');
      await _refresh();
    } catch (error) {
      final text = error.toString().toLowerCase();
      _message(
        text.contains('insufficient funded cash reward reserve')
            ? 'Not enough Reward Reserve funds for that many cash-backed coins.'
            : 'Could not create Cash-Backed Fame Coins.',
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
        title: const Text('Owner Studio'),
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
                  title: 'My Creator Account',
                  body:
                      'Your creator earnings, verification progress, PayPal payout method and payout history live here. Owner moderation stays in Owner Studio.',
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
                const _Section('CREATOR VERIFICATION'),
                const SizedBox(height: 10),
                if (_verificationQueue.isEmpty)
                  const _Notice(
                    icon: Icons.verified_user_outlined,
                    title: 'No verification requests waiting',
                    body:
                        'Pending creator verification requests will appear here for owner review.',
                  )
                else
                  ..._verificationQueue.map(
                    (request) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _VerificationReviewCard(
                        request: request,
                        busy: _busy,
                        onApprove: () =>
                            _reviewVerification(request, 'verified'),
                        onNeedsInfo: () =>
                            _reviewVerification(request, 'needs_info'),
                        onReject: () =>
                            _reviewVerification(request, 'rejected'),
                      ),
                    ),
                  ),
                const SizedBox(height: 20),
                const _Section('CREATOR PAYOUTS'),
                const SizedBox(height: 10),
                if (_payouts.isEmpty)
                  const _Notice(
                    icon: Icons.task_alt_rounded,
                    title: 'No payouts waiting',
                    body:
                        'Pending, approved and processing creator payouts will appear here for owner review.',
                  )
                else
                  ..._payouts.map(
                    (payout) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _PayoutCard(
                        payout: payout,
                        busy: _busy,
                        onApprove: () => _reviewPayout(payout, 'approved'),
                        onHold: () => _reviewPayout(payout, 'held'),
                        onReject: () => _reviewPayout(payout, 'rejected'),
                        onProcess: () => _beginPayoutProcessing(payout),
                        onSync: () => _syncPayoutStatus(payout),
                      ),
                    ),
                  ),
                const SizedBox(height: 20),
                const _Section('PLATFORM FINANCES'),
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
                const _Section('REWARD RESERVE & LIABILITIES'),
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
                const _Section('FAME STONE BALANCES'),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _Metric(
                        label: 'Promo Fame Coins · no cash value',
                        value: '${_int(_wallet['promo_coins'])}',
                        icon: Icons.science_outlined,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _Metric(
                        label: 'Cash-Backed Fame Coins · real reserve',
                        value: '${_int(_wallet['cash_backed_coins'])}',
                        icon: Icons.attach_money_rounded,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const _Section('REWARD FUNDING & OWNER BANKING'),
                const SizedBox(height: 10),
                _Action(
                  key: const Key('owner-open-paypal-funding'),
                  icon: Icons.paypal_outlined,
                  title: 'Open PayPal Business',
                  body:
                      'View the real cash available in your PayPal Business account. PayPal may not show an Add Money option on every account, so Fameverse does not assume that button exists.',
                  label: 'Open PayPal',
                  onTap: _openPayPal,
                ),
                const SizedBox(height: 10),
                _Action(
                  key: const Key('owner-record-settled-reserve'),
                  icon: Icons.account_balance_wallet_outlined,
                  title: 'Record Reward Funds',
                  body:
                      'Record only real business cash you have already set aside for rewards. Example: record \$10 and Fameverse shows \$10 available in the Reward Reserve. This does not move money.',
                  label: 'Record funds',
                  onTap: _busy ? null : _recordSettledReserve,
                ),
                const SizedBox(height: 10),
                _Action(
                  key: const Key('owner-issue-cash-reward-coins'),
                  icon: Icons.toll_rounded,
                  title: 'Create Cash-Backed Fame Coins',
                  body:
                      'Create coins from the Reward Reserve only when you want those coins to be capable of creating real creator earnings. Promo Fame Coins stay separate.',
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

class _VerificationReviewCard extends StatelessWidget {
  const _VerificationReviewCard({
    required this.request,
    required this.busy,
    required this.onApprove,
    required this.onNeedsInfo,
    required this.onReject,
  });

  final Map<String, dynamic> request;
  final bool busy;
  final VoidCallback onApprove;
  final VoidCallback onNeedsInfo;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final displayName =
        request['display_name']?.toString() ?? 'Fameverse Creator';
    final username = request['username']?.toString();
    final status = request['status']?.toString() ?? 'pending';
    final userId = request['user_id']?.toString() ?? 'unknown';
    return Container(
      key: Key('owner-verification-$userId'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF17111B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF4A3553)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            displayName,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
          ),
          if (username != null && username.isNotEmpty)
            Text(
              '@$username',
              style: const TextStyle(color: Color(0xFFA89CAE)),
            ),
          const SizedBox(height: 8),
          Chip(label: Text(status.replaceAll('_', ' '))),
          if ((request['public_note']?.toString() ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              request['public_note'].toString().trim(),
              style: const TextStyle(color: Color(0xFFB8ACBC), fontSize: 11),
            ),
          ],
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton(
                key: const Key('owner-verification-approve'),
                onPressed: busy ? null : onApprove,
                child: const Text('Verify'),
              ),
              FilledButton.tonal(
                key: const Key('owner-verification-needs-info'),
                onPressed: busy ? null : onNeedsInfo,
                child: const Text('Needs info'),
              ),
              TextButton(
                key: const Key('owner-verification-reject'),
                onPressed: busy ? null : onReject,
                child: const Text('Reject'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PayoutCard extends StatelessWidget {
  const _PayoutCard({
    required this.payout,
    required this.busy,
    required this.onApprove,
    required this.onHold,
    required this.onReject,
    required this.onProcess,
    required this.onSync,
  });

  final Map<String, dynamic> payout;
  final bool busy;
  final VoidCallback onApprove;
  final VoidCallback onHold;
  final VoidCallback onReject;
  final VoidCallback onProcess;
  final VoidCallback onSync;

  @override
  Widget build(BuildContext context) {
    final status = payout['status']?.toString() ?? 'pending_review';
    final creator = payout['display_name']?.toString() ?? 'Fameverse Creator';
    final username = payout['username']?.toString();
    final verification =
        payout['verification_status']?.toString() ?? 'unverified';
    final amount = _money((payout['amount_cents'] as num?)?.toInt() ?? 0);
    final providerStatus = payout['provider_status']?.toString() ?? '';
    final providerBatchId = payout['provider_batch_id']?.toString() ?? '';
    final needsProviderRecovery =
        status == 'processing' &&
        providerBatchId.isEmpty &&
        (providerStatus == 'SUBMISSION_UNKNOWN' ||
            providerStatus == 'SUBMITTING');
    return Container(
      key: Key('owner-payout-${payout['payout_id']}'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF17111B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF4A3553)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      creator,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (username != null && username.isNotEmpty)
                      Text(
                        '@$username',
                        style: const TextStyle(color: Color(0xFFA89CAE)),
                      ),
                  ],
                ),
              ),
              Text(
                amount,
                style: const TextStyle(
                  color: Color(0xFFFFD38E),
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Chip(label: Text(status.replaceAll('_', ' '))),
              Chip(label: Text('Verification: $verification')),
              if (providerStatus.isNotEmpty)
                Chip(
                  label: Text('PayPal: ${providerStatus.replaceAll('_', ' ')}'),
                ),
            ],
          ),
          if ((payout['moderation_note']?.toString() ?? '').isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              payout['moderation_note'].toString(),
              style: const TextStyle(color: Color(0xFFB8ACBC), fontSize: 11),
            ),
          ],
          const SizedBox(height: 12),
          if (status == 'pending_review')
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton(
                  key: const Key('owner-payout-approve'),
                  onPressed: busy ? null : onApprove,
                  child: const Text('Approve'),
                ),
                FilledButton.tonal(
                  onPressed: busy ? null : onHold,
                  child: const Text('Hold'),
                ),
                TextButton(
                  onPressed: busy ? null : onReject,
                  child: const Text('Reject'),
                ),
              ],
            )
          else if (status == 'approved')
            FilledButton.icon(
              key: const Key('owner-payout-begin-processing'),
              onPressed: busy ? null : onProcess,
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('Send with PayPal sandbox'),
            )
          else if (status == 'processing' && needsProviderRecovery)
            FilledButton.icon(
              key: const Key('owner-payout-recover-provider'),
              onPressed: busy ? null : onProcess,
              icon: const Icon(Icons.restart_alt_rounded),
              label: const Text('Recover PayPal submission'),
            )
          else if (status == 'processing')
            FilledButton.icon(
              key: const Key('owner-payout-sync-provider'),
              onPressed: busy ? null : onSync,
              icon: const Icon(Icons.sync_rounded),
              label: const Text('Sync PayPal status'),
            ),
        ],
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
            'Promo Fame Coins are test-only and have no cash value. Reward Reserve is real business money set aside for rewards. Cash-Backed Fame Coins use that reserve and can create real creator earnings.',
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
          _Line(label: 'Reward Reserve available', value: _money(reserveCents)),
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
          child: Text(label, style: const TextStyle(color: Color(0xFFB7AAB9))),
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
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

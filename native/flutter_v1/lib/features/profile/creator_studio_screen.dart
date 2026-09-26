import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/fameverse_backend.dart';
import '../../data/fameverse_creator_backend.dart';

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
  String? _role;
  FvCreatorPayoutSummary _summary = FvCreatorPayoutSummary.empty;
  List<FvCreatorPayoutRequest> _requests = const [];
  List<FvVerificationModerationItem> _verificationQueue = const [];
  List<FvPayoutModerationItem> _payoutQueue = const [];

  bool get _isOwner => _role == 'owner';

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
      final role = await widget.backend.loadRole(widget.identity.id);
      final summary = await widget.backend.loadPayoutSummary();
      final requests = await widget.backend.listPayoutRequests();
      var verificationQueue = const <FvVerificationModerationItem>[];
      var payoutQueue = const <FvPayoutModerationItem>[];
      if (role == 'owner') {
        verificationQueue = await widget.backend.listVerificationQueue();
        payoutQueue = await widget.backend.listPayoutQueue();
      }
      if (!mounted) return;
      setState(() {
        _role = role;
        _summary = summary;
        _requests = requests;
        _verificationQueue = verificationQueue;
        _payoutQueue = payoutQueue;
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

  Future<void> _requestVerification() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await widget.backend.requestVerification();
      _message('Verification request sent for Fameverse review.');
      await _refresh();
    } catch (_) {
      _message('Could not request verification right now.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openPayoutRequest() async {
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
              r'Minimum payout is $25.00. Every request goes through Fameverse review before money is released.',
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
        text.contains('verification')
            ? 'Verification is required before requesting a payout.'
            : text.contains('minimum')
            ? r'Minimum payout is $25.00.'
            : text.contains('payout method')
            ? 'Add a PayPal payout email before requesting a payout.'
            : 'Could not submit payout request.',
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _reviewVerification(
    FvVerificationModerationItem item,
    String status,
  ) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await widget.backend.reviewVerification(
        userId: item.userId,
        status: status,
      );
      _message('Verification updated to ${_label(status)}.');
      await _refresh();
    } catch (_) {
      _message('Could not update verification.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _reviewPayout(FvPayoutModerationItem item, String status) async {
    if (_busy) return;
    String? reference;
    if (status == 'paid') {
      final controller = TextEditingController();
      reference = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Mark payout paid'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'External payment reference',
              hintText: 'PayPal / processor reference',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(controller.text),
              child: const Text('Mark paid'),
            ),
          ],
        ),
      );
      controller.dispose();
      if (reference == null) return;
    }

    setState(() => _busy = true);
    try {
      await widget.backend.reviewPayout(
        payoutId: item.payoutId,
        status: status,
        externalReference: reference,
      );
      _message('Payout updated to ${_label(status)}.');
      await _refresh();
    } catch (_) {
      _message('Could not update payout review.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _openSandboxQa() {
    Navigator.of(context)
        .push<void>(
          MaterialPageRoute(
            builder: (context) => const _OwnerPayoutSandboxQaScreen(),
          ),
        )
        .then((_) => _refresh());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
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
            key: const Key('creator-studio-screen'),
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 40),
            children: [
              _StudioHero(profile: widget.profile),
              const SizedBox(height: 18),
              if (_loading)
                const _StudioLoading()
              else if (_error != null)
                _StudioInfoCard(
                  icon: Icons.cloud_off_rounded,
                  title: 'Creator Studio unavailable',
                  body: _error!,
                )
              else ...[
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
                const SizedBox(height: 24),
                _VerificationCard(
                  status: _summary.verificationStatus,
                  busy: _busy,
                  onRequest: _requestVerification,
                ),
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
                        r'When verified creator earnings reach $25, requests and their review status will appear here.',
                  )
                else
                  ..._requests.map((item) => _PayoutRequestTile(item: item)),
                if (_isOwner) ...[
                  const SizedBox(height: 32),
                  const _SectionLabel('OWNER QA'),
                  const SizedBox(height: 10),
                  _OwnerSandboxCard(onTap: _openSandboxQa),
                  const SizedBox(height: 32),
                  const _SectionLabel('OWNER MODERATION'),
                  const SizedBox(height: 6),
                  const Text(
                    'No payout can reach Paid until Fameverse moderation reviews the creator and the payout request.',
                    style: TextStyle(color: Color(0xFFB6AABE), height: 1.35),
                  ),
                  const SizedBox(height: 14),
                  _OwnerVerificationQueue(
                    items: _verificationQueue,
                    busy: _busy,
                    onReview: _reviewVerification,
                  ),
                  const SizedBox(height: 14),
                  _OwnerPayoutQueue(
                    items: _payoutQueue,
                    busy: _busy,
                    onReview: _reviewPayout,
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _OwnerPayoutSandboxQaScreen extends StatefulWidget {
  const _OwnerPayoutSandboxQaScreen();

  @override
  State<_OwnerPayoutSandboxQaScreen> createState() =>
      _OwnerPayoutSandboxQaScreenState();
}

class _OwnerPayoutSandboxQaScreenState
    extends State<_OwnerPayoutSandboxQaScreen> {
  final _email = TextEditingController();
  bool _busy = false;
  String _status = 'Ready for owner-only payout QA.';
  String? _latestPayoutId;

  SupabaseClient get _client => Supabase.instance.client;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _run(String label, Future<void> Function() action) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _status = '$label…';
    });
    try {
      await action();
      if (mounted) setState(() => _status = '$label ✓');
    } catch (error) {
      if (!mounted) return;
      final text = error.toString();
      setState(() => _status = '$label failed: $text');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _savePayPal() async {
    final email = _email.text.trim();
    if (!email.contains('@')) {
      setState(
        () => _status = 'Enter the PayPal sandbox recipient email first.',
      );
      return;
    }
    await _run('Save PayPal sandbox recipient', () async {
      await _client.rpc(
        'set_creator_payout_method',
        params: {'p_provider': 'paypal', 'p_recipient_email': email},
      );
    });
  }

  Future<void> _requestAndVerify() async {
    await _run('Verify owner QA account', () async {
      await _client.rpc('request_creator_verification');
      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw Exception('No authenticated Fameverse user.');
      await _client.rpc(
        'review_creator_verification',
        params: {
          'p_user_id': userId,
          'p_status': 'verified',
          'p_public_note': 'Owner sandbox payout QA verification',
        },
      );
    });
  }

  Future<void> _grantQaEarnings() async {
    await _run(r'Grant $25 sandbox earnings', () async {
      await _client.rpc(
        'grant_owner_payout_test_earnings',
        params: {'p_amount_cents': 2500},
      );
    });
  }

  Future<void> _createAndApprovePayout() async {
    await _run(r'Create + approve $25 payout', () async {
      final response = await _client.rpc(
        'request_creator_payout',
        params: {'p_amount_cents': 2500},
      );
      if (response is! List || response.isEmpty || response.first is! Map) {
        throw Exception('Payout request was not created.');
      }
      final row = Map<String, dynamic>.from(response.first as Map);
      final payoutId = row['payout_id']?.toString();
      if (payoutId == null || payoutId.isEmpty) {
        throw Exception('Payout ID missing.');
      }
      await _client.rpc(
        'review_creator_payout',
        params: {
          'p_payout_id': payoutId,
          'p_status': 'approved',
          'p_moderation_note': 'Owner sandbox payout QA approval',
          'p_external_reference': null,
        },
      );
      _latestPayoutId = payoutId;
    });
  }

  Future<void> _sendSandboxPayout() async {
    final payoutId = _latestPayoutId;
    if (payoutId == null) {
      setState(() => _status = r'Create + approve the $25 payout first.');
      return;
    }
    await _run('Send PayPal sandbox payout', () async {
      final response = await _client.functions.invoke(
        'process-creator-payout',
        body: {'payout_id': payoutId, 'expected_environment': 'sandbox'},
      );
      final data = response.data;
      if (data is Map && data['error'] != null) {
        throw Exception(data['error']);
      }
    });
  }

  Future<void> _syncSandboxPayout() async {
    final payoutId = _latestPayoutId;
    if (payoutId == null) {
      setState(() => _status = 'No sandbox payout has been created yet.');
      return;
    }
    await _run('Sync PayPal sandbox status', () async {
      final response = await _client.functions.invoke(
        'sync-creator-payout',
        body: {'payout_id': payoutId, 'expected_environment': 'sandbox'},
      );
      final data = response.data;
      if (data is Map && data['error'] != null) {
        throw Exception(data['error']);
      }
      if (data is Map) {
        final provider = data['provider_status']?.toString() ?? 'unknown';
        final fameverse = data['fameverse_status']?.toString() ?? 'unknown';
        if (mounted) {
          setState(() {
            _status = 'PayPal: $provider · Fameverse: $fameverse ✓';
          });
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payout Sandbox QA')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 40),
          children: [
            const _StudioInfoCard(
              icon: Icons.science_outlined,
              title: 'Sandbox only',
              body:
                  'This owner-only console requires PayPal sandbox credentials. Every payout call requires the backend to confirm the configured PayPal environment is sandbox before money is submitted.',
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'PayPal sandbox recipient email',
                hintText: 'sandbox-personal@example.com',
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.tonal(
              onPressed: _busy ? null : _savePayPal,
              child: const Text('1. Save sandbox PayPal recipient'),
            ),
            const SizedBox(height: 8),
            FilledButton.tonal(
              onPressed: _busy ? null : _requestAndVerify,
              child: const Text('2. Verify owner QA account'),
            ),
            const SizedBox(height: 8),
            FilledButton.tonal(
              onPressed: _busy ? null : _grantQaEarnings,
              child: const Text(r'3. Add $25 QA earnings'),
            ),
            const SizedBox(height: 8),
            FilledButton.tonal(
              onPressed: _busy ? null : _createAndApprovePayout,
              child: const Text(r'4. Create + approve $25 payout'),
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: _busy ? null : _sendSandboxPayout,
              child: const Text('5. Send with PayPal Sandbox'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: _busy ? null : _syncSandboxPayout,
              child: const Text('6. Sync payout status'),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: _studioPanel(),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_busy)
                    const Padding(
                      padding: EdgeInsets.only(right: 12, top: 2),
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  else
                    const Padding(
                      padding: EdgeInsets.only(right: 12),
                      child: Icon(Icons.terminal_rounded, size: 20),
                    ),
                  Expanded(
                    child: Text(_status, style: const TextStyle(height: 1.4)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'QA credits are synthetic creator earnings and do not define the future gift-to-cash conversion. Public payout verification will be stricter than this owner-only sandbox shortcut.',
              style: TextStyle(
                color: Color(0xFF9F93A8),
                fontSize: 12,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OwnerSandboxCard extends StatelessWidget {
  const _OwnerSandboxCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: const Key('open-payout-sandbox-qa'),
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Ink(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1427),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF674383)),
        ),
        child: const Row(
          children: [
            Icon(Icons.science_outlined, color: Color(0xFFC99BFF)),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Payout Sandbox QA',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                  SizedBox(height: 3),
                  Text(
                    r'Test verification → $25 earnings → payout → PayPal Sandbox.',
                    style: TextStyle(color: Color(0xFFB6AABE), fontSize: 12),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    );
  }
}

class _StudioHero extends StatelessWidget {
  const _StudioHero({required this.profile});

  final FvProfile profile;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF4B236D), Color(0xFF1D1029), Color(0xFF110B17)],
        ),
        border: Border.all(color: const Color(0xFF68408A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'FAMEVERSE CREATOR',
            style: TextStyle(
              color: Color(0xFFD6B7FF),
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Build. Earn. Grow.',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Text(
            '${profile.displayName}, your creator business lives here.',
            style: const TextStyle(color: Color(0xFFC4B8CC)),
          ),
        ],
      ),
    );
  }
}

class _VerificationCard extends StatelessWidget {
  const _VerificationCard({
    required this.status,
    required this.busy,
    required this.onRequest,
  });

  final String status;
  final bool busy;
  final VoidCallback onRequest;

  @override
  Widget build(BuildContext context) {
    final verified = status == 'verified';
    final pending = status == 'pending';
    final blocked = status == 'suspended';
    final canRequest = !verified && !pending && !blocked;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _studioPanel(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                verified
                    ? Icons.verified_rounded
                    : Icons.verified_user_outlined,
                color: verified ? const Color(0xFFB784FF) : null,
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Payout verification',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
                ),
              ),
              _StatusPill(status: status),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            verified
                ? 'Your Fameverse payout verification is approved. Payouts still require cleared earnings and moderation review.'
                : pending
                ? 'Your verification request is waiting for Fameverse review. You cannot request a payout until it is approved.'
                : blocked
                ? 'Payout verification is currently suspended. Payout requests are disabled.'
                : 'Verification is required before any creator payout. Fameverse reviews payout eligibility before money can leave the platform.',
            style: const TextStyle(color: Color(0xFFB7ACBF), height: 1.4),
          ),
          if (canRequest) ...[
            const SizedBox(height: 14),
            FilledButton.icon(
              key: const Key('request-payout-verification'),
              onPressed: busy ? null : onRequest,
              icon: const Icon(Icons.verified_user_outlined),
              label: const Text('Request verification'),
            ),
          ],
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
        ? 'Verification required'
        : summary.withdrawableCents < summary.minimumPayoutCents
        ? '${_money(summary.minimumPayoutCents)} minimum'
        : null;
    return Container(
      key: const Key('creator-payout-card'),
      padding: const EdgeInsets.all(18),
      decoration: _studioPanel(),
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
            'Only cleared creator earnings can be requested. Every payout enters moderation review before it can be processed.',
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
      decoration: _studioPanel(),
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
      decoration: _studioPanel(),
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

class _OwnerVerificationQueue extends StatelessWidget {
  const _OwnerVerificationQueue({
    required this.items,
    required this.busy,
    required this.onReview,
  });

  final List<FvVerificationModerationItem> items;
  final bool busy;
  final void Function(FvVerificationModerationItem, String) onReview;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _studioPanel(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Verification queue',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          if (items.isEmpty)
            const Text(
              'No verification requests waiting.',
              style: TextStyle(color: Color(0xFFAFA4B8)),
            )
          else
            ...items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.displayName,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    Text(
                      item.username == null ? item.userId : '@${item.username}',
                      style: const TextStyle(
                        color: Color(0xFFAFA4B8),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 7,
                      runSpacing: 7,
                      children: [
                        FilledButton.tonal(
                          onPressed: busy
                              ? null
                              : () => onReview(item, 'verified'),
                          child: const Text('Verify'),
                        ),
                        OutlinedButton(
                          onPressed: busy
                              ? null
                              : () => onReview(item, 'needs_info'),
                          child: const Text('Needs info'),
                        ),
                        TextButton(
                          onPressed: busy
                              ? null
                              : () => onReview(item, 'rejected'),
                          child: const Text('Reject'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _OwnerPayoutQueue extends StatelessWidget {
  const _OwnerPayoutQueue({
    required this.items,
    required this.busy,
    required this.onReview,
  });

  final List<FvPayoutModerationItem> items;
  final bool busy;
  final void Function(FvPayoutModerationItem, String) onReview;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _studioPanel(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Payout review queue',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          if (items.isEmpty)
            const Text(
              'No payout requests waiting.',
              style: TextStyle(color: Color(0xFFAFA4B8)),
            )
          else
            ...items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${item.displayName} · ${_money(item.amountCents)}',
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                        _StatusPill(status: item.status),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 7,
                      runSpacing: 7,
                      children: [
                        OutlinedButton(
                          onPressed: busy
                              ? null
                              : () => onReview(item, 'approved'),
                          child: const Text('Approve'),
                        ),
                        OutlinedButton(
                          onPressed: busy
                              ? null
                              : () => onReview(item, 'processing'),
                          child: const Text('Processing'),
                        ),
                        FilledButton.tonal(
                          onPressed: busy ? null : () => onReview(item, 'paid'),
                          child: const Text('Paid'),
                        ),
                        TextButton(
                          onPressed: busy
                              ? null
                              : () => onReview(item, 'rejected'),
                          child: const Text('Reject'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
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
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF352344),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFF5C3B78)),
      ),
      child: Text(
        _label(status),
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800),
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
        color: Color(0xFFB784FF),
        fontSize: 11,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.2,
      ),
    );
  }
}

class _StudioLoading extends StatelessWidget {
  const _StudioLoading();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 150,
      decoration: _studioPanel(),
      child: const Center(child: CircularProgressIndicator()),
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
      decoration: _studioPanel(),
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

BoxDecoration _studioPanel() {
  return BoxDecoration(
    color: const Color(0xFF17111E),
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: const Color(0xFF2E2238)),
  );
}

String _money(int cents) => '\$${(cents / 100).toStringAsFixed(2)}';

String _label(String value) {
  return value
      .split('_')
      .where((part) => part.isNotEmpty)
      .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');
}

String _dateLabel(DateTime? value) {
  if (value == null) return 'Date unavailable';
  final local = value.toLocal();
  return '${local.month}/${local.day}/${local.year}';
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/fameverse_creator_backend.dart';

class OwnerControlPanel extends StatefulWidget {
  const OwnerControlPanel({super.key});

  @override
  State<OwnerControlPanel> createState() => _OwnerControlPanelState();
}

class _OwnerControlPanelState extends State<OwnerControlPanel> {
  late final SupabaseFameverseCreatorBackend _backend;
  bool _loading = true;
  bool _busy = false;
  String? _error;
  String? _role;
  List<FvPayoutModerationItem> _payouts = const [];
  List<FvVerificationModerationItem> _verifications = const [];

  bool get _isOwner => _role == 'owner';

  @override
  void initState() {
    super.initState();
    _backend = SupabaseFameverseCreatorBackend(Supabase.instance.client);
    unawaited(_refresh());
  }

  Future<void> _refresh() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) throw StateError('signed-out');
      final role = await _backend.loadRole(userId);
      if (role != 'owner') {
        if (!mounted) return;
        setState(() {
          _role = role;
          _loading = false;
          _error = 'Owner access required.';
        });
        return;
      }
      final results = await Future.wait<dynamic>([
        _backend.listPayoutQueue(limit: 100),
        _backend.listVerificationQueue(limit: 100),
      ]);
      if (!mounted) return;
      setState(() {
        _role = role;
        _payouts = results[0] as List<FvPayoutModerationItem>;
        _verifications = results[1] as List<FvVerificationModerationItem>;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Owner controls could not refresh. ${error.toString()}';
      });
    }
  }

  void _message(String value) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(value)));
  }

  Future<void> _reviewPayout(
    FvPayoutModerationItem item,
    String status,
  ) async {
    if (_busy || !_isOwner) return;
    setState(() => _busy = true);
    try {
      await _backend.reviewPayout(
        payoutId: item.payoutId,
        status: status,
        moderationNote: status == 'rejected'
            ? 'Rejected by Fameverse owner review.'
            : null,
      );
      _message('Payout marked $status.');
      await _refresh();
    } catch (error) {
      _message('Payout review failed: ${error.toString()}');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _processSandbox(FvPayoutModerationItem item) async {
    if (_busy || !_isOwner || item.status != 'approved') return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Send Sandbox payout?'),
        content: Text(
          'Submit ${_money(item.amountCents)} to PayPal Sandbox for ${item.displayName}. No real money will move.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Send Sandbox'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _busy = true);
    try {
      final response = await Supabase.instance.client.functions.invoke(
        'process-creator-payout',
        body: {
          'payout_id': item.payoutId,
          'expected_environment': 'sandbox',
        },
      );
      if (response.status < 200 || response.status >= 300) {
        throw StateError('HTTP ${response.status}: ${response.data}');
      }
      _message('Sandbox payout submitted to PayPal.');
      await _refresh();
    } catch (error) {
      _message('Sandbox payout failed: ${error.toString()}');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _syncSandbox(FvPayoutModerationItem item) async {
    if (_busy || !_isOwner) return;
    setState(() => _busy = true);
    try {
      final response = await Supabase.instance.client.functions.invoke(
        'sync-creator-payout',
        body: {
          'payout_id': item.payoutId,
          'expected_environment': 'sandbox',
        },
      );
      if (response.status < 200 || response.status >= 300) {
        throw StateError('HTTP ${response.status}: ${response.data}');
      }
      _message('PayPal Sandbox status synced.');
      await _refresh();
    } catch (error) {
      _message('Payout sync failed: ${error.toString()}');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _reviewVerification(
    FvVerificationModerationItem item,
    String status,
  ) async {
    if (_busy || !_isOwner) return;
    setState(() => _busy = true);
    try {
      await _backend.reviewVerification(
        userId: item.userId,
        status: status,
        publicNote: status == 'verified'
            ? 'Verified by Fameverse.'
            : 'Verification needs additional review.',
      );
      _message('Verification marked $status.');
      await _refresh();
    } catch (error) {
      _message('Verification review failed: ${error.toString()}');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('owner-control-panel'),
      backgroundColor: const Color(0xFF070609),
      appBar: AppBar(
        backgroundColor: const Color(0xFF070609),
        title: const Text('Owner Control Panel'),
        actions: [
          IconButton(
            onPressed: _loading ? null : _refresh,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : !_isOwner
            ? _Blocked(message: _error ?? 'Owner access required.')
            : RefreshIndicator(
                onRefresh: _refresh,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 40),
                  children: [
                    const _OwnerHero(),
                    const SizedBox(height: 22),
                    _CountRow(
                      payouts: _payouts.length,
                      verifications: _verifications.length,
                    ),
                    const SizedBox(height: 26),
                    const _SectionTitle('PAYOUT REVIEW'),
                    const SizedBox(height: 10),
                    if (_payouts.isEmpty)
                      const _EmptyCard(
                        icon: Icons.payments_outlined,
                        title: 'No payouts waiting',
                        body: 'New creator payout requests will appear here.',
                      )
                    else
                      ..._payouts.map(
                        (item) => _PayoutCard(
                          item: item,
                          busy: _busy,
                          onApprove: () => _reviewPayout(item, 'approved'),
                          onReject: () => _reviewPayout(item, 'rejected'),
                          onProcess: () => _processSandbox(item),
                          onSync: () => _syncSandbox(item),
                        ),
                      ),
                    const SizedBox(height: 28),
                    const _SectionTitle('VERIFICATION REVIEW'),
                    const SizedBox(height: 10),
                    if (_verifications.isEmpty)
                      const _EmptyCard(
                        icon: Icons.verified_user_outlined,
                        title: 'No verification requests',
                        body: 'Pending creator verification requests will appear here.',
                      )
                    else
                      ..._verifications.map(
                        (item) => _VerificationCard(
                          item: item,
                          busy: _busy,
                          onApprove: () => _reviewVerification(item, 'verified'),
                          onNeedsInfo: () =>
                              _reviewVerification(item, 'needs_info'),
                        ),
                      ),
                    const SizedBox(height: 28),
                    const _SafetyCard(),
                  ],
                ),
              ),
      ),
    );
  }
}

String _money(int cents) => '\$${(cents / 100).toStringAsFixed(2)}';

class _OwnerHero extends StatelessWidget {
  const _OwnerHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF6D3A84)),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF32133F), Color(0xFF160C1C), Color(0xFF09070B)],
        ),
      ),
      child: const Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: Color(0xFF512468),
            child: Icon(Icons.admin_panel_settings_rounded),
          ),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'FAMEVERSE OWNER',
                  style: TextStyle(
                    color: Color(0xFFD4A6FF),
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.3,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Moderation & Money Controls',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CountRow extends StatelessWidget {
  const _CountRow({required this.payouts, required this.verifications});

  final int payouts;
  final int verifications;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _CountCard(label: 'Payout queue', value: payouts)),
        const SizedBox(width: 10),
        Expanded(
          child: _CountCard(label: 'Verification queue', value: verifications),
        ),
      ],
    );
  }
}

class _CountCard extends StatelessWidget {
  const _CountCard({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF151019),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF3D2B46)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$value', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: Color(0xFFAA9BAF), fontSize: 11)),
        ],
      ),
    );
  }
}

class _PayoutCard extends StatelessWidget {
  const _PayoutCard({
    required this.item,
    required this.busy,
    required this.onApprove,
    required this.onReject,
    required this.onProcess,
    required this.onSync,
  });

  final FvPayoutModerationItem item;
  final bool busy;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onProcess;
  final VoidCallback onSync;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: const Color(0xFF141017),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.displayName,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                  ),
                ),
                Text(_money(item.amountCents), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${item.username == null ? '' : '@${item.username} · '}${item.status} · ${item.verificationStatus}',
              style: const TextStyle(color: Color(0xFFA99EAC), fontSize: 11),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (item.status == 'pending_review') ...[
                  FilledButton.icon(
                    onPressed: busy ? null : onApprove,
                    icon: const Icon(Icons.check_rounded),
                    label: const Text('Approve'),
                  ),
                  OutlinedButton.icon(
                    onPressed: busy ? null : onReject,
                    icon: const Icon(Icons.close_rounded),
                    label: const Text('Reject'),
                  ),
                ],
                if (item.status == 'approved')
                  FilledButton.icon(
                    onPressed: busy ? null : onProcess,
                    icon: const Icon(Icons.paypal_rounded),
                    label: const Text('Send Sandbox payout'),
                  ),
                if (item.status == 'processing')
                  FilledButton.tonalIcon(
                    onPressed: busy ? null : onSync,
                    icon: const Icon(Icons.sync_rounded),
                    label: const Text('Sync PayPal status'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _VerificationCard extends StatelessWidget {
  const _VerificationCard({
    required this.item,
    required this.busy,
    required this.onApprove,
    required this.onNeedsInfo,
  });

  final FvVerificationModerationItem item;
  final bool busy;
  final VoidCallback onApprove;
  final VoidCallback onNeedsInfo;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: const Color(0xFF141017),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item.displayName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
            const SizedBox(height: 4),
            Text(
              '${item.username == null ? '' : '@${item.username} · '}${item.status}',
              style: const TextStyle(color: Color(0xFFA99EAC), fontSize: 11),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: busy ? null : onApprove,
                  icon: const Icon(Icons.verified_rounded),
                  label: const Text('Verify'),
                ),
                OutlinedButton.icon(
                  onPressed: busy ? null : onNeedsInfo,
                  icon: const Icon(Icons.info_outline_rounded),
                  label: const Text('Needs info'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFF9C8CA2),
        fontSize: 11,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.3,
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.icon, required this.title, required this.body});

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF141017),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF38283F)),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFB77DFF)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
                const SizedBox(height: 3),
                Text(body, style: const TextStyle(color: Color(0xFFA99EAC), fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SafetyCard extends StatelessWidget {
  const _SafetyCard();

  @override
  Widget build(BuildContext context) {
    return const _EmptyCard(
      icon: Icons.lock_rounded,
      title: 'Owner-only surface',
      body: 'This panel is hidden from ordinary users and protected again by server-side owner checks.',
    );
  }
}

class _Blocked extends StatelessWidget {
  const _Blocked({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Text(message, textAlign: TextAlign.center),
      ),
    );
  }
}

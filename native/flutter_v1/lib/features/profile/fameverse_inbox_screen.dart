import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/fv_policy_access.dart';
import '../../data/fv_system_inbox_repository.dart';

/// Build 47: system activity inbox, using existing published notices only.
/// Direct messaging and personalized read receipts are separate backend work.
class FameverseInboxScreen extends StatefulWidget {
  const FameverseInboxScreen({
    required this.userId,
    this.policyAccess,
    this.onReviewPolicy,
    this.onOpenPolicies,
    this.repository,
    super.key,
  });

  final String userId;
  final FvPolicyAccess? policyAccess;
  final VoidCallback? onReviewPolicy;
  final VoidCallback? onOpenPolicies;
  final FvSystemInboxRepository? repository;

  @override
  State<FameverseInboxScreen> createState() => _FameverseInboxScreenState();
}

class _FameverseInboxScreenState extends State<FameverseInboxScreen> {
  late FvSystemInboxRepository _repository;
  List<FvSystemNotice> _notices = const [];
  String? _error;
  bool _loading = true;
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ??
        SupabaseFvSystemInboxRepository(Supabase.instance.client);
    unawaited(_load());
  }

  @override
  void didUpdateWidget(covariant FameverseInboxScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId ||
        oldWidget.repository != widget.repository) {
      _repository = widget.repository ??
          SupabaseFvSystemInboxRepository(Supabase.instance.client);
      _notices = const [];
      _error = null;
      _loading = true;
      unawaited(_load());
    }
  }

  Future<void> _load() async {
    final generation = ++_generation;
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
        _notices = const [];
      });
    }
    try {
      final notices = await _repository.loadForUser(widget.userId);
      if (!mounted || generation != _generation) return;
      setState(() {
        _notices = notices;
        _loading = false;
      });
    } catch (_) {
      if (!mounted || generation != _generation) return;
      setState(() {
        _notices = const [];
        _loading = false;
        _error = 'System updates are temporarily unavailable.';
      });
    }
  }

  FvPolicyAccess? get _verifiedPolicy {
    final access = widget.policyAccess;
    if (access == null ||
        !access.verifiedForAccount ||
        access.accountId != widget.userId) {
      return null;
    }
    return access;
  }

  @override
  void dispose() {
    _generation++;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final policy = _verifiedPolicy;
    final policyPending = policy?.decision == FvPolicyDecision.unsigned;
    final policyLimited = policy?.decision == FvPolicyDecision.declined ||
        (policy?.requiresSupport ?? false);
    return Scaffold(
      key: const Key('fameverse-native-inbox'),
      backgroundColor: const Color(0xFF100D16),
      appBar: AppBar(
        title: const Text('Inbox'),
        backgroundColor: const Color(0xFF100D16),
        actions: [
          IconButton(
            tooltip: 'Refresh inbox',
            onPressed: _loading ? null : () => unawaited(_load()),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
          children: [
            const Text(
              'SYSTEM ACTIVITY',
              style: TextStyle(
                color: Color(0xFFC792F8),
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 10),
            if (policyPending || policyLimited) ...[
              Card(
                color: const Color(0xFF2B1B39),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        policyLimited
                            ? 'Policy access restricted'
                            : 'Policy response needed',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        policyLimited
                            ? 'Your account has limited feature access. '
                                'Review the agreement or contact support.'
                            : 'Review the current Fameverse agreement. '
                                'Your access depends on the server policy.',
                        style: const TextStyle(color: Color(0xFFE4D9EB)),
                      ),
                      if (widget.onReviewPolicy != null) ...[
                        const SizedBox(height: 8),
                        TextButton(
                          key: const Key('inbox-policy-review'),
                          onPressed: widget.onReviewPolicy,
                          child: const Text('Review agreement'),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
            if (_loading)
              const LinearProgressIndicator(
                key: Key('inbox-loading-indicator'),
              )
            else if (_error != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_error!, key: const Key('inbox-error')),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () => unawaited(_load()),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              )
            else if (_notices.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 18),
                child: Text(
                  'No published system updates right now.',
                  key: Key('inbox-empty-state'),
                  style: TextStyle(color: Color(0xFFC6B7D0)),
                ),
              )
            else
              ..._notices.map(
                (notice) => Card(
                  key: ValueKey('inbox-notice-' + notice.id),
                  color: const Color(0xFF221B2C),
                  child: Padding(
                    padding: const EdgeInsets.all(15),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          notice.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        if (notice.summary.isNotEmpty) ...[
                          const SizedBox(height: 7),
                          Text(
                            notice.summary,
                            style: const TextStyle(
                              color: Color(0xFFE0D4E7),
                            ),
                          ),
                        ],
                        if (notice.versionLabel != null) ...[
                          const SizedBox(height: 7),
                          Text(
                            notice.versionLabel!,
                            style: const TextStyle(
                              color: Color(0xFFBD93D8),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 20),
            const Divider(),
            const ListTile(
              title: Text('Messages'),
              subtitle: Text(
                'Direct messaging is not available in this version.',
              ),
              leading: Icon(Icons.chat_bubble_outline_rounded),
            ),
            if (widget.onOpenPolicies != null)
              TextButton.icon(
                onPressed: widget.onOpenPolicies,
                icon: const Icon(Icons.policy_outlined),
                label: const Text('Read Fameverse policies'),
              ),
          ],
        ),
      ),
    );
  }
}

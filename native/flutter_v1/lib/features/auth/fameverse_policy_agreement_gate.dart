import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Authenticated, versioned policy acknowledgment. Enabled only after approved
/// server migration and publication; never infer agreement from local storage.
class FameversePolicyAgreementGate extends StatefulWidget {
  const FameversePolicyAgreementGate({
    required this.userId,
    required this.child,
    super.key,
  });

  final String userId;
  final Widget child;

  @override
  State<FameversePolicyAgreementGate> createState() =>
      _FameversePolicyAgreementGateState();
}

class _FameversePolicyAgreementGateState
    extends State<FameversePolicyAgreementGate> {
  Map<String, dynamic>? _policy;
  bool _loading = true;
  bool _checked = false;
  bool _saving = false;
  bool _accepted = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) setState(() { _loading = true; _error = null; });
    try {
      final result = await Supabase.instance.client
          .rpc('fv_get_policy_requirement');
      if (result is! Map) throw StateError('Invalid policy response');
      final record = Map<String, dynamic>.from(result);
      if ((record['version'] as String?)?.isEmpty ?? true) {
        throw StateError('Missing current policy version');
      }
      if (!mounted) return;
      setState(() {
        _policy = record;
        _accepted = record['accepted'] == true;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Could not verify the current Fameverse policies. '
            'Please retry; no agreement has been recorded.';
      });
    }
  }

  Future<void> _accept() async {
    if (!_checked || _saving || _policy == null) return;
    setState(() { _saving = true; _error = null; });
    try {
      final result = await Supabase.instance.client
          .rpc('fv_accept_current_policy');
      if (result is! Map || result['accepted'] != true ||
          result['version'] != _policy!['version']) {
        throw StateError('Policy version changed before confirmation');
      }
      // Verify the authenticated acceptance is actually present server-side.
      final recheck = await Supabase.instance.client
          .rpc('fv_get_policy_requirement');
      if (recheck is! Map || recheck['accepted'] != true ||
          recheck['version'] != _policy!['version']) {
        throw StateError('Policy acceptance not confirmed');
      }
      if (mounted) setState(() => _accepted = true);
    } catch (_) {
      if (mounted) setState(() {
        _error = 'Agreement could not be saved. Retry to continue.';
        _checked = false;
      });
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_accepted) return widget.child;
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    final documents = <(String, String)>[
      ('Terms of Service', _policy?['terms']?.toString() ?? ''),
      ('Community Standards', _policy?['community']?.toString() ?? ''),
      ('Financial Protection', _policy?['financial']?.toString() ?? ''),
      ('Privacy Notice', _policy?['privacy']?.toString() ?? ''),
    ];
    return Scaffold(
      key: const Key('fameverse-policy-agreement-gate'),
      appBar: AppBar(title: const Text('Fameverse policies')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Icon(Icons.shield_rounded, size: 45),
            const SizedBox(height: 14),
            const Text('Review before continuing',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Policy version: ${_policy?['version'] ?? 'Unavailable'}'),
            const SizedBox(height: 12),
            const Text('Up to two accounts per person. Fraudulent purchases, '
                'deliberate chargeback or refund abuse, gift manipulation '
                'and payout fraud are prohibited. Good-faith refunds and '
                'billing disputes remain protected.'),
            const SizedBox(height: 12),
            ...documents.map((entry) => ExpansionTile(
              title: Text(entry.$1),
              children: [Padding(
                padding: const EdgeInsets.all(14),
                child: SelectableText(entry.$2),
              )],
            )),
            const SizedBox(height: 16),
            CheckboxListTile(
              key: const Key('policy-consent-checkbox'),
              value: _checked,
              onChanged: _saving
                  ? null
                  : (value) => setState(() => _checked = value == true),
              controlAffinity: ListTileControlAffinity.leading,
              title: const Text('I have read and agree to the Terms of '
                  'Service, Community Standards, and Financial Protection '
                  'Policy, and acknowledge the Privacy Notice.'),
            ),
            if (_error != null) ...[
              Text(_error!, style: const TextStyle(color: Colors.orangeAccent)),
              TextButton(onPressed: _load, child: const Text('Retry check')),
            ],
            FilledButton(
              key: const Key('policy-accept-continue'),
              onPressed: _checked && !_saving && _policy != null
                  ? _accept : null,
              child: Text(_saving ? 'Saving…' : 'Accept & continue'),
            ),
            TextButton(
              onPressed: () => Supabase.instance.client.auth.signOut(),
              child: const Text('Sign out'),
            ),
          ],
        ),
      ),
    );
  }
}

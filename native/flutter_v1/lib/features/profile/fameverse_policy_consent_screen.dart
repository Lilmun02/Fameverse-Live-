import 'package:flutter/material.dart';

import '../../data/fv_policy_acceptance_service.dart';
import 'fameverse_policy_screen.dart';

/// Shown after the startup/update notice before unrestricted app access.
/// Acceptance is not assumed from local preferences or from dismissing this UI.
class FameversePolicyConsentScreen extends StatefulWidget {
  const FameversePolicyConsentScreen({
    required this.onAccept,
    required this.onDecline,
    required this.onBrowseRestricted,
    required this.busy,
    this.error,
    super.key,
  });

  final VoidCallback onAccept;
  final VoidCallback onDecline;
  final VoidCallback onBrowseRestricted;
  final bool busy;
  final String? error;

  @override
  State<FameversePolicyConsentScreen> createState() =>
      _FameversePolicyConsentScreenState();
}

class _FameversePolicyConsentScreenState
    extends State<FameversePolicyConsentScreen> {
  bool _readAndAgree = false;

  void _openFullPolicies() {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (context) => const FameversePolicyScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('build47-policy-consent-screen'),
      backgroundColor: const Color(0xFF0C0810),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 26, 22, 32),
          children: [
            const Icon(
              Icons.gavel_rounded,
              size: 45,
              color: Color(0xFFD29BFF),
            ),
            const SizedBox(height: 20),
            const Text(
              'Fameverse policy update',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 25, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            const Text(
              'Review the agreement before using restricted Fameverse features.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFFC5B5CE)),
            ),
            const SizedBox(height: 14),
            const Text(
              'Policy version: ${FvPolicyAcceptanceService.requiredPolicyVersion}',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFFA99AAF), fontSize: 12),
            ),
            const SizedBox(height: 22),
            const Text(
              'The rules cover live content, conduct, gifts, purchases, fraud '
              'investigations, account restrictions, and creator payouts. '
              'Please read the full terms before accepting.',
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              key: const Key('build47-read-full-policy'),
              onPressed: widget.busy ? null : _openFullPolicies,
              icon: const Icon(Icons.article_outlined),
              label: const Text('Read terms and community rules'),
            ),
            const SizedBox(height: 12),
            CheckboxListTile(
              key: const Key('build47-policy-checkbox'),
              contentPadding: EdgeInsets.zero,
              value: _readAndAgree,
              onChanged: widget.busy
                  ? null
                  : (value) {
                      setState(() => _readAndAgree = value == true);
                    },
              title: const Text('I have read and agree to these policies'),
              controlAffinity: ListTileControlAffinity.leading,
            ),
            if (widget.error != null && widget.error!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                widget.error!,
                key: const Key('build47-policy-save-error'),
                style: const TextStyle(color: Color(0xFFFF8B9D)),
              ),
            ],
            const SizedBox(height: 12),
            FilledButton(
              key: const Key('build47-accept-policy'),
              onPressed: _readAndAgree && !widget.busy
                  ? widget.onAccept
                  : null,
              child: Text(
                widget.busy ? 'Saving decision…' : 'Accept and continue',
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              key: const Key('build47-decline-policy'),
              onPressed: widget.busy ? null : widget.onDecline,
              child: const Text('Decline agreement'),
            ),
            const SizedBox(height: 8),
            TextButton(
              key: const Key('build47-limited-browsing'),
              onPressed: widget.busy ? null : widget.onBrowseRestricted,
              child: const Text('Browse with restricted access'),
            ),
            const SizedBox(height: 12),
            const Text(
              'Without verified acceptance you may still browse, search, '
              'watch lives, view profiles, and contact support. Going live, '
              'coin purchases, beta badges, and badge transfers remain '
              'restricted. A failed save does not count as acceptance.',
              style: TextStyle(color: Color(0xFFB2A5BB), fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

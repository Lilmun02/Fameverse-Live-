import 'package:flutter/material.dart';

import '../../data/fv_policy_access.dart';
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
    required this.access,
    this.error,
    super.key,
  });

  final VoidCallback onAccept;
  final VoidCallback onDecline;
  final VoidCallback onBrowseRestricted;
  final bool busy;
  final FvPolicyAccess access;
  final String? error;

  @override
  State<FameversePolicyConsentScreen> createState() =>
      _FameversePolicyConsentScreenState();
}

class _FameversePolicyConsentScreenState
    extends State<FameversePolicyConsentScreen> {
  bool _readAndAgree = false;

  String _displayDate(DateTime? date) {
    if (date == null) return 'pending server verification';
    final local = date.toLocal();
    return '${local.month}/${local.day}/${local.year}';
  }

  String get _phaseMessage {
    final access = widget.access;
    if (access.requiresSupport) {
      return 'Your 7-day notice and 3-day grace period have expired. '
          'Restricted features stay unavailable until you contact '
          'Fameverse support Monday–Friday.';
    }
    if (access.isGracePeriod) {
      return 'You are in the 3-day grace period. Sign by '
          '${_displayDate(access.noticeEndsAt)} to avoid restrictions.';
    }
    if (access.withinNoticeWindow) {
      return 'You have 7 days of notice followed by 3 days of grace. '
          'Your deadline is ${_displayDate(access.noticeEndsAt)}. '
          'You can continue using Fameverse during this period.';
    }
    return 'Your account policy status could not be verified. '
        'Restricted features are temporarily unavailable.';
  }

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
              'Please review and sign the policy within the 10-day notice window.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFFC5B5CE)),
            ),
            const SizedBox(height: 14),
            const Text(
              'Policy version: ${FvPolicyAcceptanceService.requiredPolicyVersion}',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFFA99AAF), fontSize: 12),
            ),
            const SizedBox(height: 18),
            Text(
              _phaseMessage,
              key: const Key('build47-policy-deadline-message'),
              style: const TextStyle(color: Color(0xFFE2C5F6)),
              textAlign: TextAlign.center,
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
              onPressed: _readAndAgree && !widget.busy &&
                      !widget.access.requiresSupport &&
                      widget.access.verifiedForAccount
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
              child: Text(
                widget.access.withinNoticeWindow
                    ? 'Continue during notice period'
                    : 'Browse with restricted access',
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'During the first 7 days and 3-day grace, unsigned accounts '
              'retain temporary access. Explicitly declining immediately '
              'restricts Go Live, purchases, beta badges and badge transfers. '
              'After 10 days, unsigned accounts lose those features until '
              'reviewed by support Monday–Friday. Browsing, profiles, '
              'watching lives, search and support remain available. '
              'A failed save never counts as acceptance.',
              style: TextStyle(color: Color(0xFFB2A5BB), fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

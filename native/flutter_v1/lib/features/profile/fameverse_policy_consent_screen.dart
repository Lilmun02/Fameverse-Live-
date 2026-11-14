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
          'Fameverse support Monday–F
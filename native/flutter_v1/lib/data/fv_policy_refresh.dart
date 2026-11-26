import 'fv_policy_access.dart';

/// Pure, account-scoped reconciliation of a server policy refresh.
///
/// This controls whether the policy prompt interrupts basic browsing; it never
/// persists consent, issues tokens or grants restricted feature authorization.
/// Every failed/unverifiable lookup produces an unavailable access object.
class FvPolicyRefreshState {
  const FvPolicyRefreshState({
    required this.access,
    required this.promptDismissed,
    this.acceptedBeforeRefreshFailure = false,
  });

  final FvPolicyAccess access;
  final bool promptDismissed;
  final bool acceptedBeforeRefreshFailure;
}

FvPolicyRefreshState reconcilePolicyRefresh({
  required String accountId,
  required String policyVersion,
  required FvPolicyRefreshState previous,
  required FvPolicyAccess incoming,
}) {
  final samePreviousAccount =
      accountId.isNotEmpty &&
      policyVersion.isNotEmpty &&
      previous.access.accountId == accountId &&
      previous.access.policyVersion == policyVersion;

  final verifiedForCurrentAccount =
      accountId.isNotEmpty &&
      policyVersion.isNotEmpty &&
      incoming.verifiedForAccount &&
      incoming.accountId == accountId &&
      incoming.policyVersion == policyVersion &&
      incoming.decision != FvPolicyDecision.unavailable;

  if (!verifiedForCurrentAccount) {
    final previouslyAccepted =
        samePreviousAccount && previous.access.hasAccepted;
    return FvPolicyRefreshState(
      access: FvPolicyAccess(
        accountId: accountId,
        policyVersion: policyVersion,
        decision: FvPolicyDecision.unavailable,
        verifiedForAccount: false,
      ),
      // Dismiss only when this session has a verified reason to keep
      // browsing; never grant restricted capabilities from that history.
      promptDismissed:
          (samePreviousAccount && previous.promptDismissed) ||
          previouslyAccepted,
      acceptedBeforeRefreshFailure:
          (samePreviousAccount && previous.acceptedBeforeRefreshFailure) ||
          previouslyAccepted,
    );
  }

  // A fresh, account-bound server result is authoritative for the next route.
  // A decline permits limited browsing. A revoked/unsigned agreement does not
  // inherit dismissal of a previously accepted version.
  final dismissed = switch (incoming.decision) {
    FvPolicyDecision.accepted => false,
    FvPolicyDecision.declined => !incoming.requiresSupport,
    FvPolicyDecision.unsigned =>
      !incoming.requiresSupport &&
          samePreviousAccount &&
          previous.access.decision == FvPolicyDecision.unsigned &&
          previous.promptDismissed &&
          !previous.acceptedBeforeRefreshFailure,
    FvPolicyDecision.unavailable => false,
  };

  return FvPolicyRefreshState(
    access: incoming,
    promptDismissed: dismissed,
    acceptedBeforeRefreshFailure: false,
  );
}

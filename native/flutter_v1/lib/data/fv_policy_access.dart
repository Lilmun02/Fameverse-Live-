/// Fameverse policy-access decision rules.
///
/// This file deliberately has no local persistence or client-side authority.
/// A verified, account-bound server decision must be supplied by the caller.
enum FvPolicyDecision { accepted, declined, unsigned, unavailable }

enum FvPolicyFeature {
  watchLive,
  viewProfiles,
  search,
  inbox,
  support,
  goLive,
  purchaseCoins,
  betaBadges,
  bringYourBadge,
}

class FvPolicyAccess {
  const FvPolicyAccess({
    required this.accountId,
    required this.policyVersion,
    required this.decision,
    required this.verifiedForAccount,
  });

  final String accountId;
  final String policyVersion;
  final FvPolicyDecision decision;

  /// True only after backend verification for the signed-in account and
  /// required policy version. Never derive this from device preferences.
  final bool verifiedForAccount;

  bool get hasAccepted =>
      verifiedForAccount &&
      accountId.isNotEmpty &&
      policyVersion.isNotEmpty &&
      decision == FvPolicyDecision.accepted;

  bool permits(FvPolicyFeature feature) {
    switch (feature) {
      case FvPolicyFeature.watchLive:
      case FvPolicyFeature.viewProfiles:
      case FvPolicyFeature.search:
      case FvPolicyFeature.inbox:
      case FvPolicyFeature.support:
        return true;
      case FvPolicyFeature.goLive:
      case FvPolicyFeature.purchaseCoins:
      case FvPolicyFeature.betaBadges:
      case FvPolicyFeature.bringYourBadge:
        return hasAccepted;
    }
  }
}

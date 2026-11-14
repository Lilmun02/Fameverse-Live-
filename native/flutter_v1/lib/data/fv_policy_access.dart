/// Fameverse policy-access decisions: an authenticated, server-computed
/// 7-day notice followed by 3-day grace. No client-side timer grants rights.
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
    this.withinNoticeWindow = false,
    this.isGracePeriod = false,
    this.requiresSupport = false,
    this.noticeStartedAt,
    this.graceStartsAt,
    this.noticeEndsAt,
  });

  final String accountId;
  final String policyVersion;
  final FvPolicyDecision decision;

  /// Only true after server verification of the authenticated account.
  final bool verifiedForAccount;

  /// Calculated by the database server, never by the phone clock.
  final bool withinNoticeWindow;
  final bool isGracePeriod;
  final bool requiresSupport;
  final DateTime? noticeStartedAt;
  final DateTime? graceStartsAt;
  final DateTime? noticeEndsAt;

  bool get hasAccepted =>
      verifiedForAccount &&
      accountId.isNotEmpty &&
      policyVersion.isNotEmpty &&
      decision == FvPolicyDecision.accepted;

  bool get hasTemporaryAccess =>
      verifiedForAccount &&
      accountId.isNotEmpty &&
      policyVersion.isNotEmpty &&
      decision == FvPolicyDecision.unsigned &&
      withinNoticeWindow;

  bool get canUseRestrictedFeatures => hasAccepted || hasTemporaryAccess;

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
        return canUseRestrictedFeatures;
    }
  }
}

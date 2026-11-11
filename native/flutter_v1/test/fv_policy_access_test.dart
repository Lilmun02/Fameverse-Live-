import 'package:flutter_test/flutter_test.dart';
import 'package:fameverse_live/data/fv_policy_access.dart';

void main() {
  const allowed = [
    FvPolicyFeature.watchLive,
    FvPolicyFeature.viewProfiles,
    FvPolicyFeature.search,
    FvPolicyFeature.inbox,
    FvPolicyFeature.support,
  ];
  const restricted = [
    FvPolicyFeature.goLive,
    FvPolicyFeature.purchaseCoins,
    FvPolicyFeature.betaBadges,
    FvPolicyFeature.bringYourBadge,
  ];

  for (final decision in FvPolicyDecision.values) {
    test('nonrestricted features stay available for $decision', () {
      final access = FvPolicyAccess(
        accountId: 'account-1',
        policyVersion: '2026-10',
        decision: decision,
        verifiedForAccount: true,
      );
      for (final feature in allowed) {
        expect(access.permits(feature), isTrue);
      }
    });
  }

  test('restricted features require account-verified acceptance', () {
    for (final decision in FvPolicyDecision.values) {
      for (final verified in [false, true]) {
        final access = FvPolicyAccess(
          accountId: 'account-1',
          policyVersion: '2026-10',
          decision: decision,
          verifiedForAccount: verified,
        );
        for (final feature in restricted) {
          expect(
            access.permits(feature),
            decision == FvPolicyDecision.accepted && verified,
          );
        }
      }
    }
  });

  test('unsigned users retain access during the 7+3-day server window', () {
    const access = FvPolicyAccess(
      accountId: 'account-1',
      policyVersion: '2026-10',
      decision: FvPolicyDecision.unsigned,
      verifiedForAccount: true,
      withinNoticeWindow: true,
    );
    for (final feature in restricted) {
      expect(access.permits(feature), isTrue);
    }
  });

  test('grace period ends without accepting or resetting the notice', () {
    const grace = FvPolicyAccess(
      accountId: 'account-1',
      policyVersion: '2026-10',
      decision: FvPolicyDecision.unsigned,
      verifiedForAccount: true,
      withinNoticeWindow: true,
      isGracePeriod: true,
    );
    const expired = FvPolicyAccess(
      accountId: 'account-1',
      policyVersion: '2026-10',
      decision: FvPolicyDecision.unsigned,
      verifiedForAccount: true,
      requiresSupport: true,
    );
    const declined = FvPolicyAccess(
      accountId: 'account-1',
      policyVersion: '2026-10',
      decision: FvPolicyDecision.declined,
      verifiedForAccount: true,
      withinNoticeWindow: true,
    );
    for (final feature in restricted) {
      expect(grace.permits(feature), isTrue);
      expect(expired.permits(feature), isFalse);
      expect(declined.permits(feature), isFalse);
    }
  });

  test('missing account or policy version fails closed', () {
    for (final access in [
      const FvPolicyAccess(
        accountId: '',
        policyVersion: '2026-10',
        decision: FvPolicyDecision.accepted,
        verifiedForAccount: true,
      ),
      const FvPolicyAccess(
        accountId: 'account-1',
        policyVersion: '',
        decision: FvPolicyDecision.accepted,
        verifiedForAccount: true,
      ),
    ]) {
      for (final feature in restricted) {
        expect(access.permits(feature), isFalse);
      }
    }
  });
}

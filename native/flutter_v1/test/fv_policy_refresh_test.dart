import 'package:flutter_test/flutter_test.dart';
import 'package:fameverse_live/data/fv_policy_access.dart';
import 'package:fameverse_live/data/fv_policy_acceptance_service.dart';
import 'package:fameverse_live/data/fv_policy_refresh.dart';

void main() {
  test('stored acceptance is read without a notice write', () async {
    final row = {'decision': 'accepted'};
    var writes = 0;
    final result = await readOrStartPolicyNotice(
      read: () async => [row],
      startNotice: () async {
        writes++;
      },
      isCurrentAccount: () => true,
    );
    expect(result, [row]);
    expect(writes, 0);
  });

  test('only a confirmed empty response starts a notice', () async {
    var reads = 0;
    var writes = 0;
    final row = {'decision': 'unsigned'};
    final result = await readOrStartPolicyNotice(
      read: () async => ++reads == 1 ? [] : [row],
      startNotice: () async {
        writes++;
      },
      isCurrentAccount: () => true,
    );
    expect(result, [row]);
    expect(reads, 2);
    expect(writes, 1);
  });

  test('failed lookup cannot start or reset a notice', () async {
    var writes = 0;
    await expectLater(
      readOrStartPolicyNotice(
        read: () async => throw StateError('offline'),
        startNotice: () async {
          writes++;
        },
        isCurrentAccount: () => true,
      ),
      throwsStateError,
    );
    expect(writes, 0);
  });

  test('malformed response does not start a notice', () async {
    var writes = 0;
    final result = await readOrStartPolicyNotice(
      read: () async => null,
      startNotice: () async {
        writes++;
      },
      isCurrentAccount: () => true,
    );
    expect(result, isNull);
    expect(writes, 0);
  });

  test('account switch before notice creation prevents a write', () async {
    var writes = 0;
    await expectLater(
      readOrStartPolicyNotice(
        read: () async => [],
        startNotice: () async {
          writes++;
        },
        isCurrentAccount: () => false,
      ),
      throwsStateError,
    );
    expect(writes, 0);
  });

  const accepted = FvPolicyAccess(
    accountId: 'account-a',
    policyVersion: '2026-10',
    decision: FvPolicyDecision.accepted,
    verifiedForAccount: true,
  );
  const unavailable = FvPolicyAccess(
    accountId: 'account-a',
    policyVersion: '2026-10',
    decision: FvPolicyDecision.unavailable,
    verifiedForAccount: false,
  );

  FvPolicyRefreshState refresh(
    FvPolicyRefreshState previous,
    FvPolicyAccess incoming, {
    String accountId = 'account-a',
  }) => reconcilePolicyRefresh(
    accountId: accountId,
    policyVersion: '2026-10',
    previous: previous,
    incoming: incoming,
  );

  test(
    'offline refresh retains browsing but immediately revokes permissions',
    () {
      final result = refresh(
        const FvPolicyRefreshState(access: accepted, promptDismissed: false),
        unavailable,
      );

      expect(result.promptDismissed, isTrue);
      expect(result.acceptedBeforeRefreshFailure, isTrue);
      expect(result.access.verifiedForAccount, isFalse);
      expect(result.access.decision, FvPolicyDecision.unavailable);
      expect(result.access.permits(FvPolicyFeature.watchLive), isTrue);
      expect(result.access.permits(FvPolicyFeature.goLive), isFalse);
      expect(result.access.permits(FvPolicyFeature.purchaseCoins), isFalse);
      expect(result.access.permits(FvPolicyFeature.betaBadges), isFalse);
    },
  );

  test('cold-start unavailable status never implies consent', () {
    const initial = FvPolicyRefreshState(
      access: unavailable,
      promptDismissed: true,
    );
    final offline = refresh(initial, unavailable);
    expect(offline.promptDismissed, isTrue);
    expect(offline.access.hasAccepted, isFalse);
    expect(offline.access.permits(FvPolicyFeature.goLive), isFalse);
    const unsigned = FvPolicyAccess(
      accountId: 'account-a',
      policyVersion: '2026-10',
      decision: FvPolicyDecision.unsigned,
      verifiedForAccount: true,
    );
    expect(refresh(offline, unsigned).promptDismissed, isFalse);
    expect(refresh(offline, accepted).access.hasAccepted, isTrue);
  });

  test('repeated offline refresh cannot re-prompt or restore access', () {
    final first = refresh(
      const FvPolicyRefreshState(access: accepted, promptDismissed: false),
      unavailable,
    );
    final second = refresh(first, unavailable);

    expect(second.promptDismissed, isTrue);
    expect(second.acceptedBeforeRefreshFailure, isTrue);
    expect(second.access.permits(FvPolicyFeature.goLive), isFalse);
  });

  test(
    'fresh verified acceptance restores permissions without another prompt',
    () {
      final offline = refresh(
        const FvPolicyRefreshState(access: accepted, promptDismissed: false),
        unavailable,
      );
      final recovered = refresh(offline, accepted);

      expect(recovered.access.hasAccepted, isTrue);
      expect(recovered.access.permits(FvPolicyFeature.goLive), isTrue);
      expect(recovered.acceptedBeforeRefreshFailure, isFalse);
      expect(recovered.promptDismissed, isFalse);
    },
  );

  test('verified revoked/unsigned result reopens the agreement', () {
    final offline = refresh(
      const FvPolicyRefreshState(access: accepted, promptDismissed: false),
      unavailable,
    );
    const unsigned = FvPolicyAccess(
      accountId: 'account-a',
      policyVersion: '2026-10',
      decision: FvPolicyDecision.unsigned,
      verifiedForAccount: true,
    );
    final revoked = refresh(offline, unsigned);

    expect(revoked.access.hasAccepted, isFalse);
    expect(revoked.promptDismissed, isFalse);
    expect(revoked.acceptedBeforeRefreshFailure, isFalse);
  });

  test(
    'verified decline stays in limited browsing without claiming consent',
    () {
      final offline = refresh(
        const FvPolicyRefreshState(access: accepted, promptDismissed: false),
        unavailable,
      );
      const declined = FvPolicyAccess(
        accountId: 'account-a',
        policyVersion: '2026-10',
        decision: FvPolicyDecision.declined,
        verifiedForAccount: true,
      );
      final result = refresh(offline, declined);

      expect(result.promptDismissed, isTrue);
      expect(result.access.hasAccepted, isFalse);
      expect(result.access.permits(FvPolicyFeature.goLive), isFalse);
    },
  );

  test('unverified accounts are never treated as previously accepted', () {
    final result = refresh(
      const FvPolicyRefreshState(access: unavailable, promptDismissed: false),
      unavailable,
    );

    expect(result.promptDismissed, isFalse);
    expect(result.acceptedBeforeRefreshFailure, isFalse);
    expect(result.access.permits(FvPolicyFeature.goLive), isFalse);
  });

  test('wrong-account and wrong-policy-version responses fail closed', () {
    const wrongAccount = FvPolicyAccess(
      accountId: 'account-b',
      policyVersion: '2026-10',
      decision: FvPolicyDecision.accepted,
      verifiedForAccount: true,
    );
    const wrongVersion = FvPolicyAccess(
      accountId: 'account-a',
      policyVersion: '2026-09',
      decision: FvPolicyDecision.accepted,
      verifiedForAccount: true,
    );
    for (final incoming in [wrongAccount, wrongVersion]) {
      final result = refresh(
        const FvPolicyRefreshState(access: accepted, promptDismissed: false),
        incoming,
      );

      expect(result.access.hasAccepted, isFalse);
      expect(result.access.permits(FvPolicyFeature.goLive), isFalse);
      expect(result.promptDismissed, isTrue);
    }
  });

  test('accepted status from another identity never establishes dismissal', () {
    final result = refresh(
      const FvPolicyRefreshState(access: accepted, promptDismissed: false),
      const FvPolicyAccess(
        accountId: 'account-b',
        policyVersion: '2026-10',
        decision: FvPolicyDecision.unavailable,
        verifiedForAccount: false,
      ),
      accountId: 'account-b',
    );

    expect(result.access.hasAccepted, isFalse);
    expect(result.acceptedBeforeRefreshFailure, isFalse);
    expect(result.promptDismissed, isFalse);
  });

  test('support-required response keeps the policy gate visible', () {
    final offline = refresh(
      const FvPolicyRefreshState(access: accepted, promptDismissed: false),
      unavailable,
    );
    const expired = FvPolicyAccess(
      accountId: 'account-a',
      policyVersion: '2026-10',
      decision: FvPolicyDecision.unsigned,
      verifiedForAccount: true,
      requiresSupport: true,
    );
    final result = refresh(offline, expired);

    expect(result.access.requiresSupport, isTrue);
    expect(result.promptDismissed, isFalse);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fameverse_live/data/fv_policy_access.dart';
import 'package:fameverse_live/features/profile/fameverse_policy_consent_screen.dart';

void main() {
  Widget screen({
    required VoidCallback onAccept,
    required VoidCallback onDecline,
    bool busy = false,
    FvPolicyAccess access = const FvPolicyAccess(
      accountId: 'test-account',
      policyVersion: '2026-10',
      decision: FvPolicyDecision.unsigned,
      verifiedForAccount: true,
      withinNoticeWindow: true,
    ),
  }) {
    return MaterialApp(
      home: FameversePolicyConsentScreen(
        busy: busy,
        access: access,
        onAccept: onAccept,
        onDecline: onDecline,
        onBrowseRestricted: () {},
      ),
    );
  }

  testWidgets('acceptance requires a deliberately checked agreement', (
    tester,
  ) async {
    var accepts = 0;
    var declines = 0;
    await tester.pumpWidget(
      screen(onAccept: () => accepts++, onDecline: () => declines++),
    );

    final accept = find.byKey(const Key('build47-accept-policy'));
    expect(tester.widget<FilledButton>(accept).onPressed, isNull);

    final checkbox = find.byKey(const Key('build47-policy-checkbox'));
    await tester.ensureVisible(checkbox);
    await tester.tap(checkbox);
    await tester.pump();

    expect(tester.widget<FilledButton>(accept).onPressed, isNotNull);
    await tester.ensureVisible(accept);
    await te
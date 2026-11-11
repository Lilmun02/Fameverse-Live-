import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fameverse_live/features/profile/fameverse_policy_consent_screen.dart';

void main() {
  Widget screen({
    required VoidCallback onAccept,
    required VoidCallback onDecline,
    bool busy = false,
  }) {
    return MaterialApp(
      home: FameversePolicyConsentScreen(
        busy: busy,
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
      screen(
        onAccept: () => accepts++,
        onDecline: () => declines++,
      ),
    );

    final accept = find.byKey(const Key('build47-accept-policy'));
    expect(tester.widget<FilledButton>(accept).onPressed, isNull);

    final checkbox = find.byKey(const Key('build47-policy-checkbox'));
    await tester.ensureVisible(checkbox);
    await tester.tap(checkbox);
    await tester.pump();

    expect(tester.widget<FilledButton>(accept).onPressed, isNotNull);
    await tester.ensureVisible(accept);
    await tester.tap(accept);
    expect(accepts, 1);
    expect(declines, 0);
  });

  testWidgets('decline is not confused with acceptance', (tester) async {
    var accepts = 0;
    var declines = 0;
    await tester.pumpWidget(
      screen(
        onAccept: () => accepts++,
        onDecline: () => declines++,
      ),
    );
    final decline = find.byKey(const Key('build47-decline-policy'));
    await tester.ensureVisible(decline);
    await tester.tap(decline);
    expect(accepts, 0);
    expect(declines, 1);
  });

  testWidgets('busy state disables every decision control', (tester) async {
    await tester.pumpWidget(
      screen(onAccept: () {}, onDecline: () {}, busy: true),
    );
    final accept = find.byKey(const Key('build47-accept-policy'));
    final decline = find.byKey(const Key('build47-decline-policy'));
    final limited = find.byKey(const Key('build47-limited-browsing'));
    expect(tester.widget<FilledButton>(accept).onPressed, isNull);
    expect(tester.widget<OutlinedButton>(decline).onPressed, isNull);
    expect(tester.widget<TextButton>(limited).onPressed, isNull);
  });
}

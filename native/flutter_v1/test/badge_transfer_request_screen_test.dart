import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fameverse_live/features/profile/badge_transfer_request_screen.dart';

void main() {
  testWidgets('valid proof creates pending request', (tester) async {
    String? submittedPlatform;
    int? submittedLevel;
    String? submittedProof;
    await tester.pumpWidget(
      MaterialApp(
        home: BadgeTransferRequestScreen(
          userId: 'tester-1',
          submitRequest: (platform, level, proof) async {
            submittedPlatform = platform;
            submittedLevel = level;
            submittedProof = proof;
          },
        ),
      ),
    );

    await tester.enterText(find.byKey(const Key('badge-transfer-level')), '15');
    await tester.enterText(
      find.byKey(const Key('badge-transfer-proof')),
      'https://example.com/badge-proof',
    );
    await tester.ensureVisible(find.byKey(const Key('badge-transfer-submit')));
    await tester.tap(find.byKey(const Key('badge-transfer-submit')));
    await tester.pumpAndSettle();

    expect(submittedPlatform, 'TikTok');
    expect(submittedLevel, 15);
    expect(submittedProof, 'https://example.com/badge-proof');
    expect(find.byKey(const Key('badge-request-pending')), findsOneWidget);
    expect(find.textContaining('No level was awarded.'), findsOneWidget);
  });

  testWidgets('invalid evidence is rejected', (tester) async {
    var submitted = false;
    await tester.pumpWidget(
      MaterialApp(
        home: BadgeTransferRequestScreen(
          userId: 'tester-1',
          submitRequest: (_, __, ___) async => submitted = true,
        ),
      ),
    );
    await tester.enterText(find.byKey(const Key('badge-transfer-level')), '0');
    await tester.enterText(
      find.byKey(const Key('badge-transfer-proof')),
      'http://example.com',
    );
    await tester.ensureVisible(find.byKey(const Key('badge-transfer-submit')));
    await tester.tap(find.byKey(const Key('badge-transfer-submit')));
    await tester.pumpAndSettle();

    expect(submitted, false);
    expect(find.text('Enter a badge number from 1 to 100.'), findsOneWidget);
    expect(find.text('Enter a valid HTTPS proof link.'), findsOneWidget);
  });

  testWidgets('a failed request never appears submitted', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: BadgeTransferRequestScreen(
          userId: 'tester-1',
          submitRequest: (_, __, ___) async => throw StateError('offline'),
        ),
      ),
    );
    await tester.enterText(find.byKey(const Key('badge-transfer-level')), '38');
    await tester.enterText(
      find.byKey(const Key('badge-transfer-proof')),
      'https://example.com/evidence',
    );
    await tester.ensureVisible(find.byKey(const Key('badge-transfer-submit')));
    await tester.tap(find.byKey(const Key('badge-transfer-submit')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('badge-transfer-error')), findsOneWidget);
    expect(find.byKey(const Key('badge-request-pending')), findsNothing);
  });
}

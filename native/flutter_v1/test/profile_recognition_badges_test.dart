import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fameverse_live/features/profile/profile_recognition_badges.dart';

void main() {
  testWidgets('awarded Verse Pioneer is visible on the profile', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProfileRecognitionBadges(
            userId: 'pioneer-user',
            awardLoader: (id) async => ['verse_pioneer'],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('verse-pioneer-profile-badge')), findsOneWidget);
    expect(find.text('VERSE PIONEER'), findsOneWidget);
  });

  testWidgets('unawarded profiles do not show the Pioneer badge', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProfileRecognitionBadges(
            userId: 'other-user',
            awardLoader: (id) async => const [],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('verse-pioneer-profile-badge')), findsNothing);
  });

  testWidgets('badge fetch failure is visible during QA', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProfileRecognitionBadges(
            userId: 'offline-user',
            awardLoader: (id) async => throw StateError('network unavailable'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Recognition badge unavailable. Pull to refresh.'), findsOneWidget);
  });
}

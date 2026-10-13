import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fameverse_live/features/profile/profile_recognition_badges.dart';

void main() {
  testWidgets('awarded Pioneer is visible', (tester) async {
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

    expect(
      find.byKey(const Key('verse-pioneer-profile-badge')),
      findsOneWidget,
    );
    expect(find.text('VERSE PIONEER'), findsOneWidget);
  });

  testWidgets('unawarded profiles hide Pioneer', (tester) async {
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

    expect(
      find.text('Recognition badge unavailable. Pull to refresh.'),
      findsOneWidget,
    );
  });
  testWidgets('Pioneer badge reloads when profile reopens', (tester) async {
    var loads = 0;
    Future<List<String>> loadAwards(String userId) async {
      loads++;
      return loads == 1 ? const [] : const ['verse_pioneer'];
    }

    Widget page(int refreshToken) => MaterialApp(
      home: Scaffold(
        body: ProfileRecognitionBadges(
          userId: 'pioneer-user',
          refreshToken: refreshToken,
          awardLoader: loadAwards,
        ),
      ),
    );

    await tester.pumpWidget(page(0));
    await tester.pumpAndSettle();
    expect(find.text('VERSE PIONEER'), findsNothing);

    await tester.pumpWidget(page(1));
    await tester.pumpAndSettle();
    expect(loads, 2);
    expect(find.text('VERSE PIONEER'), findsOneWidget);
  });
  testWidgets('stale badge fetch cannot replace a newer refresh', (tester) async {
    final oldFetch = Completer<List<String>>();
    final latestFetch = Completer<List<String>>();
    var requests = 0;

    Future<List<String>> loadAwards(String userId) {
      requests++;
      return requests == 1 ? oldFetch.future : latestFetch.future;
    }

    Widget page(int refreshToken) => MaterialApp(
      home: Scaffold(
        body: ProfileRecognitionBadges(
          userId: 'pioneer-user',
          refreshToken: refreshToken,
          awardLoader: loadAwards,
        ),
      ),
    );

    await tester.pumpWidget(page(0));
    await tester.pump();
    await tester.pumpWidget(page(1));
    await tester.pump();
    expect(requests, 2);

    latestFetch.complete(const ['verse_pioneer']);
    await tester.pumpAndSettle();
    expect(find.text('VERSE PIONEER'), findsOneWidget);

    oldFetch.complete(const []);
    await tester.pumpAndSettle();
    expect(find.text('VERSE PIONEER'), findsOneWidget);
  });

  test('public profile refresh reloads the recognition badge', () async {
    final source = await File(
      'lib/features/profile/fameverse_public_profile_screen.dart',
    ).readAsString();
    expect(source, contains('_recognitionRefreshToken++'));
    expect(source, contains('refreshToken: _recognitionRefreshToken'));
  });

}

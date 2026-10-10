import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fameverse_live/data/fameverse_beta_backend.dart';
import 'package:fameverse_live/features/profile/first_verse_beta_screen.dart';

class _FakeBetaBackend implements FameverseBetaBackend {
  _FakeBetaBackend(this.status);

  final FvBetaProgramStatus status;

  @override
  Future<FvBetaProgramStatus> loadProgramStatus() async => status;

  @override
  Future<void> recordMission(String missionKey) async {}
}

void main() {
  testWidgets('First Verse stays locked until required missions are complete', (
    tester,
  ) async {
    const status = FvBetaProgramStatus(
      enrolled: true,
      memberStatus: 'active',
      completedRequired: 3,
      requiredTotal: 8,
      completedOptional: 0,
      badgeUnlocked: false,
      badgeUnlockedAt: null,
      completedMissionKeys: {
        'complete_profile',
        'browse_home',
        'browse_discover',
      },
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: FirstVerseBetaScreen(backend: _FakeBetaBackend(status)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Your badge is waiting'), findsOneWidget);
    expect(find.text('3/8 required tests'), findsOneWidget);
    expect(find.byIcon(Icons.lock_rounded), findsOneWidget);
  });

  testWidgets('Owner sees unblurred badge art without earning First Verse', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: FirstVerseBetaScreen(
          backend: _FakeBetaBackend(FvBetaProgramStatus.notEnrolled),
          ownerPreview: true,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Owner preview · not yet earned'), findsOneWidget);
    expect(find.byKey(const Key('first-verse-badge-art')), findsOneWidget);
    expect(find.byIcon(Icons.lock_rounded), findsNothing);
    expect(find.text('Build your profile'), findsOneWidget);
  });

  testWidgets('First Verse reveals permanently earned badge state', (
    tester,
  ) async {
    final status = FvBetaProgramStatus(
      enrolled: true,
      memberStatus: 'earned',
      completedRequired: 8,
      requiredTotal: 8,
      completedOptional: 1,
      badgeUnlocked: true,
      badgeUnlockedAt: DateTime.utc(2026, 9, 27),
      completedMissionKeys: const {
        'complete_profile',
        'browse_home',
        'browse_discover',
        'open_public_profile',
        'follow_creator',
        'join_live',
        'send_comment',
        'view_story',
        'cohost_session',
      },
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: FirstVerseBetaScreen(backend: _FakeBetaBackend(status)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('First Verse earned'), findsOneWidget);
    expect(find.text('8/8 required tests'), findsOneWidget);
    expect(find.text('100%'), findsOneWidget);
    expect(find.text('1 bonus check completed'), findsOneWidget);
  });

  test('First Verse required mission list excludes payout operations', () {
    final keys = fvFirstVerseMissions.map((mission) => mission.key).toSet();
    expect(keys, isNot(contains('payout')));
    expect(keys, isNot(contains('request_payout')));
    expect(keys, isNot(contains('approve_payout')));
    expect(keys, contains('browse_discover'));
    expect(fvFirstVerseMissions.where((mission) => mission.required).length, 8);
  });
}

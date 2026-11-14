import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fameverse_live/data/fv_policy_access.dart';
import 'package:fameverse_live/data/fv_system_inbox_repository.dart';
import 'package:fameverse_live/features/profile/fameverse_inbox_screen.dart';

class _StubNotices implements FvSystemInboxRepository {
  _StubNotices(this.data);

  final List<FvSystemNotice> data;
  final List<String> requestedAccounts = [];

  @override
  Future<List<FvSystemNotice>> loadForUser(String userId) async {
    requestedAccounts.add(userId);
    return data;
  }
}

void main() {
  testWidgets('Inbox shows real repository notices and no fake DMs', (
    tester,
  ) async {
    final store = _StubNotices([
      const FvSystemNotice(
        id: 'notice-one',
        title: 'Policy update',
        summary: 'A new policy is available.',
      ),
    ]);
    await tester.pumpWidget(
      MaterialApp(
        home: FameverseInboxScreen(
          userId: 'member-one',
          repository: store,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(store.requestedAccounts, ['member-one']);
    expect(find.text('Inbox'), findsOneWidget);
    expect(find.text('Policy update'), findsOneWidget);
    expect(find.text('A new policy is available.'), findsOneWidget);
    expect(
      find.text('Direct messaging is not available in this version.'),
      findsOneWidget,
    );
  });

  testWidgets('declined accounts can still see policy reminder', (
    tester,
  ) async {
    var reviews = 0;
    final store = _StubNotices([]);
    await tester.pumpWidget(
      MaterialApp(
        home: FameverseInboxScreen(
          userId: 'member-two',
          repository: store,
          policyAccess: const FvPolicyAccess(
            accountId: 'member-two',
            policyVersion: 'v47',
            decision: FvPolicyDecision.declined,
            verifiedForAccount: true,
          ),
          onReviewPolicy: () => reviews++,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Policy access restricted'), findsOneWidget);
    expect(find.text('No published system updates right now.'), findsOneWidget);
    await tester.tap(find.text('Review agreement'));
    expect(reviews, 1);
  });

  testWidgets('inbox never shows another account policy', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: FameverseInboxScreen(
          userId: 'member-B',
          repository: _StubNotices([]),
          policyAccess: const FvPolicyAccess(
            accountId: 'member-A',
            policyVersion: 'v47',
            decision: FvPolicyDecision.declined,
            verifiedForAccount: true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Policy access restricted'), findsNothing);
  });
}

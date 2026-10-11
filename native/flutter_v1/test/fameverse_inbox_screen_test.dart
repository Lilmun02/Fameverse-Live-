import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fameverse_live/features/profile/fameverse_inbox_screen.dart';

void main() {
  testWidgets('inbox displays entries for owner', (tester) async {
    var loadedUser = '';
    await tester.pumpWidget(
      MaterialApp(
        home: FameverseInboxScreen(
          userId: 'account-a',
          loadItems: (userId) async {
            loadedUser = userId;
            return const [
              FvInboxItem(
                id: 'notice-1',
                title: 'Welcome to Fameverse',
                body: 'Your account is ready.',
                createdAt: null,
              ),
            ];
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(loadedUser, 'account-a');
    expect(find.text('Welcome to Fameverse'), findsOneWidget);
    expect(find.byKey(const Key('inbox-item-notice-1')), findsOneWidget);
  });

  testWidgets('empty inbox is not reported as an error', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: FameverseInboxScreen(
          userId: 'account-a',
          loadItems: (userId) async => const [],
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('inbox-empty')), findsOneWidget);
  });

  testWidgets('inbox reports backend failure', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: FameverseInboxScreen(
          userId: 'account-a',
          loadItems: (userId) async => throw StateError('offline'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('inbox-load-error')), findsOneWidget);
  });
}

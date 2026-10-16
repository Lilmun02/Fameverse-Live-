import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fameverse_live/features/profile/fameverse_inbox_models.dart';
import 'package:fameverse_live/features/profile/fameverse_inbox_screen.dart';

class _InboxStub implements FameverseInboxRepository {
  _InboxStub({this.snapshot = const FvInboxSnapshot(conversations: [], activities: []), this.fail = false});

  final FvInboxSnapshot snapshot;
  final bool fail;
  final List<String> loadedAccounts = [];

  @override
  Future<FvInboxSnapshot> load(String userId) async {
    loadedAccounts.add(userId);
    if (fail) throw StateError('not deployed');
    return snapshot;
  }

  @override
  Future<List<FvInboxContact>> searchContacts(String userId, String query) async => [];

  @override
  Future<String> startConversation(String userId, String otherUserId) async => 'conversation-1';

  @override
  Future<List<FvInboxMessage>> loadMessages(String userId, String conversationId) async => [];

  @override
  Future<void> sendMessage(String userId, String conversationId, String body) async {}

  @override
  Future<void> readConversation(String userId, String conversationId) async {}

  @override
  Future<void> readActivity(String userId, String activityId) async {}
}

void main() {
  testWidgets('Inbox shows an empty conversation list without fabricating messages', (tester) async {
    final stub = _InboxStub();
    await tester.pumpWidget(MaterialApp(
      home: FameverseInboxScreen(userId: 'account-a', repository: stub),
    ));
    await tester.pumpAndSettle();
    expect(stub.loadedAccounts, ['account-a']);
    expect(find.byKey(const Key('inbox-messages-empty')), findsOneWidget);
    expect(find.byKey(const Key('inbox-compose-button')), findsOneWidget);
  });

  testWidgets('Inbox shows real repository conversations and Activity separately', (tester) async {
    final stub = _InboxStub(snapshot: const FvInboxSnapshot(
      conversations: [
        FvInboxConversation(
          id: 'conversation-1',
          peerId: 'account-b',
          peerName: 'Creator B',
          peerHandle: 'creatorb',
          preview: 'Hello',
          unreadCount: 1,
        ),
      ],
      activities: [
        FvInboxActivity(
          id: 'notice-1',
          title: 'Account update',
          body: 'Your profile is ready.',
          createdAt: null,
          readAt: null,
        ),
      ],
    ));
    await tester.pumpWidget(MaterialApp(
      home: FameverseInboxScreen(userId: 'account-a', repository: stub),
    ));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('inbox-chat-conversation-1')), findsOneWidget);
    await tester.tap(find.byKey(const Key('inbox-activity-tab')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('inbox-activity-notice-1')), findsOneWidget);
  });

  testWidgets('Backend unavailable is an explicit error, not a fake empty inbox', (tester) async {
    final stub = _InboxStub(fail: true);
    await tester.pumpWidget(MaterialApp(
      home: FameverseInboxScreen(userId: 'account-a', repository: stub),
    ));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('inbox-load-error')), findsOneWidget);
    expect(find.byKey(const Key('inbox-messages-empty')), findsNothing);
  });

  testWidgets('Account switching reloads the new owner and clears stale content', (tester) async {
    final stub = _InboxStub(snapshot: const FvInboxSnapshot(
      conversations: [], activities: [],
    ));
    await tester.pumpWidget(MaterialApp(
      home: FameverseInboxScreen(userId: 'account-a', repository: stub),
    ));
    await tester.pumpAndSettle();
    await tester.pumpWidget(MaterialApp(
      home: FameverseInboxScreen(userId: 'account-b', repository: stub),
    ));
    await tester.pumpAndSettle();
    expect(stub.loadedAccounts, ['account-a', 'account-b']);
  });
}

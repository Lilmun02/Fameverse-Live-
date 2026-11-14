import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Build 47 Inbox is routed to signed-in Profile', () {
    final shell = File(
      'lib/features/shell/fameverse_shell_build23.dart',
    ).readAsStringSync();
    final profile = File(
      'lib/features/profile/native_profile_build23.dart',
    ).readAsStringSync();
    expect(shell, contains('FameverseInboxScreen('));
    expect(shell, contains('userId: widget.identity.id'));
    expect(shell, contains('onOpenInbox: _openInbox'));
    expect(profile, contains("Key('profile-inbox-button')"));
  });

  test('Inbox only reads published notices with account-verified session', () {
    final repo = File(
      'lib/data/fv_system_inbox_repository.dart',
    ).readAsStringSync();
    expect(repo, contains("client.auth.currentUser?.id != userId"));
    expect(repo, contains(".from('app_update_notices')"));
    expect(repo, contains(".eq('active', true)"));
    expect(repo, isNot(contains(".from('direct_messages')")));
    expect(repo, isNot(contains(".insert(")));
    expect(repo, isNot(contains(".update(")));
  });

  test('Inbox does not claim fake private messages or unread counts', () {
    final screen = File(
      'lib/features/profile/fameverse_inbox_screen.dart',
    ).readAsStringSync();
    expect(screen, contains('generation != _generation'));
    expect(screen, contains('verifiedForAccount'));
    expect(screen, contains(
      'Direct messaging is not available in this version.',
    ));
    expect(screen, isNot(contains('fakeMessage')));
    expect(screen, isNot(contains('unreadCount')));
  });
}

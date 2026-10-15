import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Home Live Feed plays real fullscreen video with vertical swipes', () {
    final feed = File(
      'lib/features/shell/fameverse_vertical_live_feed.dart',
    ).readAsStringSync();
    final shell = File(
      'lib/features/shell/fameverse_shell_build23.dart',
    ).readAsStringSync();
    final viewer = File(
      'lib/features/live/stream_viewer_live_screen.dart',
    ).readAsStringSync();

    expect(feed, contains("Key('home-fullscreen-live-feed')"));
    expect(feed, contains("Key('home-live-vertical-swiper')"));
    expect(feed, contains('scrollDirection: Axis.vertical'));
    expect(feed, contains('NativeViewerLiveScreen('));
    expect(feed, contains('onPageChanged: _onPageChanged'));
    expect(feed, contains('onExitFeed: _onLeave'));
    expect(feed, contains('if (index != _activeIndex)'));
    expect(shell, contains('if (_tab == 0 && _rooms.isNotEmpty)'));
    expect(shell, contains('FameverseVerticalLiveFeed('));
    expect(viewer, contains('NativeViewerV2Stage('));
    expect(viewer, contains('widget.onExitFeed!()'));
  });

  test('Discover grid stays separate from actual immersive Live Feed', () {
    final discover = File(
      'lib/features/shell/fameverse_discover_screen.dart',
    ).readAsStringSync();
    final feed = File(
      'lib/features/shell/fameverse_vertical_live_feed.dart',
    ).readAsStringSync();
    expect(discover, contains('GridView.builder('));
    expect(discover, contains('crossAxisCount: 2'));
    expect(feed, isNot(contains('GridView.builder(')));
    expect(feed, contains('onOpenDiscover'));
  });

  test('no false video-preview, viewer-count or demo room data in feed', () {
    final feed = File(
      'lib/features/shell/fameverse_vertical_live_feed.dart',
    ).readAsStringSync();
    expect(feed, isNot(contains('videoUrl')));
    expect(feed, isNot(contains('fakeLive')));
    expect(feed, isNot(contains('viewerCount: 999')));
    expect(feed, contains('room: room'));
  });

  test('Inbox contains messages, activity, composer and search', () {
    final inbox = File(
      'lib/features/profile/fameverse_inbox_screen.dart',
    ).readAsStringSync();
    final chat = File(
      'lib/features/profile/fameverse_chat_screen.dart',
    ).readAsStringSync();
    final composer = File(
      'lib/features/profile/fameverse_compose_message_screen.dart',
    ).readAsStringSync();
    final repository = File(
      'lib/features/profile/fameverse_inbox_repository.dart',
    ).readAsStringSync();

    expect(inbox, contains("label: 'Messages'"));
    expect(inbox, contains("label: 'Activity'"));
    expect(inbox, contains('inbox-compose-button'));
    expect(inbox, contains('conversation.unreadCount'));
    expect(chat, contains("Key('direct-chat-send')"));
    expect(composer, contains("Key('inbox-search-creator')"));
    expect(repository, contains("from('direct_messages')"));
    expect(repository, contains("from('direct_conversations')"));
    expect(repository, contains("from('user_inbox_items')"));
    expect(repository, contains('client.auth.currentUser?.id != userId'));
  });
}

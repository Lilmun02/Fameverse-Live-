import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('host join notices come from Stream roster, not client chat events', () {
    final source = File(
      'lib/features/live/stream_host_live_screen.dart',
    ).readAsStringSync();
    expect(source, contains('call.state.valueStream.listen('));
    expect(source, contains('_onViewerRosterChanged'));
    expect(source, contains('hostUserId: widget.identity.id'));
    expect(source, contains("kind: 'join'"));
    expect(source, contains("text: 'joined the Live'"));
    expect(source, contains('await _viewerJoinSubscription?.cancel();'));
    expect(source, contains('void _showViewerSheet()'));
    expect(source, contains('FvLiveChatList(messages: _chat)'));
    expect(source, isNot(contains("activity.send('viewer-joined'")));
  });
}

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Build 47 keyboard-safe Live chat regression', () {
    for (final filename in [
      'stream_host_live_screen.dart',
      'stream_viewer_live_screen.dart',
    ]) {
      test('$filename resizes chat while a software keyboard is visible', () {
        final source = File('lib/features/live/$filename').readAsStringSync();
        expect(source, contains('resizeToAvoidBottomInset: true'));
        expect(
          source,
          contains('MediaQuery.viewInsetsOf(context).bottom > 0'),
        );
        expect(source, contains('if (!keyboardVisible) ...['));
        expect(source, contains('if (keyboardVisible)'));
        expect(source, contains('Expanded('));
        expect(source, contains('FvLiveChatList(messages: _chat)'));
        expect(source, contains('FvLiveCommentComposer('));
      });
    }
  });
}

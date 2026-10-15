import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('host and viewer bound comment and gift chat memory at 200', () {
    for (final path in [
      'lib/features/live/stream_host_live_screen.dart',
      'lib/features/live/stream_viewer_live_screen.dart',
    ]) {
      final source = File(path).readAsStringSync();
      expect(source, contains('void _appendChat(FvLiveChatMessage message)'));
      expect(source, contains('if (_chat.length > 200)'));
      expect(source, contains('_chat.removeRange(0, _chat.length - 200)'));
      expect(source, contains('_appendChat('));
    }
  });
}

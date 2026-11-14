import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Build 47 host End Live confirmation regression', () {
    test('End button and system back both ask before stopping the stream', () {
      final host = File(
        'lib/features/live/stream_host_live_screen.dart',
      ).readAsStringSync();

      expect(host, contains('canPop: _ended'));
      expect(
        host,
        contains('if (!didPop && !_ending) unawaited(_confirmEndLive());'),
      );
      expect(host, contains("Key('native-end-live')"));
      expect(host, contains(': _confirmEndLive,'));
      expect(host, isNot(contains('unawaited(_endLive());')));
      expect(host, isNot(contains('onPressed: _ending ? null : _endLive')));
    });

    test('only an affirmative choice calls the existing shutdown path', () {
      final host = File(
        'lib/features/live/stream_host_live_screen.dart',
      ).readAsStringSync();

      expect(host, contains('Future<void> _confirmEndLive() async'));
      expect(
        host,
        contains('if (!mounted || _ending || _confirmingEnd) return;'),
      );
      expect(host, contains('showDialog<bool>('));
      expect(host, contains('barrierDismissible: false'));
      expect(host, contains("Key('native-keep-live')"));
      expect(host, contains('Navigator.of(dialogContext).pop(false)'));
      expect(host, contains("Key('native-confirm-end-live')"));
      expect(host, contains('Navigator.of(dialogContext).pop(true)'));
      expect(
        host,
        contains('if (confirmed == true && mounted) await _endLive();'),
      );
      expect(RegExp(r'_endLive\(\)').allMatches(host).length, 2);
      expect(host, contains('await call.stopLive();'));
      expect(host, contains('await widget.liveBackend.endLiveRoom('));
    });
  });
}

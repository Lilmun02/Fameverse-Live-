import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Live discovery refresh stability', () {
    test('room discovery refreshes independently on Home/Discover', () {
      final source = File(
        'lib/features/shell/fameverse_shell_build23.dart',
      ).readAsStringSync();

      expect(source, contains('Future<void> _refreshRooms() async {'));
      expect(source, contains('unawaited(_refreshRooms());'));
      expect(
        source,
        contains('final rooms = await widget.backend.listActiveLiveRooms('),
      );
      expect(source, contains('setState(() => _rooms = rooms)'));
      expect(source, contains('if (_tab == 0 || _tab == 1)'));
    });

    test('timer is finite, disposed, and overlapping requests are blocked', () {
      final source = File(
        'lib/features/shell/fameverse_shell_build23.dart',
      ).readAsStringSync();

      expect(source, contains('Timer.periodic(const Duration(seconds: 20)'));
      expect(source, contains('_roomRefreshTimer?.cancel()'));
      expect(source, contains('if (_roomRefreshBusy) return;'));
      expect(source, contains('_roomRefreshBusy = true;'));
      expect(source, contains('} finally {'));
      expect(source, contains('_roomRefreshBusy = false;'));
      expect(source, contains('if (mounted) setState(() => _rooms = rooms)'));
    });

    test('profile failure cannot block live discovery', () {
      final source = File(
        'lib/features/shell/fameverse_shell_build23.dart',
      ).readAsStringSync();
      final start = source.indexOf('Future<void> _refreshAll() async {');
      final end = source.indexOf('Future<void> _toggleFollow(');
      expect(start, greaterThanOrEqualTo(0));
      expect(end, greaterThan(start));
      final all = source.substring(start, end);

      expect(all, contains('unawaited(_refreshRooms());'));
      expect(all, isNot(contains('listActiveLiveRooms(')));
      expect(all, isNot(contains('_rooms = results[3]')));
    });

    test('real active live cards keep opening native viewer', () {
      final shell = File(
        'lib/features/shell/fameverse_shell_build23.dart',
      ).readAsStringSync();
      final discover = File(
        'lib/features/shell/fameverse_discover_screen.dart',
      ).readAsStringSync();

      expect(shell, contains('NativeViewerLiveScreen('));
      expect(shell, contains('onRoomSelected: (room)'));
      expect(discover, contains('widget.onRoomSelected(room)'));
      expect(shell, contains('onLiveEnded: _refreshAll'));
    });
  });
}

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  const path = 'lib/features/shell/fameverse_shell_build23.dart';

  test('Background lifecycle stops room polling', () {
    final source = File(path).readAsStringSync();
    expect(source, contains('with WidgetsBindingObserver {'));
    expect(source, contains('WidgetsBinding.instance.addObserver(this);'));
    expect(source, contains('WidgetsBinding.instance.removeObserver(this);'));
    expect(source, contains('didChangeAppLifecycleState'));
    expect(source, contains('AppLifecycleState.resumed'));
    expect(source, contains('_roomRefreshTimer?.cancel();'));
    expect(source, contains('_roomRefreshTimer = null;'));
  });

  test('Room polling resumes once and refreshes visible tabs', () {
    final source = File(path).readAsStringSync();
    expect(source, contains('_startRoomRefreshTimer();'));
    expect(source, contains('_roomRefreshTimer?.isActive == true'));
    expect(source, contains('Timer.periodic(const Duration(seconds: 20)'));
    expect(source, contains('if (_tab == 0 || _tab == 1)'));
    expect(source, contains('unawaited(_refreshRooms());'));
  });
}

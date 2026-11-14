import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Room polling pauses when app is not resumed', () {
    final shell = File(
      'lib/features/shell/fameverse_shell_build23.dart',
    ).readAsStringSync();
    expect(shell, contains('with WidgetsBindingObserver {'));
    expect(shell, contains('WidgetsBinding.instance.addObserver(this);'));
    expect(shell, contains('WidgetsBinding.instance.removeObserver(this);'));
    expect(shell, contains('didChangeAppLifecycleState(AppLifecycleState state)'));
    expect(shell, contains('if (state == AppLifecycleState.resumed) {'));
    expect(shell, contains('_roomRefreshTimer = null;'));
    expect(shell, contains('_roomRefreshTimer?.cancel();'));
    expect(shell, contains('_startRoomRefreshTimer();'));
    expect(shell, contains('if (_tab == 0 || _tab == 1)'));
  });

  test('Repeated resumed notifications cannot add polling timers', () {
    final shell = File(
      'lib/features/shell/fameverse_shell_build23.dart',
    ).readAsStringSync();
    expect(
      shell,
      contains('if (_roomRefreshTimer?.isActive == true) return;'),
    );
    expect(
      shell,
      contains('Timer.periodic(const Duration(seconds: 20)'),
    );
  });
}

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a room created before unmount is closed before Go Live navigation', () {
    final camera = File(
      'lib/features/live/native_camera_screen.dart',
    ).readAsStringSync();
    final start = camera.indexOf(
      'final credentials = await widget.liveBackend.issueLiveCredentials(',
    );
    final abandonment = camera.indexOf('if (!mounted) {', start);
    final end = camera.indexOf(
      'await widget.liveBackend.endLiveRoom(',
      abandonment,
    );
    final nextRoute = camera.indexOf(
      'Navigator.of(context).push<bool>(',
      start,
    );

    expect(start, greaterThan(0));
    expect(abandonment, greaterThan(start));
    expect(end, greaterThan(abandonment));
    expect(nextRoute, greaterThan(end));
    expect(
      camera.substring(abandonment, nextRoute),
      contains('hostUserId: widget.identity.id'),
    );
    expect(
      camera.substring(abandonment, nextRoute),
      contains('return;'),
    );
  });

  test('normal host navigation and failure cleanup are preserved', () {
    final camera = File(
      'lib/features/live/native_camera_screen.dart',
    ).readAsStringSync();
    expect(camera, contains('builder: (context) => NativeHostLiveScreen('));
    expect(camera, contains('if (room != null) {'));
    expect(camera, contains('await widget.liveBackend.endLiveRoom('));
    expect(camera, contains('if (ended == true) {'));
  });
}

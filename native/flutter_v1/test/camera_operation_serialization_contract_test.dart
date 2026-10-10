import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

String _method(String source, String signature, String followingSignature) {
  final start = source.indexOf(signature);
  if (start < 0) throw StateError('Missing camera method: $signature');
  final end = source.indexOf(followingSignature, start + signature.length);
  if (end < 0) throw StateError('Missing next method: $followingSignature');
  return source.substring(start, end);
}

void _expectSerializedCameraPower(
  String method, {
  required String guard,
  required String busyFlag,
  required String sdkCall,
}) {
  expect(method, contains(guard));

  final acquired = method.indexOf('setState(() => $busyFlag = true)');
  final call = method.indexOf(sdkCall);
  final released = method.indexOf('setState(() => $busyFlag = false)');

  expect(acquired, greaterThanOrEqualTo(0));
  expect(call, greaterThan(acquired));
  expect(released, greaterThan(call));
  expect(method, contains('} finally {'));
}

void main() {
  test('host camera power shares the flip-operation lock', () {
    final host = File(
      'lib/features/live/stream_host_live_screen.dart',
    ).readAsStringSync();
    final cameraPower = _method(
      host,
      'Future<void> _toggleCamera() async {',
      'Future<void> _handleCohostEvent(',
    );

    _expectSerializedCameraPower(
      cameraPower,
      guard: '_connecting || _ending || _flipCameraBusy',
      busyFlag: '_flipCameraBusy',
      sdkCall: 'await call.setCameraEnabled(enabled: next)',
    );

    expect(host, contains('bool _flipCameraBusy = false;'));
    expect(host, contains('onPressed: !_flipCameraBusy'));
  });

  test('cohost camera power shares the cohost flip-operation lock', () {
    final viewer = File(
      'lib/features/live/stream_viewer_live_screen.dart',
    ).readAsStringSync();
    final cameraPower = _method(
      viewer,
      'Future<void> _toggleCohostCamera() async {',
      'Future<void> _shareLive() async {',
    );

    _expectSerializedCameraPower(
      cameraPower,
      guard: '_call == null || _cohostFlipBusy',
      busyFlag: '_cohostFlipBusy',
      sdkCall: 'await _call!.setCameraEnabled(enabled: next)',
    );

    expect(viewer, contains('bool _cohostFlipBusy = false;'));
    expect(viewer, contains('onPressed: !_cohostFlipBusy'));
  });
}

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Build 47 Live camera preview regression', () {
    final camera = File(
      'lib/features/live/native_camera_screen.dart',
    ).readAsStringSync();

    test('creator can preview their camera before starting Stream Video', () {
      expect(camera, contains("Key('native-live-camera-preview')"));
      expect(camera, contains("Key('native-enable-camera-preview')"));
      expect(camera, contains('CameraPreview(_previewController!)'));
      expect(camera, contains('enableAudio: false'));
      expect(camera, contains('CameraLensDirection.front'));
    });

    test('camera preview never opens automatically in the hidden Live tab', () {
      expect(camera, contains('Future<void> _startPreview() async'));
      expect(camera, contains('onPressed: _liveBusy'));
      expect(camera, isNot(contains('unawaited(_startPreview());\n  }')));
    });

    test('releases preview before microphone permission check and Stream room', () {
      final stop = camera.indexOf('await _stopPreview();');
      final verify = camera.indexOf('await _verifyCameraAccess();');
      final open = camera.indexOf('room = await widget.liveBackend.startLiveRoom(');
      expect(stop, greaterThan(0));
      expect(verify, greaterThan(stop));
      expect(open, greaterThan(verify));
      expect(camera, contains('await controller.dispose();'));
    });
  });
}

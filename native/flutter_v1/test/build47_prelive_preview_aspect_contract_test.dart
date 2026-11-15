import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Pre-Live front-camera preview aspect contract', () {
    final camera = File('lib/features/live/native_camera_screen.dart')
        .readAsStringSync();

    test('preview is centered with loose constraints in a wide card', () {
      const before = 'child: _previewController?.value.isInitialized == true';
      const after = 'if (_previewController?.value.isInitialized != true)';
      final preview = camera.split(before).last.split(after).first;

      // CameraPreview has its own orientation-aware AspectRatio. A Center
      // prevents the parent fixed-height card from imposing tight wide
      // constraints that can stretch the portrait selfie texture.
      expect(preview, contains('? Center('));
      expect(preview, contains('child: CameraPreview(_previewController!)'));
      expect(preview, contains('key: const Key(\'native-enable-camera-preview\')'), isFalse);
      expect(preview, isNot(contains('BoxFit.fill')));
    });

    test('preview remains opt-in and releases camera before Stream media', () {
      expect(camera, contains('Future<void> _startPreview() async {'));
      expect(camera, contains('Future<void> _stopPreview() async {'));
      final start = camera.indexOf('await _stopPreview();');
      final access = camera.indexOf('await _verifyCameraAccess();');
      expect(start, greaterThan(-1));
      expect(access, greaterThan(start));
      expect(camera, contains("key: const Key('native-enable-camera-preview')"));
      expect(camera, contains("key: const Key('native-go-live')"));
    });

    test('preserves Android and iOS camera initialization and permission policy', () {
      expect(camera, contains('availableCameras()'));
      expect(camera, contains('CameraLensDirection.front'));
      expect(camera, contains('enableAudio: false'));
      expect(camera, contains('enableAudio: true'));
    });
  });
}

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Build 47 camera flip profile-image regression', () {
    final backend =
        File('lib/data/fameverse_live_backend.dart').readAsStringSync();
    final host =
        File('lib/features/live/stream_host_live_screen.dart').readAsStringSync();
    final viewer =
        File('lib/features/live/stream_viewer_live_screen.dart').readAsStringSync();
    final stage =
        File('lib/features/live/native_live_stage.dart').readAsStringSync();

    test('existing Live room activity carries best-effort flip events', () {
      expect(backend, contains("'camera-flip'"));
      expect(backend, contains("onCohost({...data, '_event': event});"));
    });

    test('host and cohost show and clear their own fallback around a flip', () {
      for (final source in [host, viewer]) {
        expect(source, contains('_setCameraFlipFallback(widget.identity.id, true);'));
        expect(source, contains('await _announceCameraFlip(true);'));
        expect(source, contains("await call.flipCamera()"));
        expect(source, contains('await _announceCameraFlip(false);'));
        expect(source, contains('_setCameraFlipFallback(widget.identity.id, false);'));
        expect(source, contains('Duration(seconds: 6)'));
        expect(source, contains('_cameraFallbackTimers.clear()'));
      }
    });

    test('only the current host or cohost can trigger remote visual fallback', () {
      expect(host, contains("if (viewerId != null && viewerId == _activeCohostUserId)"));
      expect(viewer, contains('viewerId == widget.room.hostUserId ||'));
      expect(viewer, contains('viewerId == _activeCohostUserId'));
    });

    test('camera transition is a profile photo, not a black live tile', () {
      expect(stage, contains('final bool hostCameraTransitioning;'));
      expect(stage, contains('final bool cohostCameraTransitioning;'));
      expect(stage, contains('if (!videoEnabled || transitioning)'));
      expect(stage, contains('transitioning ?'));
      expect(stage, contains("'Switching camera…' : 'Camera off'"));
      expect(stage, contains('NetworkImage(image)'));
      expect(stage, contains('aspectRatio: 1'));
    });
  });
}

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

String read(String path) => File(path).readAsStringSync();

void main() {
  test('host startup never mislabels asynchronous camera startup as camera off', () {
    final stage = read('lib/features/live/native_live_stage.dart');
    final host = read('lib/features/live/stream_host_live_screen.dart');

    expect(stage, contains('videoExpected: cameraEnabled'));
    expect(stage, contains("Key('live-camera-starting')"));
    expect(stage, contains('Preparing camera…'));
    expect(
      stage,
      contains('if (videoExpected && (participant == null || !videoEnabled))'),
    );
    expect(
      host,
      isNot(contains('const FvLiveBackground(icon: Icons.videocam_off_rounded),')),
    );
  });

  test('FameTaps has one branded F-plus-flame identity across host and viewer', () {
    final shared = read('lib/features/live/stream_live_shared.dart');
    final host = read('lib/features/live/stream_host_live_screen.dart');
    final viewer = read('lib/features/live/stream_viewer_live_screen.dart');

    expect(shared, contains('class FvFameTapMark'));
    expect(shared, contains("Key('fame-tap-mark')"));
    expect(shared, contains('Icons.local_fire_department_rounded'));
    expect(shared, contains("'F'"));
    expect(shared, contains('color: Color(0xFFE1B5FF)'));
    expect(host, contains('const FvFameTapMark(size: 13)'));
    expect(host, isNot(contains('Color(0xFFFF9D2E)')));
    expect(viewer, contains('const FvFameTapMark(size: 28)'));
    expect(viewer, contains('const FvFameTapMark(size: 14)'));
    expect(viewer, isNot(contains("'🔥'")));
    expect(shared, contains('Colors.black.withValues(alpha: .22)'));
    expect(shared, contains('Colors.black.withValues(alpha: .48)'));
    expect(shared, isNot(contains('Colors.black.withValues(alpha: .88)')));
  });

  test(
    'For You preserves backend Fame Algo ranking instead of locally replacing it',
    () {
      final home = read('lib/features/shell/fameverse_home_screen.dart');
      final backend = read('lib/data/fameverse_backend.dart');

      expect(home, contains("Key('fame-algo-identity')"));
      expect(home, contains('FAME ALGO'));
      expect(
        home,
        contains('widget.rooms already arrives in backend Fame Algo order'),
      );
      expect(home, contains('return rooms;'));
      expect(home, isNot(contains('_forYouScore')));
      expect(backend, contains("'get_recommended_creators_v2'"));
      expect(backend, contains("'get_active_live_rooms_v2'"));
    },
  );

  test('owner/admin viewer gift box remains explicitly role-gated', () {
    final viewer = read('lib/features/live/stream_viewer_live_screen.dart');

    expect(
      viewer,
      contains("_accountRole == 'owner' || _accountRole == 'admin'"),
    );
    expect(viewer, contains("Key('viewer-gift-button')"));
    expect(viewer, contains('if (_giftEnabled) ...['));
    expect(viewer, contains('You cannot gift your own live.'));
  });
}

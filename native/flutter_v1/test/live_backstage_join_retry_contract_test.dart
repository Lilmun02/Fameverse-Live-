import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('viewer retries the short host-to-live backstage window', () {
    final viewer = File(
      'lib/features/live/stream_viewer_live_screen.dart',
    ).readAsStringSync();

    expect(viewer, contains('for (var attempt = 0; attempt < 3; attempt++)'));
    expect(viewer, contains('if (!joinResult.isFailure) break;'));
    expect(viewer, contains('Duration(milliseconds: 400 * (attempt + 1))'));
    expect(viewer, contains('if (attempt == 2) {'));
    expect(viewer, contains("'Could not join the livestream'"));
    expect(viewer, contains("fvIsEndedLiveError(error)"));
    expect(viewer, contains("viewer-live-retry-join"));
  });
}

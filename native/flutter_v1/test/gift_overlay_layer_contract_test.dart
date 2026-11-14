import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('viewer gift overlay stays above transient tap effects', () {
    final source = File(
      'lib/features/live/stream_viewer_live_screen.dart',
    ).readAsStringSync();

    final tapBursts = source.indexOf('..._tapBursts.map(');
    final giftOverlay = source.indexOf("ValueKey('viewer-gift-\$_giftSerial')");

    expect(tapBursts, greaterThanOrEqualTo(0));
    expect(giftOverlay, greaterThanOrEqualTo(0));
    expect(
      giftOverlay,
      greaterThan(tapBursts),
      reason:
          'Gift playback must paint after tap particles so it cannot be visually covered.',
    );
  });
}

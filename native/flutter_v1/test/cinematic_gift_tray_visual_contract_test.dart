import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'cinematic gift tray previews real media instead of emoji stand-ins',
    () {
      final visual = File(
        'lib/features/live/native_gift_visual.dart',
      ).readAsStringSync();

      expect(visual, contains("package:video_player/video_player.dart"));
      expect(visual, contains('VideoPlayerController.networkUrl'));
      expect(visual, contains('VideoPlayer(controller)'));
      expect(visual, contains('await next.setVolume(0)'));
      expect(visual, contains('await next.seekTo'));
      expect(visual, contains('if (widget.gift.cinematic)'));
      expect(
        visual,
        contains("Key('gift-preview-unavailable-${widget.gift.id}')"),
      );

      final cinematicBlockStart = visual.indexOf('Widget _cinematicPreview()');
      final lightweightBlockStart = visual.indexOf('@override\n  Widget build');
      expect(cinematicBlockStart, greaterThanOrEqualTo(0));
      expect(lightweightBlockStart, greaterThan(cinematicBlockStart));

      final cinematicBlock = visual.substring(
        cinematicBlockStart,
        lightweightBlockStart,
      );
      expect(cinematicBlock, isNot(contains('Text(widget.gift.symbol')));
      expect(cinematicBlock, isNot(contains('Text(gift.symbol')));
    },
  );
}

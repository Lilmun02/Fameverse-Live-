import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Build 23 finalization regressions', () {
    test('cohost camera flip is serialized like host flip', () async {
      final viewer = await File(
        'lib/features/live/stream_viewer_live_screen.dart',
      ).readAsString();

      expect(viewer, contains('bool _cohostFlipBusy = false;'));
      expect(viewer, contains('_cohostFlipBusy) {'));
      expect(viewer, contains('setState(() => _cohostFlipBusy = true)'));
      expect(viewer, contains('setState(() => _cohostFlipBusy = false)'));
      expect(viewer, contains('_cohostCameraEnabled && !_cohostFlipBusy'));
    });

    test('Fame Coins profile card opens the store across the whole card', () async {
      final profile = await File(
        'lib/features/profile/native_profile_build23.dart',
      ).readAsString();

      expect(profile, contains("Key('profile-fame-coins-card')"));
      expect(profile, contains('onTap: _loading ? null : _openStore'));
      expect(profile, contains("Key('profile-buy-fame-coins')"));
      expect(profile, contains("tooltip: 'Refresh Fame Coins'"));
    });
  });
}

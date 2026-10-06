import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

String _files(List<String> paths) =>
    paths.map((path) => File(path).readAsStringSync()).join('\n');

void main() {
  group('Build 23 finalization regressions', () {
    test('cohost camera flip is serialized like host flip', () {
      final viewer = _files([
        'lib/features/live/stream_viewer_live_screen.dart',
        'lib/features/live/stream_viewer_interactions.part.dart',
        'lib/features/live/stream_viewer_sheets.part.dart',
      ]);

      expect(viewer, contains('bool _cohostFlipBusy = false;'));
      expect(viewer, contains('_cohostFlipBusy) {'));
      expect(viewer, contains('setState(() => _cohostFlipBusy = true)'));
      expect(viewer, contains('setState(() => _cohostFlipBusy = false)'));
      expect(viewer, contains('_cohostCameraEnabled && !_cohostFlipBusy'));
    });

    test('Fame Coins profile card opens the store across the whole card', () {
      final profile = _files([
        'lib/features/profile/native_profile_build23.dart',
        'lib/features/profile/native_profile_build23_identity.part.dart',
        'lib/features/profile/native_profile_build23_settings.part.dart',
      ]);

      expect(profile, contains("Key('profile-fame-coins-card')"));
      expect(profile, contains('onTap: _loading ? null : _openStore'));
      expect(profile, contains("Key('profile-buy-fame-coins')"));
      expect(profile, contains("tooltip: 'Refresh Fame Coins'"));
    });
  });
}

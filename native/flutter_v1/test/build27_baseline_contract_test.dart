import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Build 27 baseline contract', () {
    test('owner control center stays wired to authoritative identity', () {
      final shell = File(
        'lib/features/shell/fameverse_shell_build23.dart',
      ).readAsStringSync();
      final profile = File(
        'lib/features/profile/native_profile_build23.dart',
      ).readAsStringSync();

      expect(shell, contains('get_my_fameverse_identity'));
      expect(shell, contains('Build23OwnerControlCenterScreen'));
      expect(profile, contains('Owner Control Center'));
    });

    test('owner host gift tray stays on host Live', () {
      final wrapper = File(
        'lib/features/live/stream_owner_host_live_screen.dart',
      ).readAsStringSync();
      final host = File(
        'lib/features/live/stream_host_live_screen.dart',
      ).readAsStringSync();
      final liveExport = File(
        'lib/features/live/stream_live_screen.dart',
      ).readAsStringSync();

      expect(host, contains("Key('owner-host-gift-button')"));
      expect(wrapper, contains("'record_beta_gift'"));
      expect(
        liveExport,
        contains("export 'stream_owner_host_live_screen.dart';"),
      );
    });

    test('host Live keeps the visible End control', () {
      final host = File(
        'lib/features/live/stream_host_live_screen.dart',
      ).readAsStringSync();

      expect(host, contains("Key('native-end-live')"));
      expect(host, contains('onPressed: _ending ? null : _endLive'));
      expect(host, contains("Text(_ending ? 'Ending…' : 'End')"));
    });

    test('branded splash stays visible for 2.5 seconds after first frame', () {
      final app = File('lib/app/fameverse_app.dart').readAsStringSync();

      expect(app, contains('WidgetsBinding.instance.addPostFrameCallback'));
      expect(app, contains('Duration(milliseconds: 2500)'));
      expect(app, contains('FameverseApp.splashKey'));
    });

    test('native iOS launch cannot regress to the white default', () {
      final applyBranding = File(
        'tool/apply_ios_branding.sh',
      ).readAsStringSync();
      final verifyBranding = File(
        'tool/verify_ios_branding.sh',
      ).readAsStringSync();

      expect(applyBranding, contains('FAMEVERSE_NATIVE_LAUNCH_DARK'));
      expect(
        applyBranding,
        contains(
          'red="0.01960784314" green="0.01960784314" blue="0.02745098039"',
        ),
      );
      expect(
        verifyBranding,
        contains('white native LaunchScreen background returned'),
      );
    });
  });
}

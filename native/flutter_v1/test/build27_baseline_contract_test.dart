import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

String _files(List<String> paths) =>
    paths.map((path) => File(path).readAsStringSync()).join('\n');

void main() {
  group('Build 27 baseline contract', () {
    test('owner control center stays wired to authoritative identity', () {
      final shell = _files([
        'lib/features/shell/fameverse_shell_build23.dart',
        'lib/features/shell/build23_shell_account_service.dart',
      ]);
      final profile = _files([
        'lib/features/profile/native_profile_build23.dart',
        'lib/features/profile/native_profile_build23_settings.part.dart',
      ]);
      expect(shell, contains('get_my_fameverse_identity'));
      expect(shell, contains('Build23OwnerControlCenterScreen'));
      expect(profile, contains('Owner Studio'));
    });

    test('owner host gift tray stays on host Live', () {
      final wrapper = File(
        'lib/features/live/stream_owner_host_live_screen.dart',
      ).readAsStringSync();
      final host = _files([
        'lib/features/live/stream_host_live_screen.dart',
        'lib/features/live/stream_host_view.part.dart',
      ]);
      final liveExport = File(
        'lib/features/live/stream_live_screen.dart',
      ).readAsStringSync();

      expect(host, contains("Key('owner-host-gift-button')"));
      expect(wrapper, contains("'record_beta_gift'"));
      expect(liveExport, contains("export 'stream_owner_host_live_screen.dart';"));
    });

    test('host Live keeps the visible End control', () {
      final host = _files([
        'lib/features/live/stream_host_live_screen.dart',
        'lib/features/live/stream_host_view.part.dart',
      ]);
      expect(host, contains("Key('native-end-live')"));
      expect(host, contains('onPressed: _ending ? null : _endLive'));
      expect(host, contains("Text(_ending ? 'Ending…' : 'End')"));
    });

    test('branded splash stays visible for 2.5 seconds after first frame', () {
      final app = _files([
        'lib/app/fameverse_app.dart',
        'lib/app/fameverse_app_widgets.part.dart',
      ]);
      expect(app, contains('WidgetsBinding.instance.addPostFrameCallback'));
      expect(app, contains('Duration(milliseconds: 2500)'));
      expect(app, contains('FameverseApp.splashKey'));
    });

    test('native iOS launch cannot regress to the white default', () {
      final applyBranding = File('tool/apply_ios_branding.sh').readAsStringSync();
      final verifyBranding = File('tool/verify_ios_branding.sh').readAsStringSync();
      expect(applyBranding, contains('FAMEVERSE_NATIVE_LAUNCH_DARK'));
      expect(
        applyBranding,
        contains('red="0.01960784314" green="0.01960784314" blue="0.02745098039"'),
      );
      expect(verifyBranding, contains('white native LaunchScreen background returned'));
    });
  });
}

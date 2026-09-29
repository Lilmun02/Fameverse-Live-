import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

String _source(String path) => File(path).readAsStringSync();

void main() {
  group('Build 23 internal bug patches', () {
    test('owner control center keeps dollar validation parse-safe', () {
      final source = _source(
        'lib/features/profile/owner_control_center_build23.dart',
      );

      expect(source, contains("r'Enter an amount greater than \$0.'"));
      expect(
        source,
        isNot(contains("_message('Enter an amount greater than \$0.');")),
      );
    });

    test('host camera flips are serialized and cannot overlap', () {
      final source = _source('lib/features/live/stream_host_live_screen.dart');

      expect(source, contains('bool _flipCameraBusy = false;'));
      expect(source, contains('_flipCameraBusy) {'));
      expect(source, contains('setState(() => _flipCameraBusy = true);'));
      expect(source, contains('setState(() => _flipCameraBusy = false);'));
      expect(source, contains('_cameraEnabled && !_flipCameraBusy'));
    });

    test('profile verification comes from backend verified status', () {
      final source = _source(
        'lib/features/profile/native_profile_build23.dart',
      );

      expect(source, contains('_Build23VerificationBadge('));
      expect(source, contains("from('creator_verification_requests')"));
      expect(source, contains(".select('status')"));
      expect(source, contains("== 'verified'"));
      expect(
        source,
        contains('if (!_verified) return const SizedBox.shrink();'),
      );
    });
  });
}

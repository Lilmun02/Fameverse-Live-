import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

String _source(String path) => File(path).readAsStringSync();
String _files(List<String> paths) => paths.map(_source).join('\n');

void main() {
  group('Build 23 internal bug patches', () {
    test('owner control center keeps dollar validation parse-safe', () {
      final source = _files([
        'lib/features/profile/owner_control_center_build23.dart',
        'lib/features/profile/owner_control_center_dialogs.part.dart',
      ]);

      expect(source, contains("r'Enter an amount greater than \\$0.'"));
      expect(
        source,
        isNot(contains("_message('Enter an amount greater than \\$0.');")),
      );
    });

    test('host camera flips are serialized and cannot overlap', () {
      final source = _files([
        'lib/features/live/stream_host_live_screen.dart',
        'lib/features/live/stream_host_session.part.dart',
        'lib/features/live/stream_host_view.part.dart',
      ]);

      expect(source, contains('bool _flipCameraBusy = false;'));
      expect(source, contains('_flipCameraBusy) {'));
      expect(source, contains('setState(() => _flipCameraBusy = true);'));
      expect(source, contains('setState(() => _flipCameraBusy = false);'));
      expect(source, contains('_cameraEnabled && !_flipCameraBusy'));
    });

    test('profile verification comes from backend verified status', () {
      final source = _files([
        'lib/features/profile/native_profile_build23.dart',
        'lib/features/profile/native_profile_build23_identity.part.dart',
      ]);

      expect(source, contains('_Build23VerificationBadge('));
      expect(source, contains("from('creator_verification_requests')"));
      expect(source, contains(".select('status')"));
      expect(source, contains("== 'verified'"));
      expect(source, contains('if (!_verified) return const SizedBox.shrink();'));
    });

    test('comments and gifts dismiss sticky keyboard focus', () {
      final host = _files([
        'lib/features/live/stream_host_live_screen.dart',
        'lib/features/live/stream_host_session.part.dart',
        'lib/features/live/stream_host_sheets.part.dart',
      ]);
      final viewer = _files([
        'lib/features/live/stream_viewer_live_screen.dart',
        'lib/features/live/stream_viewer_session.part.dart',
        'lib/features/live/stream_viewer_sheets.part.dart',
      ]);

      expect(
        'FocusManager.instance.primaryFocus?.unfocus()'.allMatches(host).length,
        greaterThanOrEqualTo(1),
      );
      expect(
        'FocusManager.instance.primaryFocus?.unfocus()'.allMatches(viewer).length,
        greaterThanOrEqualTo(3),
      );
    });

    test('gift activity stays lightweight instead of a purple card', () {
      final source = _source('lib/features/live/stream_live_shared.dart');
      expect(source, contains("Key('v2-highlighted-gift-chat')"));
      expect(
        source,
        contains('padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2)'),
      );
      expect(source, isNot(contains('Color(0xCC1A0E24)')));
      expect(source, isNot(contains('Color(0x553C0A71)')));
    });

    test('host live does not show an unconditional verification check', () {
      final source = _files([
        'lib/features/live/stream_host_live_screen.dart',
        'lib/features/live/stream_host_view.part.dart',
      ]);
      expect(source, isNot(contains('Icons.verified_rounded')));
      expect(source, contains('const FvLiveBadge()'));
    });
  });
}

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

String _source(String path) => File(path).readAsStringSync();

void main() {
  group('Build 23 internal bug patches', () {
    test('web owner control keeps dollar validation parse-safe', () {
      final source = _source(
        '../../src/components/owner/OwnerControlCenter.jsx',
      );

      expect(source, contains('Math.round(Number(reserveAmount) * 100)'));
      expect(source, contains('Number.isFinite(cents)'));
      expect(
        source,
        contains(
          "setError('Enter a reward reserve amount greater than \$0.00.')",
        ),
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

    test('comments and gifts dismiss sticky keyboard focus', () {
      final host = _source('lib/features/live/stream_host_live_screen.dart');
      final viewer = _source(
        'lib/features/live/stream_viewer_live_screen.dart',
      );

      expect(
        'FocusManager.instance.primaryFocus?.unfocus()'.allMatches(host).length,
        greaterThanOrEqualTo(1),
      );
      expect(
        'FocusManager.instance.primaryFocus?.unfocus()'
            .allMatches(viewer)
            .length,
        greaterThanOrEqualTo(3),
      );
    });

    test(
      'custom gift amount keeps quick buttons and quantity field synced',
      () {
        final source = _source('lib/features/live/native_live_components.dart');

        expect(source, contains("TextEditingController(text: '1')"));
        expect(source, contains("Key('gift-custom-quantity-field')"));
        expect(source, contains('controller: quantityController'));
        expect(source, contains('setQuantity(value)'));
        expect(source, contains('syncField: false'));
      },
    );

    test('Live chat avatars can open profile surfaces', () {
      final shared = _source('lib/features/live/stream_live_shared.dart');
      final host = _source('lib/features/live/stream_host_live_screen.dart');
      final viewer = _source(
        'lib/features/live/stream_viewer_live_screen.dart',
      );

      expect(shared, contains('final ValueChanged<String>? onProfileTap;'));
      expect(shared, contains("Key('live-chat-profile-avatar-\$userId')"));
      expect(shared, contains('foregroundImage: hasAvatar'));
      expect(host, contains('onProfileTap: (userId)'));
      expect(host, contains('_showProfileSheet();'));
      expect(host, contains('avatarUrl: widget.room.host.avatarUrl'));
      expect(viewer, contains('_showChatProfile(String userId)'));
      expect(viewer, contains('await widget.backend.loadProfile(userId)'));
      expect(viewer, contains('avatarUrl: widget.viewerProfile.avatarUrl'));
    });

    test('gift activity stays lightweight instead of a purple card', () {
      final source = _source('lib/features/live/stream_live_shared.dart');

      expect(source, contains("Key('v2-highlighted-gift-chat')"));
      expect(
        source,
        contains(
          'padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2)',
        ),
      );
      expect(source, isNot(contains('Color(0xCC1A0E24)')));
      expect(source, isNot(contains('Color(0x553C0A71)')));
    });

    test('host live does not show an unconditional verification check', () {
      final source = _source('lib/features/live/stream_host_live_screen.dart');

      expect(source, isNot(contains('Icons.verified_rounded')));
      expect(source, contains('const FvLiveBadge()'));
    });
  });
}

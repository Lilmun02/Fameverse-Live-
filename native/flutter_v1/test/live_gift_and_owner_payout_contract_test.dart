import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Live gifting and owner payout repair', () {
    test('gift tray stays reduced to five human-sized categories', () {
      final tray = File(
        'lib/features/live/native_live_components.dart',
      ).readAsStringSync();
      for (final value in <String>[
        "('trending', 'Trending')",
        "('support', 'Support')",
        "('fun', 'Fun')",
        "('luxury', 'Luxury')",
        "('fameverse', 'Fameverse')",
      ]) {
        expect(tray, contains(value));
      }
      expect(tray, isNot(contains("('classic', 'Classic')")));
      expect(tray, isNot(contains("('sports', 'Sports')")));
      expect(
        tray,
        contains('final sent = await widget.onSend(gift, quantity);'),
      );
      expect(tray, contains('if (sent) {'));
      expect(tray, contains('setState(() => _sending = false);'));
    });

    test('100 coin Fame Burst is client-visible and server-authoritative', () {
      final backend = File(
        'lib/data/fameverse_live_backend.dart',
      ).readAsStringSync();
      expect(backend, contains("id: 'fame-burst'"));
      expect(backend, contains("label: 'Fame Burst'"));
      expect(backend, contains('cost: 100'));
    });

    test('Abyssal Leviathan stays wired as the 5000 coin cinematic gift', () {
      final backend = File(
        'lib/data/fameverse_live_backend.dart',
      ).readAsStringSync();
      expect(backend, contains("id: 'abyssal-leviathan'"));
      expect(backend, contains("label: 'Abyssal Leviathan'"));
      expect(backend, contains('cost: 5000'));
      expect(
        backend,
        contains(
          'https://d2ol7oe51mr4n9.cloudfront.net/user_3IL6AXXAqcrsLZJmbjvrquIP0Bd/ee94db8e-08fe-4028-a641-47e8b0dc3b89.mp4',
        ),
      );
      final start = backend.indexOf("id: 'abyssal-leviathan'");
      final end = backend.indexOf('),', start);
      expect(start, greaterThanOrEqualTo(0));
      expect(end, greaterThan(start));
      expect(backend.substring(start, end), contains('cinematic: true'));
    });

    test('viewer gifting is not owner-refill gated', () {
      final viewer = File(
        'lib/features/live/stream_viewer_live_screen.dart',
      ).readAsStringSync();
      expect(viewer, contains("Key('viewer-gift-button')"));
      expect(viewer, isNot(contains("if (_canRefill) ...[")));
      expect(viewer, contains('canRefill: _canRefill'));
    });

    test(
      'host owner gift control lives in the composer and wrapper has no floater',
      () {
        final host = File(
          'lib/features/live/stream_host_live_screen.dart',
        ).readAsStringSync();
        final wrapper = File(
          'lib/features/live/stream_owner_host_live_screen.dart',
        ).readAsStringSync();
        expect(host, contains("Key('owner-host-gift-button')"));
        expect(host, contains('onGiftPressed'));
        expect(wrapper, contains('onGiftPressed: _qaGiftAllowed'));
        expect(
          wrapper,
          isNot(contains('bottom: MediaQuery.paddingOf(context).bottom + 78')),
        );
      },
    );

    test(
      'gift playback is completion-driven instead of fixed 6.8 second chopping',
      () {
        final tray = File(
          'lib/features/live/native_live_components.dart',
        ).readAsStringSync();
        final host = File(
          'lib/features/live/stream_host_live_screen.dart',
        ).readAsStringSync();
        final viewer = File(
          'lib/features/live/stream_viewer_live_screen.dart',
        ).readAsStringSync();
        expect(tray, contains('onFinished'));
        expect(host, contains('onFinished: _playNextGift'));
        expect(viewer, contains('onFinished: _playNextGift'));
        expect(host, isNot(contains('6800')));
        expect(viewer, isNot(contains('6800')));
      },
    );

    test(
      'cinematic gifts retry real media and never fake-fallback to emoji',
      () {
        final tray = File(
          'lib/features/live/native_live_components.dart',
        ).readAsStringSync();

        expect(tray, contains('for (var attempt = 0; attempt < 2; attempt++)'));
        expect(tray, contains("timeout(const Duration(seconds: 10))"));
        expect(
          tray,
          contains('Preparing the original premium gift animation.'),
        );
        expect(tray, contains('will not replace its animation with an emoji'));
        expect(tray, contains('cinematic-gift-media-failed-'));
        expect(tray, contains('cinematic-gift-media-loading-'));
      },
    );

    test(
      'owner payout review submits and syncs through PayPal provider functions',
      () {
        final owner = File(
          'lib/features/profile/owner_control_center_build23.dart',
        ).readAsStringSync();
        expect(owner, contains('get_creator_payout_moderation_queue'));
        expect(owner, contains('review_creator_payout'));
        expect(owner, contains("'process-creator-payout'"));
        expect(owner, contains("'sync-creator-payout'"));
        expect(owner, contains("'expected_environment': 'sandbox'"));
        expect(owner, contains("Key('owner-payout-approve')"));
        expect(owner, contains("Text('Send with PayPal sandbox')"));
        expect(owner, contains("Key('owner-payout-sync-provider')"));
        expect(owner, isNot(contains("Key('owner-payout-mark-paid')")));
      },
    );

    test('owner can review pending creator verification before payout QA', () {
      final owner = File(
        'lib/features/profile/owner_control_center_build23.dart',
      ).readAsStringSync();
      expect(owner, contains('get_creator_verification_moderation_queue'));
      expect(owner, contains('review_creator_verification'));
      expect(owner, contains("Key('owner-verification-approve')"));
      expect(owner, contains("Key('owner-verification-needs-info')"));
      expect(owner, contains("Key('owner-verification-reject')"));
    });

    test('owner action cards are tappable across the entire card surface', () {
      final owner = File(
        'lib/features/profile/owner_control_center_build23.dart',
      ).readAsStringSync();
      final actionStart = owner.indexOf(
        'class _Action extends StatelessWidget',
      );
      final noticeStart = owner.indexOf(
        'class _Notice extends StatelessWidget',
      );
      expect(actionStart, greaterThanOrEqualTo(0));
      expect(noticeStart, greaterThan(actionStart));
      final action = owner.substring(actionStart, noticeStart);
      expect(action, contains('return InkWell('));
      expect(action, contains('onTap: onTap'));
      expect(action, contains('borderRadius: BorderRadius.circular(18)'));
    });
  });
}

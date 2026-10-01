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
    });

    test('100 coin Fame Burst is client-visible and server-authoritative', () {
      final backend = File(
        'lib/data/fameverse_live_backend.dart',
      ).readAsStringSync();
      expect(backend, contains("id: 'fame-burst'"));
      expect(backend, contains("label: 'Fame Burst'"));
      expect(backend, contains('cost: 100'));
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

    test('owner payout review controls call the owner moderation backend', () {
      final owner = File(
        'lib/features/profile/owner_control_center_build23.dart',
      ).readAsStringSync();
      expect(owner, contains('get_creator_payout_moderation_queue'));
      expect(owner, contains('review_creator_payout'));
      expect(owner, contains('begin_creator_payout_processing'));
      expect(owner, contains("Key('owner-payout-approve')"));
      expect(owner, contains("Key('owner-payout-mark-paid')"));
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

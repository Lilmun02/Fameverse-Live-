import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Live gifting and owner payout repair', () {
    test('gift tray stays reduced to five human-sized categories', () {
      final tray = File(
        'lib/features/live/native_live_components.dart',
      ).readAsStringSync();
      for (final value in <String>[
        "('trending', 'Featured')",
        "('support', '1–10 Coins')",
        "('fun', '11–39 Coins')",
        "('luxury', '40–99 Coins')",
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
        expect(tray, contains('await next.setVolume(0)'));
        expect(tray, contains("Key('gift-sender-entrance-"));
        expect(tray, contains('cinematic-gift-media-failed-'));
        expect(tray, contains('AnimatedOpacity('));
      },
    );

    test('cinematic gifts render the entire asset with no title overlay', () {
      final overlay = File(
        'lib/features/live/native_live_components.dart',
      ).readAsStringSync();
      final preview = File(
        'lib/features/live/native_gift_visual.dart',
      ).readAsStringSync();

      expect(overlay, contains('fit: BoxFit.contain'));
      expect(preview, contains('fit: BoxFit.contain'));
      expect(overlay, contains('.clamp(1500, 60000)'));
      expect(overlay, isNot(contains("width: size.width * .96")));
      final cinematicStart = overlay.indexOf(
        "key: Key('cinematic-gift-presentation-",
      );
      final endOfCinematic = overlay.indexOf(
        'return Align(',
        cinematicStart + 1,
      );
      expect(cinematicStart, greaterThanOrEqualTo(0));
      expect(endOfCinematic, greaterThan(cinematicStart));
      final cinematic = overlay.substring(cinematicStart, endOfCinematic);
      expect(cinematic, isNot(contains('playback.gift.label')));
      expect(cinematic, isNot(contains('playback.sender')));
    });

    test('native live controls survive optional data refresh failures', () {
      final host = File(
        'lib/features/live/stream_host_live_screen.dart',
      ).readAsStringSync();
      final viewer = File(
        'lib/features/live/stream_viewer_live_screen.dart',
      ).readAsStringSync();
      final ownerHost = File(
        'lib/features/live/stream_owner_host_live_screen.dart',
      ).readAsStringSync();

      expect(viewer, isNot(contains('Future.wait<dynamic>([')));
      expect(viewer, contains('unawaited(_hydrateViewerState())'));
      expect(viewer, contains('_walletReady = true;'));
      expect(ownerHost, isNot(contains('Future.wait<dynamic>([')));
      expect(ownerHost, contains('setState(() => _qaGiftAllowed = true)'));
      expect(host, contains("setState(() => _connecting = false)"));
      expect(host, contains('loadGifterStats'));
      expect(host, contains('loadTapTotal'));
    });

    test('native livestream audio uses high quality voice configuration', () {
      final host = File(
        'lib/features/live/stream_host_live_screen.dart',
      ).readAsStringSync();
      final viewer = File(
        'lib/features/live/stream_viewer_live_screen.dart',
      ).readAsStringSync();

      expect(host, contains('SfuAudioBitrateProfile.voiceHighQuality'));
      expect(host, contains('AudioConfigurationPolicy.broadcaster()'));
      expect(viewer, contains('SfuAudioBitrateProfile.voiceHighQuality'));
      expect(viewer, contains('AudioConfigurationPolicy.viewer()'));
      expect(host.toLowerCase(), isNot(contains('safari')));
      expect(viewer.toLowerCase(), isNot(contains('safari')));
    });

    test(
      'recorded gifts do not become failed sends when broadcast sync hiccups',
      () {
        final backend = File(
          'lib/data/fameverse_live_backend.dart',
        ).readAsStringSync();
        final viewer = File(
          'lib/features/live/stream_viewer_live_screen.dart',
        ).readAsStringSync();
        final ownerHost = File(
          'lib/features/live/stream_owner_host_live_screen.dart',
        ).readAsStringSync();

        expect(
          backend,
          contains('RealtimeChannelConfig(ack: true, self: false)'),
        );
        expect(viewer, contains('_broadcastGiftReceipt'));
        expect(
          viewer,
          contains('for (var attempt = 0; attempt < 3; attempt += 1)'),
        );
        expect(ownerHost, contains('_broadcastQaGiftReceipt'));
        expect(
          ownerHost,
          contains('for (var attempt = 0; attempt < 3; attempt += 1)'),
        );
      },
    );

    test(
      'web owner payout review submits, recovers and syncs through PayPal provider functions',
      () {
        final owner = File(
          '../../src/components/owner/OwnerControlCenter.jsx',
        ).readAsStringSync();
        final service = File(
          '../../src/services/ownerControl.js',
        ).readAsStringSync();

        expect(service, contains('get_creator_payout_moderation_queue_v2'));
        expect(service, contains('review_creator_payout'));
        expect(service, contains("'process-creator-payout'"));
        expect(service, contains("'sync-creator-payout'"));
        expect(service, contains('expected_environment: expectedEnvironment'));
        expect(owner, contains('Release to PayPal'));
        expect(owner, contains('Recover PayPal submission'));
        expect(owner, contains('Sync PayPal'));
        expect(owner, isNot(contains('Mark paid')));
      },
    );

    test(
      'web owner can review pending creator verification before payout QA',
      () {
        final owner = File(
          '../../src/components/owner/OwnerControlCenter.jsx',
        ).readAsStringSync();
        final verification = File(
          '../../src/components/owner/OwnerVerificationQueue.jsx',
        ).readAsStringSync();
        final service = File(
          '../../src/services/ownerControl.js',
        ).readAsStringSync();

        expect(service, contains('get_creator_verification_moderation_queue'));
        expect(service, contains('review_creator_verification'));
        expect(owner, contains('OwnerVerificationQueue'));
        expect(owner, contains('onAction={verificationAction}'));
        expect(verification, contains('Verification Queue'));
        expect(verification, contains("onAction(request, 'verified')"));
        expect(verification, contains("onAction(request, 'needs_info')"));
        expect(verification, contains("onAction(request, 'rejected')"));
      },
    );

    test(
      'native owner profile routes to Creator Studio instead of admin controls',
      () {
        final shell = File(
          'lib/features/shell/fameverse_shell_build23.dart',
        ).readAsStringSync();
        final profile = File(
          'lib/features/profile/native_profile_build23.dart',
        ).readAsStringSync();

        expect(shell, isNot(contains('Build23OwnerControlCenterScreen')));
        expect(profile, contains('Creator Studio'));
        expect(profile, isNot(contains('Owner Studio')));
      },
    );
  });
}

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  String files(List<String> paths) =>
      paths.map((path) => File(path).readAsStringSync()).join('\n');

  final liveComponents = () => files([
        'lib/features/live/native_live_components.dart',
        'lib/features/live/native_gift_tray.part.dart',
        'lib/features/live/native_gift_balance.part.dart',
        'lib/features/live/native_gift_custom_amount.part.dart',
        'lib/features/live/native_gift_overlay.part.dart',
      ]);
  final host = () => files([
        'lib/features/live/stream_host_live_screen.dart',
        'lib/features/live/stream_host_session.part.dart',
        'lib/features/live/stream_host_cohost.part.dart',
        'lib/features/live/stream_host_sheets.part.dart',
        'lib/features/live/stream_host_view.part.dart',
        'lib/features/live/stream_host_widgets.part.dart',
      ]);
  final viewer = () => files([
        'lib/features/live/stream_viewer_live_screen.dart',
        'lib/features/live/stream_viewer_session.part.dart',
        'lib/features/live/stream_viewer_interactions.part.dart',
        'lib/features/live/stream_viewer_sheets.part.dart',
        'lib/features/live/stream_viewer_view.part.dart',
        'lib/features/live/stream_viewer_widgets.part.dart',
      ]);
  final owner = () => files([
        'lib/features/profile/owner_control_center_build23.dart',
        'lib/features/profile/owner_control_center_dialogs.part.dart',
        'lib/features/profile/owner_control_center_view.part.dart',
        'lib/features/profile/owner_control_center_review_cards.part.dart',
        'lib/features/profile/owner_control_center_widgets.part.dart',
      ]);
  final giftCatalog = () => files([
        'lib/data/fameverse_gift_catalog.dart',
        'lib/data/fameverse_gift_catalog_core.dart',
        'lib/data/fameverse_gift_catalog_premium.dart',
      ]);

  group('Live gifting and owner payout repair', () {
    test('gift tray stays reduced to five human-sized categories', () {
      final tray = liveComponents();
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
        contains('widget.onSend(gift, quantity, _fundingMode)'),
      );
      expect(tray, contains('if (sent) {'));
      expect(tray, contains('setState(() => _sending = false);'));
    });

    test('gift tray visibly separates Real Coins and Test Coins', () {
      final tray = liveComponents();
      expect(tray, contains("Key('gift-real-coin-balance')"));
      expect(tray, contains("Key('gift-test-coin-balance')"));
      expect(tray, contains("Key('gift-funding-mode-selector')"));
      expect(tray, contains("value: 'test'"));
      expect(tray, contains("value: 'real'"));
      expect(tray, contains('Test Coins · no real payout value'));
      expect(tray, contains('Real Coins · creator earnings apply'));
    });

    test('100 coin Fame Burst is client-visible and server-authoritative', () {
      final backend = giftCatalog();
      expect(backend, contains("id: 'fame-burst'"));
      expect(backend, contains("label: 'Fame Burst'"));
      expect(backend, contains('cost: 100'));
    });

    test('Abyssal Leviathan stays wired as the 5000 coin cinematic gift', () {
      final backend = giftCatalog();
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
      final source = viewer();
      expect(source, contains("Key('viewer-gift-button')"));
      expect(source, isNot(contains("if (_canRefill) ...[")));
      expect(source, contains('canRefill: _canRefill'));
      expect(source, contains('realCoins: _realCoins'));
      expect(source, contains('testCoins: _testCoins'));
    });

    test(
      'host owner gift control lives in the composer and wrapper has no floater',
      () {
        final hostSource = host();
        final wrapper = File(
          'lib/features/live/stream_owner_host_live_screen.dart',
        ).readAsStringSync();
        expect(hostSource, contains("Key('owner-host-gift-button')"));
        expect(hostSource, contains('onGiftPressed'));
        expect(wrapper, contains('onGiftPressed: _qaGiftAllowed'));
        expect(wrapper, contains('realCoins: 0'));
        expect(wrapper, isNot(contains('bottom: MediaQuery.paddingOf(context).bottom + 78')));
      },
    );

    test(
      'gift playback is completion-driven instead of fixed 6.8 second chopping',
      () {
        final overlay = liveComponents();
        final hostSource = host();
        final viewerSource = viewer();
        expect(overlay, contains('onFinished'));
        expect(hostSource, contains('onFinished: _playNextGift'));
        expect(viewerSource, contains('onFinished: _playNextGift'));
        expect(hostSource, isNot(contains('6800')));
        expect(viewerSource, isNot(contains('6800')));
      },
    );

    test(
      'cinematic gifts retry real media and never fake-fallback to emoji',
      () {
        final overlay = liveComponents();
        expect(overlay, contains('for (var attempt = 0; attempt < 2; attempt++)'));
        expect(overlay, contains('timeout(const Duration(seconds: 10))'));
        expect(overlay, contains('Preparing the original premium gift animation.'));
        expect(overlay, contains('will not replace its animation with an emoji'));
        expect(overlay, contains('cinematic-gift-media-failed-'));
        expect(overlay, contains('cinematic-gift-media-loading-'));
      },
    );

    test('cinematic gifts render the entire asset with no title overlay', () {
      final overlay = liveComponents();
      final preview = File(
        'lib/features/live/native_gift_visual.dart',
      ).readAsStringSync();

      expect(overlay, contains('fit: BoxFit.contain'));
      expect(preview, contains('fit: BoxFit.contain'));
      expect(overlay, contains('rawMs.clamp(1500, 60000).toInt()'));
      expect(overlay, isNot(contains('width: size.width * .96')));
      final cinematicStart = overlay.indexOf(
        "key: Key('cinematic-gift-presentation-",
      );
      final loadingStart = overlay.indexOf("key: Key(", cinematicStart + 1);
      expect(cinematicStart, greaterThanOrEqualTo(0));
      expect(loadingStart, greaterThan(cinematicStart));
      final cinematic = overlay.substring(cinematicStart, loadingStart);
      expect(cinematic, isNot(contains('playback.gift.label')));
      expect(cinematic, isNot(contains('playback.sender')));
    });

    test('native live controls survive optional data refresh failures', () {
      final hostSource = host();
      final viewerSource = viewer();
      final ownerHost = File(
        'lib/features/live/stream_owner_host_live_screen.dart',
      ).readAsStringSync();

      expect(viewerSource, isNot(contains('Future.wait<dynamic>([')));
      expect(viewerSource, contains('unawaited(_hydrateViewerState())'));
      expect(viewerSource, contains('_walletReady = true;'));
      expect(ownerHost, isNot(contains('Future.wait<dynamic>([')));
      expect(ownerHost, contains('setState(() => _qaGiftAllowed = true)'));
      expect(hostSource, contains('setState(() => _connecting = false)'));
      expect(hostSource, contains('loadGifterStats'));
      expect(hostSource, contains('loadTapTotal'));
    });

    test('native livestream audio uses high quality voice configuration', () {
      final hostSource = host();
      final viewerSource = viewer();

      expect(hostSource, contains('SfuAudioBitrateProfile.voiceHighQuality'));
      expect(hostSource, contains('AudioConfigurationPolicy.broadcaster()'));
      expect(viewerSource, contains('SfuAudioBitrateProfile.voiceHighQuality'));
      expect(viewerSource, contains('AudioConfigurationPolicy.viewer()'));
      expect(hostSource.toLowerCase(), isNot(contains('safari')));
      expect(viewerSource.toLowerCase(), isNot(contains('safari')));
    });

    test(
      'recorded gifts do not become failed sends when broadcast sync hiccups',
      () {
        final liveContract = File(
          'lib/data/fameverse_live_contract.dart',
        ).readAsStringSync();
        final viewerSource = viewer();
        final ownerHost = File(
          'lib/features/live/stream_owner_host_live_screen.dart',
        ).readAsStringSync();

        expect(liveContract, contains('RealtimeChannelConfig(ack: true, self: false)'));
        expect(viewerSource, contains('_broadcastGiftReceipt'));
        expect(viewerSource, contains('for (var attempt = 0; attempt < 3; attempt += 1)'));
        expect(ownerHost, contains('_broadcastQaGiftReceipt'));
        expect(ownerHost, contains('for (var attempt = 0; attempt < 3; attempt += 1)'));
      },
    );

    test('owner payout review routes QA and real lanes separately', () {
      final source = owner();
      expect(source, contains('get_creator_payout_moderation_queue_v3'));
      expect(source, contains('review_creator_payout'));
      expect(source, contains("'process-creator-payout'"));
      expect(source, contains("'sync-creator-payout'"));
      expect(source, contains("payout['payout_environment']"));
      expect(source, contains("'expected_environment': environment"));
      expect(source, contains('QA · SANDBOX'));
      expect(source, contains('REAL · LIVE'));
      expect(source, contains("Key('owner-payout-approve')"));
      expect(source, contains("Key('owner-payout-sync-provider')"));
      expect(source, isNot(contains("Key('owner-payout-mark-paid')")));
    });

    test('owner can review pending creator verification before payout QA', () {
      final source = owner();
      expect(source, contains('get_creator_verification_moderation_queue'));
      expect(source, contains('review_creator_verification'));
      expect(source, contains("Key('owner-verification-approve')"));
      expect(source, contains("Key('owner-verification-needs-info')"));
      expect(source, contains("Key('owner-verification-reject')"));
    });

    test('owner action cards are tappable across the entire card surface', () {
      final source = owner();
      final actionStart = source.indexOf('class _Action extends StatelessWidget');
      final noticeStart = source.indexOf('class _Notice extends StatelessWidget');
      expect(actionStart, greaterThanOrEqualTo(0));
      expect(noticeStart, greaterThan(actionStart));
      final action = source.substring(actionStart, noticeStart);
      expect(action, contains('return InkWell('));
      expect(action, contains('onTap: onTap'));
      expect(action, contains('borderRadius: BorderRadius.circular(18)'));
    });
  });
}

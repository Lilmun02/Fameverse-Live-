// Release-blocking regression contract for the Build 18 Live repair candidate.
import 'dart:io';

import 'package:fameverse_live/data/fameverse_live_backend.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Build 18 Live repair contract', () {
    test(
      'gift catalog is unique, priced, and cinematic assets are intentional',
      () {
        final ids = fvGiftCatalog.map((gift) => gift.id).toList();
        expect(ids.toSet().length, ids.length, reason: 'Gift ids must be unique.');
        expect(fvGiftCatalog, isNotEmpty);

        for (final gift in fvGiftCatalog) {
          expect(
            gift.cost,
            greaterThan(0),
            reason: '${gift.id} must have a positive cost.',
          );
          expect(
            gift.label.trim(),
            isNotEmpty,
            reason: '${gift.id} needs a label.',
          );
          if (gift.cinematic && gift.id != 'pocket-comet') {
            expect(
              gift.videoUrl,
              isNotNull,
              reason: '${gift.id} is cinematic and must have a real video asset.',
            );
            expect(
              gift.videoUrl!.startsWith('https://'),
              isTrue,
              reason: '${gift.id} cinematic media must use HTTPS.',
            );
          }
        }

        expect(fvGiftById('welcome-to-fameverse'), isNotNull);
        expect(fvGiftById('ember-dragon'), isNotNull);
        expect(fvGiftById('celestial-phoenix'), isNotNull);
        expect(fvGiftById('pocket-comet'), isNotNull);
      },
    );

    test(
      'host and viewer use approved square cohost stage and keyed gift playback',
      () async {
        final host = await File(
          'lib/features/live/stream_host_live_screen.dart',
        ).readAsString();
        final viewer = await File(
          'lib/features/live/stream_viewer_live_screen.dart',
        ).readAsString();
        final stage = await File(
          'lib/features/live/native_live_stage.dart',
        ).readAsString();

        expect(host, contains('NativeHostV2Stage('));
        expect(viewer, contains('NativeViewerV2Stage('));
        expect(stage, contains('class _V2CohostStage'));
        expect(stage, contains('child: Row('));
        expect(stage, contains('aspectRatio: 1'));
        expect(
          stage,
          contains('never convert co-host into tall stacked rectangles'),
        );
        expect(host, contains("ValueKey<String>('host-gift-\$_giftSerial')"));
        expect(viewer, contains("ValueKey('viewer-gift-\$_giftSerial')"));
      },
    );

    test('camera-off keeps the participant visually present', () async {
      final stage = await File(
        'lib/features/live/native_live_stage.dart',
      ).readAsString();
      final host = await File(
        'lib/features/live/stream_host_live_screen.dart',
      ).readAsString();

      expect(stage, contains('class _V2CameraOffSurface'));
      expect(stage, contains('participant.image?.trim()'));
      expect(stage, contains("'Camera off'"));
      expect(stage, contains('NetworkImage(image)'));
      expect(host, contains('image: widget.room.host.avatarUrl'));
    });

    test(
      'custom send keeps real gift visual and 100000 quantity ceiling',
      () async {
        final components = await File(
          'lib/features/live/native_live_components.dart',
        ).readAsString();

        expect(
          components,
          contains('NativeGiftTrayVisual(gift: _selected, size: 50)'),
        );
        expect(components, contains('value.clamp(1, 100000)'));
        expect(components, contains("Text('Send ×\$quantity')"));
      },
    );

    test(
      'viewer cannot publish media before cohost permission and realtime does not self-echo',
      () async {
        final viewer = await File(
          'lib/features/live/stream_viewer_live_screen.dart',
        ).readAsString();
        final host = await File(
          'lib/features/live/stream_host_live_screen.dart',
        ).readAsString();
        final backend = await File(
          'lib/data/fameverse_live_backend.dart',
        ).readAsString();

        expect(viewer, contains('camera: TrackOption.disabled()'));
        expect(viewer, contains('microphone: TrackOption.disabled()'));
        expect(viewer, contains('CallPermission.sendAudio'));
        expect(viewer, contains('CallPermission.sendVideo'));
        expect(host, contains('CallPermission.sendAudio'));
        expect(host, contains('CallPermission.sendVideo'));
        expect(
          viewer,
          contains('await call.setMicrophoneEnabled(enabled: true)'),
        );
        expect(viewer, contains('await call.setCameraEnabled(enabled: true)'));
        expect(
          backend,
          contains('RealtimeChannelConfig(ack: false, self: false)'),
        );
      },
    );

    test('approved neon solo host V2 layout stays wired', () async {
      final host = await File(
        'lib/features/live/stream_host_live_screen.dart',
      ).readAsString();
      final shared = await File(
        'lib/features/live/stream_live_shared.dart',
      ).readAsString();

      expect(host, contains("Key('host-v2-fameverse-wordmark')"));
      expect(host, contains("'FAMEVERSE'"));
      expect(host, contains("'PEOPLE MAKE LEGENDS'"));
      expect(host, contains('widget.room.host.displayName'));
      expect(host, contains('class _NeonHostAvatar'));
      expect(host, contains('class _LiveStatsPill'));
      expect(host, contains("Key('host-v2-combined-stats')"));
      expect(host, contains('backgroundColor: const Color(0xFFE62952)'));
      expect(host, contains("Key('host-f-menu-button')"));
      expect(host, contains('height: cohostActive ? 230 : 245'));
      expect(host, contains('FvLiveCommentComposer('));
      expect(shared, contains('class FvFameActionButton'));
      expect(shared, contains('color: Color(0xFFE1B5FF)'));
      expect(shared, contains("Key('v2-highlighted-gift-chat')"));
    });

    test(
      'chat and composer match the approved V2 readability contract',
      () async {
        final host = await File(
          'lib/features/live/stream_host_live_screen.dart',
        ).readAsString();
        final viewer = await File(
          'lib/features/live/stream_viewer_live_screen.dart',
        ).readAsString();
        final shared = await File(
          'lib/features/live/stream_live_shared.dart',
        ).readAsString();

        expect(shared, contains('fontSize: 15'));
        expect(shared, contains("'Lv. \$level'"));
        expect(shared, contains('maxLines: 3'));
        expect(shared, contains('keyboardType: TextInputType.multiline'));
        expect(shared, contains('textInputAction: TextInputAction.newline'));
        expect(host, contains('cohostCameraHeight + 32'));
        expect(viewer, contains('cohostCameraHeight + 32'));
        expect(host, contains('FvLiveCommentComposer('));
        expect(viewer, contains('FvLiveCommentComposer('));
      },
    );

    test('PayPal sandbox recharge is native, custom, and Vercel-free', () async {
      final screen = await File(
        'lib/features/profile/native_recharge_screen.dart',
      ).readAsString();
      final studio = await File(
        'lib/features/profile/creator_studio_screen.dart',
      ).readAsString();
      final session = await File(
        '../../supabase/functions/recharge-session/index.ts',
      ).readAsString();
      final api = await File(
        '../../supabase/functions/recharge/index.ts',
      ).readAsString();

      expect(screen, contains('class NativeRechargeScreen'));
      expect(screen, contains('final launched = await launchUrl('));
      expect(screen, contains('mode: LaunchMode.externalApplication'));
      expect(screen, contains("Key('custom-fame-coins-card')"));
      expect(screen, contains("'custom_coins': coins"));
      expect(screen, contains("'Complete sandbox purchase'"));
      expect(studio, contains('if (_isOwner)'));
      expect(studio, contains('NativeRechargeScreen'));
      expect(session, contains('checkout: "native"'));
      expect(session, contains('session: token'));
      expect(session, isNot(contains('vercel.app')));
      expect(api, contains('CUSTOM_PACK_ID = "owner-qa-custom"'));
      expect(api, contains('CUSTOM_MIN_COINS = 100'));
      expect(api, contains('CUSTOM_MAX_COINS = 10000'));
      expect(api, contains('customCoins * CUSTOM_CENTS_PER_COIN'));
      expect(api, contains('approval_url: approvalUrl'));
      expect(api, contains('"native-checkout-required"'));
      expect(api, isNot(contains('vercel.app')));
      expect(api, isNot(contains('text/html')));
    });

    test('TestFlight candidate is source-locked to Build 18', () async {
      final codemagic = await File('../../codemagic.yaml').readAsString();

      expect(codemagic, contains('TARGET_BRANCH="build18/live-repair"'));
      expect(
        codemagic,
        contains('git checkout --detach "refs/remotes/origin/\$TARGET_BRANCH"'),
      );
      expect(codemagic, contains('FAMEVERSE_SOURCE_SHA=\$SOURCE_SHA'));
      expect(codemagic, contains('build18_source_identity.txt'));
      expect(
        codemagic,
        contains(
          '--dart-define="FAMEVERSE_SOURCE_SHA=\${FAMEVERSE_SOURCE_SHA}"',
        ),
      );
    });

    test('physical Live repair contracts remain wired', () async {
      final viewer = await File(
        'lib/features/live/stream_viewer_live_screen.dart',
      ).readAsString();
      final components = await File(
        'lib/features/live/native_live_components.dart',
      ).readAsString();
      final chat = await File(
        'lib/features/live/stream_live_shared.dart',
      ).readAsString();

      expect(viewer, contains("Key('viewer-gift-button')"));
      expect(viewer, contains('widget.room.host.handle'));
      expect(viewer, contains('state.liveEndedAt != null'));
      expect(viewer, contains('class _TapBurstParticle'));
      expect(viewer, isNot(contains("fvGiftById('rose')")));
      expect(components, contains('Future<int> Function() onRefill'));
      expect(components, contains('playback.gift.cost <= 1'));
      expect(chat, contains('fontSize: 15'));
    });
  });
}

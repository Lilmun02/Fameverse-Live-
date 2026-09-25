// Release-blocking regression contract for the Build 16 Live V2 candidate.
import 'dart:io';

import 'package:fameverse_live/data/fameverse_live_backend.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Build 16 Live V2 release contract', () {
    test(
      'gift catalog is unique, priced, and cinematic assets are intentional',
      () {
        final ids = fvGiftCatalog.map((gift) => gift.id).toList();
        expect(
          ids.toSet().length,
          ids.length,
          reason: 'Gift ids must be unique.',
        );
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
              reason:
                  '${gift.id} is cinematic and must have a real video asset.',
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
      'host and viewer use V2 stage and stale gift overlays are keyed per playback',
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
        expect(stage, contains('active co-hosting is two equal tiles'));
        expect(host, contains("ValueKey<String>('host-gift-\$_giftSerial')"));
        expect(
          viewer,
          contains("ValueKey<String>('viewer-gift-\$_giftSerial')"),
        );
      },
    );

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
  });
}

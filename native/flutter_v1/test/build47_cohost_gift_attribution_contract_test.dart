import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Build 47 co-host gifts', () {
    test('existing host gifts remain source-compatible', () {
      final backend = File(
        'lib/data/fameverse_live_backend.dart',
      ).readAsStringSync();

      expect(backend, contains('Future<FvGiftSendResult> recordGift({'));
      expect(backend, contains("required int quantity,"));
      expect(backend, contains("class SupabaseFameverseLiveBackend"));
      expect(backend, contains("'p_recipient_user_id': cohostUserId"));
      expect(backend, contains("prepare_fameverse_live_cohost"));
      expect(backend, contains("activate_fameverse_live_cohost"));
      expect(backend, contains("clear_fameverse_live_cohost"));
      expect(backend, contains("get_fameverse_cohost_gift_coins"));
    });

    test('co-host activation is gated by the server after media starts', () {
      final host = File(
        'lib/features/live/stream_host_live_screen.dart',
      ).readAsStringSync();
      final viewer = File(
        'lib/features/live/stream_viewer_live_screen.dart',
      ).readAsStringSync();

      expect(
        host.indexOf('prepareCohostGiftSession('),
        lessThan(host.indexOf('await call.grantPermissions(')),
      );
      expect(host, contains('clearCohostGiftSession('));
      expect(viewer, contains('activateCohostGiftSession('));
      expect(viewer, contains('clearCohostGiftSession('));
      expect(viewer, contains('recipientUserId != _activeCohostUserId'));
      expect(viewer, contains('recordGiftToCohost('));
      expect(viewer, contains("key: const Key('gift-recipient-cohost')"));
    });

    test('co-host gifted coins are read from backend, never from broadcast', () {
      final stage = File(
        'lib/features/live/native_live_stage.dart',
      ).readAsStringSync();
      final viewer = File(
        'lib/features/live/stream_viewer_live_screen.dart',
      ).readAsStringSync();
      final host = File(
        'lib/features/live/stream_host_live_screen.dart',
      ).readAsStringSync();

      expect(stage, contains('if (cohostGiftCoins != null)'));
      expect(stage, contains('right: 8,'));
      expect(stage, contains('bottom: 8,'));
      expect(stage, contains('Icons.diamond_rounded'));
      expect(stage, contains('Color(0xFFAD73FF)'));
      expect(host, contains('backend.loadCohostGiftCoins('));
      expect(viewer, contains('backend.loadCohostGiftCoins('));
      expect(viewer, isNot(contains('_cohostGiftCoins += total')));
      expect(host, isNot(contains('_cohostGiftCoins += total')));
    });
  });
}

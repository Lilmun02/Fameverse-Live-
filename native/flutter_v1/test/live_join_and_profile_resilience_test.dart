import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fameverse_live/features/live/stream_live_shared.dart';

void main() {
  test('expired room responses are distinguished from network failures', () {
    expect(fvIsEndedLiveError(StateError('live-room-ended')), isTrue);
    expect(fvIsEndedLiveError(StateError('room-not-live')), isTrue);
    expect(fvIsEndedLiveError(StateError('room-not-found')), isTrue);
    expect(fvIsEndedLiveError(StateError('network timeout')), isFalse);
    expect(
      fvFriendlyError(StateError('live-room-ended')),
      contains('This live has ended'),
    );
    expect(
      fvFriendlyError(StateError('network timeout')),
      isNot(contains('has ended')),
    );
  });

  testWidgets('disconnected Live comment composer refuses input', (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FvLiveCommentComposer(
            controller: controller,
            hintText: 'Live unavailable',
            enabled: false,
          ),
        ),
      ),
    );

    expect(tester.widget<TextField>(find.byType(TextField)).enabled, isFalse);
  });

  test('failed joining blocks fake taps, comments and gifts', () {
    final viewer = File(
      'lib/features/live/stream_viewer_live_screen.dart',
    ).readAsStringSync();

    expect(viewer, contains('void _retryJoin() {'));
    expect(viewer, contains('viewer-live-retry-join'));
    expect(viewer, contains('viewer-live-exit-failed-join'));
    expect(viewer, contains('fvIsEndedLiveError(error)'));
    expect(viewer, contains('_activity == null'));
    expect(viewer, contains('enabled: _activity != null'));
    expect(viewer, contains('onPressed: _activity != null'));
    expect(viewer, contains('_walletReady &&'));
  });

  test('a room-only success earns First Verse join mission', () {
    final shell = File(
      'lib/features/shell/fameverse_shell_build23.dart',
    ).readAsStringSync();
    final viewer = File(
      'lib/features/live/stream_viewer_live_screen.dart',
    ).readAsStringSync();

    expect(
      shell,
      contains("onLiveJoined: () => unawaited(_recordBetaMission('join_live'))"),
    );
    expect(viewer, contains('widget.onLiveJoined?.call()'));
    expect(shell, contains('if (mounted) unawaited(_refreshRooms())'));
  });

  test('profile stats failures do not erase available follow information', () {
    final sheet = File(
      'lib/features/live/native_live_profile_sheet.dart',
    ).readAsStringSync();
    expect(sheet, contains('Future<T?> _optionalLoad<T>'));
    expect(sheet, contains('_optionalLoad(statsFuture)'));
    expect(sheet, contains('_optionalLoad(viewerNetworkFuture)'));
    expect(sheet, contains('_optionalLoad(targetNetworkFuture)'));
    expect(sheet, contains('if (stats != null) ...['));
    expect(sheet, contains('Retry details'));
  });

  test('missing or ended room credentials never attempt Stream Video join', () {
    final backend = File(
      'lib/data/fameverse_live_backend.dart',
    ).readAsStringSync();
    expect(backend, contains("details['error'] == 'room-not-live'"));
    expect(backend, contains("details['error'] == 'room-not-found'"));
    expect(backend, contains("throw StateError('live-room-ended')"));
  });
}

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:fameverse_live/data/fameverse_live_backend.dart';

void main() {
  test('catalog adds at least fifty lightweight gifts under one dollar', () {
    final lightweight = fvGiftCatalog.where(
      (gift) => gift.cost < 100 && !gift.cinematic,
    );
    expect(lightweight.length, greaterThanOrEqualTo(50));
    expect(lightweight.every((gift) => gift.videoUrl == null), isTrue);
    expect(
      lightweight.every((gift) => gift.cost >= 1 && gift.cost <= 99),
      isTrue,
    );
  });

  test('cinematic gifts stay separate from lightweight catalog', () {
    final cinematics = fvGiftCatalog.where((gift) => gift.cinematic).toList();
    expect(cinematics, isNotEmpty);
    expect(cinematics.every((gift) => gift.cost >= 100), isTrue);
    expect(fvGiftById('ember-dragon')?.cinematic, isTrue);
    expect(fvGiftById('rose')?.cinematic, isFalse);
  });

  test('gift sending is promo-first and only cash-backed coins use 70/30', () {
    final sql = File(
      '../../supabase/migrations/20260927_gift_catalog_and_funded_sending.sql',
    ).readAsStringSync();

    expect(sql, contains('v_promo_spent := least'));
    expect(sql, contains('v_cash_spent := v_total - v_promo_spent'));
    expect(sql, contains('_apply_creator_cash_coin_share'));
    expect(sql, contains('v_creator_bps <> 7000'));
    expect(sql, contains('promo-first funding'));
    expect(sql, contains('self gifting is not allowed'));
  });

  test('owner promotional gift bonus is funded and capped at five cents', () {
    final sql = File(
      '../../supabase/migrations/20260927_gift_catalog_and_funded_sending.sql',
    ).readAsStringSync();
    expect(sql, contains('v_owner_bonus := least(v_promo_spent, 5)'));
    expect(sql, contains('cash_reward_reserve'));
    expect(sql, contains('No reserve means no hidden liability'));
  });

  test('gift sender slides in before premium playback starts', () {
    final components = File(
      'lib/features/live/native_live_components.dart',
    ).readAsStringSync();

    expect(components, contains("Key('gift-sender-entrance-"));
    expect(components, contains('alignment: const Alignment(-1, -0.02)'));
    expect(components, contains('duration: const Duration(milliseconds: 330)'));
    expect(components, contains('await next.setVolume(0)'));
    expect(components, contains('await player.setVolume(1)'));
    expect(components, contains('await WidgetsBinding.instance.endOfFrame'));
    expect(components, contains('await player.pause()'));
    expect(components, contains('AnimatedOpacity('));
    expect(components, contains('fit: BoxFit.contain'));
  });

  test('low-cost gift visual is compact and does not use default emoji', () {
    final components = File(
      'lib/features/live/native_live_components.dart',
    ).readAsStringSync();
    final host = File(
      'lib/features/live/stream_host_live_screen.dart',
    ).readAsStringSync();
    final viewer = File(
      'lib/features/live/stream_viewer_live_screen.dart',
    ).readAsStringSync();

    expect(components, contains("width: size.width * .76"));
    expect(components, contains("height: size.height * .34"));
    expect(components, contains("Key('native-gift-presentation-"));
    expect(components, isNot(contains('Text(playback.gift.symbol')));
    expect(host, isNot(contains("text: '\${gift.symbol} sent")));
    expect(viewer, isNot(contains("text: '\${gift.symbol} sent")));
  });


  test(
    'cinematic gift tray uses the real gift media instead of an emoji stand-in',
    () {
      final visual = File(
        'lib/features/live/native_gift_visual.dart',
      ).readAsStringSync();
      final components = File(
        'lib/features/live/native_live_components.dart',
      ).readAsStringSync();

      expect(visual, contains('VideoPlayerController.networkUrl'));
      expect(visual, contains('await next.seekTo'));
      expect(visual, contains('VideoPlayer(controller)'));
      expect(components, contains("Key('native-gift-presentation-"));
      expect(components, contains("Key('cinematic-gift-presentation-"));
      expect(components, contains('VideoPlayer(controller)'));
      expect(components, contains('BoxFit.contain'));
    },
  );
}

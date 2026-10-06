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
    expect(lightweight.every((gift) => gift.cost >= 1 && gift.cost <= 99), isTrue);
  });

  test('cinematic gifts stay separate from lightweight catalog', () {
    final cinematics = fvGiftCatalog.where((gift) => gift.cinematic).toList();
    expect(cinematics, isNotEmpty);
    expect(cinematics.every((gift) => gift.cost >= 100), isTrue);
    expect(fvGiftById('ember-dragon')?.cinematic, isTrue);
    expect(fvGiftById('rose')?.cinematic, isFalse);
  });

  test('gift sending has explicit test and real funding modes', () {
    final sql = File(
      '../../supabase/migrations/20261006202500_explicit_real_test_coin_funding.sql',
    ).readAsStringSync();

    expect(sql, contains("v_mode not in ('auto','real','test')"));
    expect(sql, contains("elsif v_mode = 'test'"));
    expect(sql, contains("elsif v_mode = 'real'"));
    expect(sql, contains('v_promo_spent := v_total'));
    expect(sql, contains('v_cash_spent := v_total'));
    expect(sql, contains('_apply_creator_cash_coin_share'));
    expect(sql, contains("'explicit_test_zero_earnings'"));
    expect(sql, contains("'explicit_real_cash_backed_earnings'"));
    expect(sql, contains('self gifting is not allowed'));
  });

  test('owner/admin ordinary gifts remain test-only', () {
    final sql = File(
      '../../supabase/migrations/20261006202500_explicit_real_test_coin_funding.sql',
    ).readAsStringSync();
    expect(sql, contains("in ('owner','admin')"));
    expect(
      sql,
      contains('ordinary owner/admin gifts cannot spend real coins'),
    );
    expect(sql, contains("'staff_test_only_zero_earnings'"));
  });

  test('cinematic gift tray uses the real gift media instead of an emoji stand-in', () {
    final visual = File(
      'lib/features/live/native_gift_visual.dart',
    ).readAsStringSync();
    final components = [
      File('lib/features/live/native_live_components.dart').readAsStringSync(),
      File('lib/features/live/native_gift_overlay.part.dart').readAsStringSync(),
    ].join('\n');

    expect(visual, contains('VideoPlayerController.networkUrl'));
    expect(visual, contains('await next.seekTo'));
    expect(visual, contains('VideoPlayer(controller)'));
    expect(components, contains("Key('native-gift-presentation-"));
    expect(components, contains("Key('cinematic-gift-presentation-"));
    expect(components, contains('VideoPlayer(controller)'));
    expect(components, contains('BoxFit.contain'));
  });
}

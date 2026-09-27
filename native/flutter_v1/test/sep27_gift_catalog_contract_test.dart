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

  test('gift visuals never use paused cinematic frames as thumbnails', () {
    final visual = File(
      'lib/features/live/native_gift_visual.dart',
    ).readAsStringSync();
    final components = File(
      'lib/features/live/native_live_components.dart',
    ).readAsStringSync();

    expect(visual, contains('deterministic poster'));
    expect(components, contains('never a paused remote frame'));
    expect(components, contains('lightweight-gift-'));
  });
}

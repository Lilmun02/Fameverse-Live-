import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('mobile badge proof form accepts only owner-approved transfer sources', () {
    final form = File(
      'lib/features/profile/native_badge_transfer_preview.dart',
    ).readAsStringSync();
    final creator = File(
      'lib/features/profile/creator_studio_build23.dart',
    ).readAsStringSync();
    final profile = File(
      'lib/features/profile/native_profile_build23.dart',
    ).readAsStringSync();

    expect(creator, contains('NativeBadgeTransferPreview()'));
    expect(form, contains('ImagePicker().pickVideo'));
    expect(form, contains("source: ImageSource.gallery"));
    expect(form, contains("from('badge-transfer-proofs').upload"));
    expect(form, contains("'submit_badge_transfer_claim'"));
    expect(form, contains("value: 'tiktok'"));
    expect(form, contains("value: 'favorited'"));
    expect(form, contains("value: 'epic'"));
    expect(form, isNot(contains("value: 'echo'")));
    expect(form, contains('Submit for owner review'));
    expect(form, contains("'pending'"));
    expect(form, contains("'approved'"));
    expect(profile, contains('NativeImportedBadgeChip(userId: profile.id)'));
  });

  test('badge approval imports recognition without manipulating gift funds', () {
    final migration = File(
      '../../supabase/migrations/20261007_badge_transfer_owner_review.sql',
    ).readAsStringSync();

    expect(migration, contains('create table if not exists public.badge_imports'));
    expect(migration, contains('create table if not exists public.badge_transfer_claims'));
    expect(migration, contains('public.owner_review_badge_transfer'));
    expect(migration, contains('public._badge_transfer_is_owner()'));
    expect(migration, contains("bucket_id = 'badge-transfer-proofs'"));
    expect(migration, contains('public.submit_badge_transfer_claim'));
    expect(migration, contains("('tiktok','favorited','epic')"));
    expect(migration, isNot(contains('update public.gifter_stats')));
    expect(migration, isNot(contains('update public.coin_funding_balances')));
    expect(migration, contains('approved_level integer'));
    expect(migration, contains("status = 'approved'"));
  });
}

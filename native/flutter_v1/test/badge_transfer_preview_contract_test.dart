import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'Badge Transfer preview stays read-only and follows approved rules',
    () async {
      final studio = await File(
        'lib/features/profile/creator_studio_screen.dart',
      ).readAsString();

      expect(studio, contains("Key('badge-transfer-preview-card')"));
      expect(studio, contains("'Bring your badge'"));
      expect(studio, contains("_BadgeSourceChip('TikTok')"));
      expect(studio, contains("_BadgeSourceChip('Favorited')"));
      expect(studio, contains("_BadgeSourceChip('EPIC')"));
      expect(studio, isNot(contains("_BadgeSourceChip('Echo')")));
      expect(studio, contains('screen recording'));
      expect(studio, contains('Mismatch = denied'));
      expect(studio, contains('Only one transferred badge can be active'));
      expect(studio, contains("'COMING SOON'"));
    },
  );

  test('Build 33 private device candidate keeps imported levels inactive', () {
    final creator = File(
      'lib/features/profile/creator_studio_build23.dart',
    ).readAsStringSync();
    final preview = File(
      'lib/features/profile/native_badge_transfer_preview.dart',
    ).readAsStringSync();

    expect(creator, contains('NativeBadgeTransferPreview'));
    expect(preview, contains("Key('badge-transfer-preview-card')"));
    expect(preview, contains('COMING SOON'));
    expect(preview, contains('TikTok, Favorited, or EPIC'));
    expect(preview, contains('screen recording'));
    expect(preview, isNot(contains('pickVideo')));
    expect(preview, isNot(contains('submit_badge_transfer_claim')));
    expect(preview, isNot(contains('transferLevel')));
  });
}

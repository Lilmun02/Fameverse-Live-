import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'Pro Live remains a read-only 10 percent teaser in this candidate',
    () async {
      final studio = await File(
        'lib/features/profile/creator_studio_screen.dart',
      ).readAsString();
      final roadmap = await File(
        '../../docs/PRO_LIVE_ACHIEVEMENTS_ROADMAP.md',
      ).readAsString();

      expect(studio, contains("Key('pro-live-preview-card')"));
      expect(studio, contains("'Fameverse Pro Live Achievements'"));
      expect(studio, contains("'10% PREVIEW'"));
      expect(studio, contains("'Silver  •  Gold  •  Diamond'"));
      expect(studio, contains('ImageFiltered('));
      expect(studio, contains('ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8)'));
      expect(studio, contains('ExcludeSemantics('));
      expect(studio, contains("'90% hidden until the feature is ready'"));

      // The roadmap preserves the CEO-approved rules without activating them.
      expect(roadmap, contains('100,000 Fame Coins per week'));
      expect(roadmap, contains('one missed week is allowed'));
      expect(roadmap, contains('500,000 Fame Coins per month'));
      expect(roadmap, contains('one missed month is allowed'));
      expect(roadmap, contains('1,000,000 Fame Coins per month'));
      expect(roadmap, contains('Grace rule: none'));
      expect(
        roadmap,
        contains('No database tables, counters, automatic qualification'),
      );
    },
  );
}

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

String read(String path) => File(path).readAsStringSync();

void main() {
  test('owner/admin bypasses First Verse UI locks without fake completion', () {
    final backend = read('lib/data/fameverse_beta_backend.dart');
    final firstVerse = read(
      'lib/features/profile/first_verse_beta_screen.dart',
    );
    final shell = read('lib/features/shell/fameverse_shell_build16.dart');

    expect(backend, contains("role == 'owner' || role == 'admin'"));
    expect(backend, contains('privilegedAccess'));
    expect(backend, contains('enrolled: enrolled || value'));
    expect(backend, contains('badgeUnlocked: badgeUnlocked'));
    expect(backend, contains('completedRequired: completedRequired'));

    expect(firstVerse, contains("Key('first-verse-owner-preview')"));
    expect(firstVerse, contains('OWNER / ADMIN PREVIEW · NO FEATURE LOCKS'));
    expect(
      firstVerse,
      contains('if (unlocked || privilegedPreview) return badge;'),
    );
    expect(firstVerse, contains('without faking mission completion'));

    expect(
      shell,
      contains("_accountRole == 'owner' || _accountRole == 'admin'"),
    );
    expect(
      shell,
      contains(
        '_betaStatus.enrolled && !_betaStatus.badgeUnlocked && !_isPrivileged',
      ),
    );
  });
}

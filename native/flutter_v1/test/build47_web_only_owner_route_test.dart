import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Build 47 web-only Owner Command Center regression', () {
    test('native Creator Studio never routes to a privileged owner panel', () {
      final shell = File(
        'lib/features/shell/fameverse_shell_build23.dart',
      ).readAsStringSync();

      expect(shell, contains('Future<void> _openCreatorStudio('));
      expect(shell, contains('_openPersonalCreatorStudio(currentProfile);'));
      expect(shell, isNot(contains('Build23OwnerControlCenterScreen(')));
      expect(shell, isNot(contains("import '../profile/owner_control_center_build23.dart';")));
      expect(shell, contains('account.profile.id != widget.identity.id'));
      expect(shell, contains('_loadAuthoritativeAccount()'));
    });
  });
}

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Fameverse owner authorization and regression guards', () {
    test('TestFlight source remains locked to the canonical branch', () {
      final codemagic = File('../../codemagic.yaml').readAsStringSync();

      expect(
        codemagic,
        contains('TARGET_BRANCH="integration/sep27-big-update"'),
      );
      expect(codemagic, isNot(contains('TARGET_BRANCH="qa/')));
      expect(codemagic, contains('FAMEVERSE_SOURCE_SHA='));
      expect(codemagic, contains('flutter build ipa --release'));
      expect(codemagic, contains('Verify required TestFlight secrets'));
    });

    test('physical iPhone release acceptance cannot be bypassed', () {
      final workflow = File(
        '../../.github/workflows/native-preflight.yml',
      ).readAsStringSync();
      final gate = File(
        '../../scripts/check-native-physical-acceptance.mjs',
      ).readAsStringSync();

      expect(workflow, contains('Physical iPhone release gate'));
      expect(
        workflow,
        contains('node scripts/check-native-physical-acceptance.mjs'),
      );
      expect(gate, contains("manifest.status, 'passed'"));
      expect(gate, contains("manifest.owner_iphone, 'owner iPhone'"));
      expect(
        gate,
        contains("manifest.external_tester_iphone, 'external tester iPhone'"),
      );
      expect(gate, contains('manifest.fingerprint'));
      expect(gate, contains("['merge-base', '--is-ancestor'"));
    });

    test('owner-approved restrictions and retired gift remain recorded', () {
      final rules = File('../../AGENTS.md').readAsStringSync();
      final backend = File(
        'lib/data/fameverse_live_backend.dart',
      ).readAsStringSync();

      expect(rules, contains('No fake completion'));
      expect(rules, contains('Pocket Comet'));
      expect(rules, contains('owner explicitly'));
      expect(backend, isNot(contains("id: 'pocket-comet'")));
    });

    test('sensitive changes route to the owner for review', () {
      final owners = File('../../.github/CODEOWNERS').readAsStringSync();
      expect(owners, contains('* @Lilmun02'));
      expect(owners, contains('/codemagic.yaml @Lilmun02'));
      expect(owners, contains('/supabase/ @Lilmun02'));
      expect(owners, contains('/.github/workflows/ @Lilmun02'));
      expect(
        owners,
        contains('/scripts/check-native-physical-acceptance.mjs @Lilmun02'),
      );
    });
  });
}

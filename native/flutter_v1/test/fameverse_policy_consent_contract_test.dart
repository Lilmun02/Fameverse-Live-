import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('consent uses authenticated server RPC, never a local accept flag', () {
    final source = File(
      'lib/features/auth/fameverse_policy_agreement_gate.dart',
    ).readAsStringSync();
    expect(source, contains("rpc('fv_get_policy_requirement')"));
    expect(source, contains("rpc('fv_accept_current_policy')"));
    expect(source, contains("recheck['accepted'] != true"));
    expect(source, contains("key: const Key('policy-consent-checkbox')"));
    expect(source, contains('_checked && !_saving && _policy != null'));
    expect(source, isNot(contains('SharedPreferences')));
  });

  test('policy rollout is explicitly gated to protect existing beta', () {
    final source = File('lib/app/fameverse_app.dart').readAsStringSync();
    expect(source, contains("'FAMEVERSE_POLICY_GATE_ENABLED'"));
    expect(source, contains('defaultValue: false'));
    expect(source, contains('FameversePolicyAgreementGate('));
  });
}

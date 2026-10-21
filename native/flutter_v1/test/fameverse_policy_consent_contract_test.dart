import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('native policy decisions use verified backend, not local acceptance', () {
    final source = File(
      'lib/features/auth/fameverse_policy_agreement_gate.dart',
    ).readAsStringSync();

    expect(source, contains("'fv_get_policy_requirement'"));
    expect(source, contains("'fv_accept_current_policy'"));
    expect(source, contains("'fv_decline_current_policy'"));
    expect(source, contains("recheck['accepted'] != true"));
    expect(source, contains("recheck['decision'] != 'declined'"));
    expect(source, contains("key: const Key('policy-decline-continue')"));
    expect(source, contains("key: const Key('policy-pending-continue')"));
    expect(source, contains('if (_accepted || _limited) return widget.child'));
    expect(source, isNot(contains('SharedPreferences')));
  });

  test('backend stages consent records and protected feature boundaries', () {
    final sql = File(
      '../../docs/POLICY_ENFORCEMENT_STAGING_SCHEMA.sql',
    ).readAsStringSync();

    expect(sql, contains('fv_policy_decisions'));
    expect(sql, contains('PRIMARY KEY (user_id, version)'));
    expect(sql, contains('fv_decline_current_policy'));
    expect(sql, contains('fv_policy_permissions'));
    expect(sql, contains("2026-10-26T04:00:00Z"));
    expect(sql, contains("p_feature IN ('watch_live','profile','browse','inbox','settings','support')"));
    expect(sql, contains("RETURN p_feature = 'send_gift'"));
    expect(sql, contains('fv_policy_gate_live_host'));
    expect(sql, contains('fv_policy_gate_gift'));
    expect(sql, contains('fv_policy_gate_coin_order'));
  });

  test('policy gate stays disabled until backend and iPhone QA pass', () {
    final source = File('lib/app/fameverse_app.dart').readAsStringSync();
    expect(source, contains("'FAMEVERSE_POLICY_GATE_ENABLED'"));
    expect(source, contains('defaultValue: false'));
    expect(source, contains('FameversePolicyAgreementGate('));
  });
}

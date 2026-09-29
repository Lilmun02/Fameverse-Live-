import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Build 23 startup and owner identity regressions stay locked', () {
    final app = File('lib/app/fameverse_app.dart').readAsStringSync();
    final shell = File(
      'lib/features/shell/fameverse_shell_build23.dart',
    ).readAsStringSync();
    final profile = File(
      'lib/features/profile/native_profile_build23.dart',
    ).readAsStringSync();
    final iosBranding = File('tool/apply_ios_branding.sh').readAsStringSync();
    final iosVerify = File('tool/verify_ios_branding.sh').readAsStringSync();
    final identityMigration = File(
      '../../supabase/migrations/20260929_authoritative_current_identity_contract.sql',
    ).readAsStringSync();

    expect(
      app,
      contains('WidgetsBinding.instance.addPostFrameCallback'),
      reason: 'Splash timing must start after Flutter renders its first frame.',
    );
    expect(
      app,
      contains('Duration(milliseconds: 1500)'),
      reason: 'The visible branded splash must not collapse into a flash.',
    );
    expect(
      iosBranding,
      contains('FAMEVERSE_NATIVE_LAUNCH_DARK'),
      reason: 'Native iOS launch must replace Flutter default white startup.',
    );
    expect(
      iosVerify,
      contains('white native LaunchScreen background returned'),
      reason: 'CI must reject any return of the white native launch screen.',
    );
    expect(
      identityMigration,
      contains('get_my_fameverse_identity'),
      reason: 'Backend must provide one authoritative profile + role response.',
    );
    expect(
      shell,
      contains("rpc('get_my_fameverse_identity')"),
      reason: 'Build 23 shell must actually consume the authoritative identity RPC.',
    );
    expect(
      shell,
      contains("throw StateError('current-account-mismatch')"),
      reason: 'A stale profile must never be accepted for another auth session.',
    );
    expect(
      shell,
      contains('final account = await _loadAuthoritativeAccount();'),
      reason: 'Owner routing must revalidate account authority before navigation.',
    );
    expect(
      profile,
      contains("label: isOwner ? 'Owner Control Center' : 'Creator Studio'"),
      reason: 'Owner Settings must visibly expose Owner Control Center.',
    );
  });
}

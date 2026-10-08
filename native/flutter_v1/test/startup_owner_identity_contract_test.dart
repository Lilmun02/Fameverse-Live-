import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('current startup and owner identity regressions stay locked', () {
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
      contains('Duration(milliseconds: 2500)'),
      reason:
          'The branded splash must remain visibly on-screen for 2.5 seconds.',
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
      contains('get_my_fameverse_identity'),
      reason:
          'Current shell must actually consume the authoritative identity RPC.',
    );
    expect(
      shell,
      contains("throw StateError('current-account-mismatch')"),
      reason:
          'A stale profile must never be accepted for another auth session.',
    );
    expect(
      shell,
      contains('final account = await _loadAuthoritativeAccount();'),
      reason:
          'Creator Studio navigation must revalidate account authority before navigation.',
    );
    expect(
      shell,
      isNot(contains('Build23OwnerControlCenterScreen')),
      reason: 'Native owner/admin operations must stay out of the iPhone app.',
    );
    expect(
      profile,
      contains("label: 'Creator Studio'"),
      reason:
          'Owner and creator accounts must enter the same native Creator Studio.',
    );
    expect(
      profile,
      isNot(contains('Owner Studio')),
      reason: 'Native profile must not expose the retired Owner Studio route.',
    );
  });
}

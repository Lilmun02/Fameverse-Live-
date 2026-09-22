import 'dart:io';

void require(bool condition, String message) {
  if (!condition) {
    stderr.writeln('[native-foundation-law] $message');
    exitCode = 1;
  }
}

String read(String path) => File(path).readAsStringSync();

void main() {
  final constitution = read('../../docs/ENGINEERING_CONSTITUTION.md');
  final parity = read('../../docs/NATIVE_PARITY_MATRIX.md');
  final gates = read('../../docs/NATIVE_RELEASE_GATES.md');
  final codemagic = read('../../codemagic.yaml');
  final app = read('lib/app/fameverse_app.dart');
  final test = read('test/app_smoke_test.dart');

  require(
    constitution.contains('Physical device behavior outranks simulation'),
    'Constitution must preserve physical-device authority.',
  );
  require(
    constitution.contains('FIX_CANDIDATE'),
    'Constitution must preserve explicit bug states.',
  );
  require(
    parity.contains('Camera flip') && parity.contains('Premium cinematics'),
    'Parity matrix must track device-sensitive Live and gift migration.',
  );
  require(
    gates.contains('FIX_CANDIDATE -> LOCKED'),
    'Release gates must prevent CI-only lock claims.',
  );
  require(
    codemagic.contains('flutter analyze'),
    'Codemagic must run Flutter static analysis.',
  );
  require(
    codemagic.contains('flutter test'),
    'Codemagic must run Flutter tests.',
  );
  require(
    codemagic.contains('flutter build apk --debug'),
    'Codemagic must prove Android builds during bootstrap.',
  );
  require(
    codemagic.contains('flutter build ios --debug --no-codesign'),
    'Codemagic must prove iOS builds before signing is enabled.',
  );

  final testflightWorkflow = codemagic.indexOf('  native-testflight:');
  if (testflightWorkflow == -1) {
    require(
      !codemagic.contains('\n    publishing:'),
      'Bootstrap-only configuration must not publish before a dedicated signed release workflow exists.',
    );
  } else {
    final bootstrapSection = codemagic.substring(0, testflightWorkflow);
    final releaseSection = codemagic.substring(testflightWorkflow);

    require(
      !bootstrapSection.contains('\n    publishing:'),
      'Bootstrap workflow must remain non-publishing.',
    );
    require(
      releaseSection.contains('BUNDLE_ID: "com.fameverse.live"'),
      'TestFlight workflow must use the locked Fameverse bundle identifier.',
    );
    require(
      releaseSection.contains('flutter build ipa --release'),
      'TestFlight workflow must build a signed release IPA.',
    );

    final usesEnvironmentPublishing =
        releaseSection.contains('app_store_connect:') &&
        releaseSection.contains('api_key: \$APP_STORE_CONNECT_PRIVATE_KEY') &&
        releaseSection.contains('key_id: \$APP_STORE_CONNECT_KEY_IDENTIFIER') &&
        releaseSection.contains('issuer_id: \$APP_STORE_CONNECT_ISSUER_ID') &&
        releaseSection.contains('- appstore_credentials');

    require(
      usesEnvironmentPublishing,
      'TestFlight publishing must use authorized App Store Connect environment credentials.',
    );

    final usesDirectManualSigning =
        releaseSection.contains('- manual_signing') &&
        releaseSection.contains('\$CM_CERTIFICATE') &&
        releaseSection.contains('\$CM_CERTIFICATE_PASSWORD') &&
        releaseSection.contains('\$CM_PROVISIONING_PROFILE') &&
        releaseSection.contains('base64 --decode') &&
        releaseSection.contains('keychain add-certificates') &&
        releaseSection.contains('xcode-project use-profiles') &&
        !releaseSection.contains('ios_signing:');

    require(
      usesDirectManualSigning,
      'TestFlight must bypass Codemagic signing-identity resolution and install manual signing assets directly.',
    );
  }

  require(
    app.contains('Native pipeline probe'),
    'Bootstrap UI must remain clearly identified as a probe, not approved product UI.',
  );
  require(
    test.contains('native pipeline probe boots'),
    'Bootstrap app must have a widget smoke test.',
  );

  if (exitCode == 0) {
    stdout.writeln(
      '[native-foundation-law] constitution, parity, CI, direct signing, publishing, and probe contracts passed',
    );
  }
}

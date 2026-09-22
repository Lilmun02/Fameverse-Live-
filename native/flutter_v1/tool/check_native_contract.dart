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
      releaseSection.contains('bundle_identifier: com.fameverse.live'),
      'TestFlight workflow must use the locked Fameverse bundle identifier.',
    );
    require(
      releaseSection.contains('distribution_type: app_store'),
      'TestFlight workflow must use App Store distribution signing.',
    );
    require(
      releaseSection.contains('flutter build ipa --release'),
      'TestFlight workflow must build a signed release IPA.',
    );
    require(
      releaseSection.contains('app_store_connect:') &&
          releaseSection.contains('auth: integration'),
      'TestFlight publishing must use the authorized App Store Connect integration.',
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
      '[native-foundation-law] constitution, parity, CI, signing separation, and probe contracts passed',
    );
  }
}

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

  require(constitution.contains('Physical device behavior outranks simulation'),
      'Constitution must preserve physical-device authority.');
  require(constitution.contains('FIX_CANDIDATE'),
      'Constitution must preserve explicit bug states.');
  require(parity.contains('Camera flip') && parity.contains('Premium cinematics'),
      'Parity matrix must track device-sensitive Live and gift migration.');
  require(gates.contains('FIX_CANDIDATE -> LOCKED'),
      'Release gates must prevent CI-only lock claims.');
  require(codemagic.contains('flutter analyze'),
      'Codemagic must run Flutter static analysis.');
  require(codemagic.contains('flutter test'),
      'Codemagic must run Flutter tests.');
  require(codemagic.contains('flutter build apk --debug'),
      'Codemagic must prove Android builds during bootstrap.');
  require(codemagic.contains('flutter build ios --debug --no-codesign'),
      'Codemagic must prove iOS builds before signing is enabled.');
  require(!codemagic.contains('\n    publishing:'),
      'Bootstrap workflow must not publish before signing/release approval.');
  require(app.contains('Native pipeline probe'),
      'Bootstrap UI must remain clearly identified as a probe, not approved product UI.');
  require(test.contains('native pipeline probe boots'),
      'Bootstrap app must have a widget smoke test.');

  if (exitCode == 0) {
    stdout.writeln('[native-foundation-law] constitution, parity, CI, and probe contracts passed');
  }
}

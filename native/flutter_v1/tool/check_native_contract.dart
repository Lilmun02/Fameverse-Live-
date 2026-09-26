import 'dart:io';

void require(bool condition, String message) {
  if (!condition) {
    stderr.writeln('[native-foundation-law] $message');
    exitCode = 1;
  }
}

String read(String path) => File(path).readAsStringSync();

void main() {
  final stage = Platform.environment['FAMEVERSE_NATIVE_STAGE'] ?? '';
  final cmBranch = Platform.environment['CM_BRANCH'] ?? '';

  // Release-provenance law: the stale base branch may still be used for
  // bootstrap/preflight work, but it must never publish another TestFlight
  // candidate while Build 18 repair is under physical QA. This specifically
  // prevents Codemagic from silently uploading the old Profile/Live UI again.
  if (stage == 'testflight') {
    require(
      cmBranch == 'build18/live-repair',
      'BLOCKED: TestFlight candidate is not sourced from build18/live-repair. '
      'Do not upload stale native/flutter-v1 product code.',
    );
  }

  final constitution = read('../../docs/ENGINEERING_CONSTITUTION.md');
  final parity = read('../../docs/NATIVE_PARITY_MATRIX.md');
  final providerLock = read('../../docs/NATIVE_MEDIA_PROVIDER_LOCK.md');
  final gates = read('../../docs/NATIVE_RELEASE_GATES.md');
  final codemagic = read('../../codemagic.yaml');
  final app = read('lib/app/fameverse_app.dart');
  final backend = read('lib/data/fameverse_backend.dart');
  final liveBackend = read('lib/data/fameverse_live_backend.dart');
  final camera = read('lib/features/live/native_camera_screen.dart');
  final liveExports = read('lib/features/live/stream_live_screen.dart');
  final hostLive = read('lib/features/live/stream_host_live_screen.dart');
  final viewerLive = read('lib/features/live/stream_viewer_live_screen.dart');
  final liveMedia = '$liveExports\n$hostLive\n$viewerLive';
  final shell = read('lib/features/shell/fameverse_shell.dart');
  final pubspec = read('pubspec.yaml');
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
    providerLock.contains('Stream Video') &&
        providerLock.contains('explicit product-owner approval'),
    'Native media provider lock must preserve the approved Stream architecture.',
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
    app.contains('productShellKey') &&
        !app.contains('Native pipeline probe') &&
        shell.contains('fameverse-bottom-nav'),
    'Native TestFlight app must boot the Fameverse product shell, not the pipeline probe.',
  );
  require(
    backend.contains('SupabaseFameverseBackend') &&
        backend.contains("from('profiles')") &&
        backend.contains("from('follows')") &&
        backend.contains("from('live_rooms')"),
    'Native product shell must reuse authoritative Supabase identity/community/live contracts.',
  );
  require(
    pubspec.contains('stream_video_flutter: 1.6.0') &&
        !pubspec.contains('livekit_client') &&
        camera.contains('CameraController') &&
        camera.contains('native-go-live') &&
        hostLive.contains('flipCamera()') &&
        liveMedia.contains('StreamVideo(') &&
        liveMedia.contains('StreamCallType.liveStream()') &&
        liveMedia.contains('setMicrophoneEnabled') &&
        liveMedia.contains('NativeViewerLiveScreen') &&
        liveBackend.contains("'stream-token'") &&
        liveBackend.contains("from('live_rooms')") &&
        !liveBackend.contains("'livekit-token'") &&
        !liveMedia.contains('package:livekit_client'),
    'Native Live migration must use approved Stream Video transport with Supabase-authoritative rooms and an active host camera flip.',
  );
  require(
    !shell.contains('WebView') && !shell.contains('webview'),
    'Native product migration must not hide the PWA inside a WebView.',
  );
  require(
    test.contains('signed-out native product opens account entry') &&
        test.contains('signed-in native product exposes primary navigation'),
    'Native product shell must have account-entry and signed-in navigation widget gates.',
  );

  if (exitCode == 0) {
    stdout.writeln(
      '[native-foundation-law] constitution, parity, CI, direct signing, publishing, product shell, Supabase, Stream Video host/viewer, and camera contracts passed',
    );
  }
}

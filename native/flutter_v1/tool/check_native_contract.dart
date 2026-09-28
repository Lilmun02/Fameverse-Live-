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
  final providerLock = read('../../docs/NATIVE_MEDIA_PROVIDER_LOCK.md');
  final gates = read('../../docs/NATIVE_RELEASE_GATES.md');
  final codemagic = read('../../codemagic.yaml');
  final app = read('lib/app/fameverse_app.dart');
  final backend = read('lib/data/fameverse_backend.dart');
  final liveBackend = read('lib/data/fameverse_live_backend.dart');
  final startupUpdater = read('lib/data/startup_update_service.dart');
  final camera = read('lib/features/live/native_camera_screen.dart');
  final liveExports = read('lib/features/live/stream_live_screen.dart');
  final hostLive = read('lib/features/live/stream_host_live_screen.dart');
  final viewerLive = read('lib/features/live/stream_viewer_live_screen.dart');
  final liveMedia = '$liveExports\n$hostLive\n$viewerLive';
  final shell = read('lib/features/shell/fameverse_shell.dart');
  final build23Shell = read('lib/features/shell/fameverse_shell_build23.dart');
  final build23Home = read('lib/features/shell/fameverse_home_build23.dart');
  final build23Profile = read(
    'lib/features/profile/native_profile_build23.dart',
  );
  final build23Studio = read(
    'lib/features/profile/creator_studio_build23.dart',
  );
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
    require(
      releaseSection.contains('TARGET_BRANCH="integration/sep27-big-update"') &&
          releaseSection.contains('FAMEVERSE_BUILD_FAMILY: "23"') &&
          releaseSection.contains('FAMEVERSE_BUILD_FAMILY=23') &&
          !releaseSection.contains('TARGET_BRANCH="build18/live-repair"'),
      'TestFlight Build 23 must package the repaired integration branch, never the old Build 18 source.',
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
    app.contains('fameverse_shell_build23.dart') &&
        app.contains('FameverseBuild23Shell') &&
        !app.contains('FameverseBuild16Shell'),
    'Build 23 startup must route the current product shell instead of silently launching Build 16.',
  );
  require(
    app.contains('startup_update_service.dart') &&
        app.contains('FvStartupUpdateService') &&
        startupUpdater.contains("from('app_update_notices')"),
    'The active backend updater must remain wired into startup.',
  );
  require(
    build23Home.contains('home-live-feed-tab') &&
        build23Home.contains('home-story-feed-tab') &&
        build23Home.contains('_StoryRail(') &&
        build23Home.indexOf('_StoryRail(') < build23Home.indexOf("'LIVE NOW'"),
    'Home must preserve Stories above Live and the Live Feed / Story Feed top navigation.',
  );
  require(
    build23Profile.contains('settings-first-verse-entry') &&
        build23Profile.contains('settings-first-verse-progress') &&
        build23Profile.contains('status.progress') &&
        !build23Shell.contains('first-verse-tester-entry') &&
        !build23Shell.contains('_HomeStoryLauncher'),
    'First Verse must live in Settings with its real progress bar, not as a floating profile/home control.',
  );
  require(
    build23Profile.contains('FAMEVERSE OWNER • PREMIUM') &&
        build23Studio.contains('Premium owner access') &&
        !build23Studio.contains('ImageFiltered') &&
        !build23Studio.contains('ImageFilter.blur') &&
        build23Studio.contains('Promotional (non-withdrawable)'),
    'Owner premium surfaces must stay readable and promo QA value must remain separate from withdrawable cash.',
  );

  final keepsAuthoritativeCommunityContracts =
      backend.contains("from('profiles')") &&
      backend.contains("from('follows')");
  final keepsAuthoritativeLiveContracts =
      backend.contains("from('live_rooms')") ||
      backend.contains("'get_active_live_rooms_v2'");

  require(
    backend.contains('SupabaseFameverseBackend') &&
        keepsAuthoritativeCommunityContracts &&
        keepsAuthoritativeLiveContracts,
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
      '[native-foundation-law] constitution, Build 23 release source, updater, feed navigation, First Verse settings, owner premium, promo separation, Supabase, Stream Video, signing, and camera contracts passed',
    );
  }
}

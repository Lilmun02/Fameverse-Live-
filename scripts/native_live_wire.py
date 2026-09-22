from pathlib import Path
import re


def must_replace(text: str, old: str, new: str, label: str) -> str:
    if old not in text:
        raise SystemExit(f"missing expected block: {label}")
    return text.replace(old, new)


shell = Path("native/flutter_v1/lib/features/shell/fameverse_shell.dart")
text = shell.read_text()
text = must_replace(
    text,
    "import '../../data/fameverse_backend.dart';\nimport '../live/native_camera_screen.dart';",
    "import '../../data/fameverse_backend.dart';\nimport '../../data/fameverse_live_backend.dart';\nimport '../live/livekit_live_screen.dart';\nimport '../live/native_camera_screen.dart';",
    "shell imports",
)
text = must_replace(
    text,
    "  const FameverseShell({\n    required this.backend,\n    required this.identity,\n    super.key,\n  });\n\n  final FameverseBackend backend;\n  final FvIdentity identity;",
    "  const FameverseShell({\n    required this.backend,\n    required this.liveBackend,\n    required this.identity,\n    super.key,\n  });\n\n  final FameverseBackend backend;\n  final FameverseLiveBackend liveBackend;\n  final FvIdentity identity;",
    "shell constructor",
)
text = must_replace(
    text,
    "        onRoomSelected: (room) {\n          showModalBottomSheet<void>(\n            context: context,\n            showDragHandle: true,\n            builder: (context) => _ViewerMigrationSheet(room: room),\n          );\n        },",
    "        onRoomSelected: (room) {\n          Navigator.of(context).push<void>(\n            MaterialPageRoute(\n              builder: (context) => NativeViewerLiveScreen(\n                liveBackend: widget.liveBackend,\n                room: room,\n              ),\n            ),\n          );\n        },",
    "viewer navigation",
)
text = must_replace(
    text,
    "      const NativeCameraScreen(),",
    "      NativeCameraScreen(\n        liveBackend: widget.liveBackend,\n        identity: widget.identity,\n        profile: profile,\n        onLiveEnded: _refreshAll,\n      ),",
    "host live tab",
)
text = re.sub(
    r"\nclass _ViewerMigrationSheet extends StatelessWidget \{.*?\n\}\n\nclass _LiveRoomCard",
    "\nclass _LiveRoomCard",
    text,
    flags=re.S,
)
if "_ViewerMigrationSheet" in text:
    raise SystemExit("viewer migration placeholder was not removed")
shell.write_text(text)

camera = Path("native/flutter_v1/lib/features/live/native_camera_screen.dart")
ctext = camera.read_text().replace(
    "            initialCameraPosition: _cameraPosition,\n",
    "",
)
camera.write_text(ctext)

test = Path("native/flutter_v1/test/app_smoke_test.dart")
t = test.read_text()
t = must_replace(
    t,
    "import 'package:fameverse_live/data/fameverse_backend.dart';",
    "import 'package:fameverse_live/data/fameverse_backend.dart';\nimport 'package:fameverse_live/data/fameverse_live_backend.dart';",
    "test live backend import",
)
t = must_replace(
    t,
    "FameverseApp(backend: _FakeBackend())",
    "FameverseApp(backend: _FakeBackend(), liveBackend: _FakeLiveBackend())",
    "signed out app construction",
)
t = must_replace(
    t,
    "FameverseApp(backend: _FakeBackend(identity: identity))",
    "FameverseApp(\n        backend: _FakeBackend(identity: identity),\n        liveBackend: _FakeLiveBackend(),\n      )",
    "signed in app construction",
)
t += r'''

class _FakeLiveBackend implements FameverseLiveBackend {
  @override
  Future<FvLiveRoom> startLiveRoom({
    required FvIdentity identity,
    required FvProfile profile,
    required String title,
  }) async {
    return FvLiveRoom(
      id: 'room-1',
      hostUserId: identity.id,
      title: title.isEmpty ? 'Live on Fameverse' : title,
      fameTaps: 0,
      host: profile,
    );
  }

  @override
  Future<void> heartbeatLiveRoom({
    required String roomId,
    required String hostUserId,
  }) async {}

  @override
  Future<void> endLiveRoom({
    required String roomId,
    required String hostUserId,
  }) async {}

  @override
  Future<FvLiveCredentials> issueLiveCredentials({
    required String roomId,
    required String role,
  }) async {
    return const FvLiveCredentials(
      serverUrl: 'wss://example.invalid',
      participantToken: 'test-token',
      roomName: 'fv_room-1',
    );
  }
}
'''
test.write_text(t)

contract = Path("native/flutter_v1/tool/check_native_contract.dart")
ct = contract.read_text()
ct = must_replace(
    ct,
    "  final backend = read('lib/data/fameverse_backend.dart');\n  final camera = read('lib/features/live/native_camera_screen.dart');",
    "  final backend = read('lib/data/fameverse_backend.dart');\n  final liveBackend = read('lib/data/fameverse_live_backend.dart');\n  final camera = read('lib/features/live/native_camera_screen.dart');\n  final liveMedia = read('lib/features/live/livekit_live_screen.dart');",
    "contract live file reads",
)
ct = must_replace(
    ct,
    "    camera.contains('CameraPreview') &&\n        camera.contains('availableCameras') &&\n        camera.contains('Flip camera'),\n    'Native Live migration must use the device camera plugin and preserve a real flip control.',",
    "    camera.contains('LocalVideoTrack.createCameraTrack') &&\n        camera.contains('Flip camera') &&\n        camera.contains('native-go-live') &&\n        liveMedia.contains('setMicrophoneEnabled') &&\n        liveMedia.contains('NativeViewerLiveScreen') &&\n        liveBackend.contains(\"'livekit-token'\") &&\n        liveBackend.contains(\"from('live_rooms')\"),\n    'Native Live migration must use native LiveKit camera/mic transport with real host and viewer room wiring.',",
    "native live engineering law",
)
ct = ct.replace(
    "product shell, Supabase, and native camera contracts passed",
    "product shell, Supabase, native LiveKit host/viewer, and camera contracts passed",
)
contract.write_text(ct)

camera_block = '''          /usr/libexec/PlistBuddy \\
            -c "Set :NSCameraUsageDescription Fameverse Live uses the camera for native live preview and hosting." \\
            ios/Runner/Info.plist 2>/dev/null || \\
          /usr/libexec/PlistBuddy \\
            -c "Add :NSCameraUsageDescription string Fameverse Live uses the camera for native live preview and hosting." \\
            ios/Runner/Info.plist'''
mic_block = camera_block + '''

          /usr/libexec/PlistBuddy \\
            -c "Set :NSMicrophoneUsageDescription Fameverse Live uses the microphone for native live hosting." \\
            ios/Runner/Info.plist 2>/dev/null || \\
          /usr/libexec/PlistBuddy \\
            -c "Add :NSMicrophoneUsageDescription string Fameverse Live uses the microphone for native live hosting." \\
            ios/Runner/Info.plist'''

for path in ["codemagic.yaml", ".github/workflows/native-preflight.yml"]:
    p = Path(path)
    x = p.read_text()
    if camera_block not in x:
        raise SystemExit(f"camera plist block missing in {path}")
    p.write_text(x.replace(camera_block, mic_block))

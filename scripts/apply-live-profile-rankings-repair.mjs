import fs from 'node:fs'

function read(path) {
  return fs.readFileSync(path, 'utf8')
}

function write(path, value) {
  fs.writeFileSync(path, value)
}

function replaceOnce(path, before, after) {
  const source = read(path)
  const first = source.indexOf(before)
  if (first < 0) throw new Error(`Expected patch target missing in ${path}`)
  if (source.indexOf(before, first + before.length) >= 0) {
    throw new Error(`Patch target is ambiguous in ${path}`)
  }
  write(path, source.slice(0, first) + after + source.slice(first + before.length))
}

function replaceBetween(path, startMarker, endMarker, replacement) {
  const source = read(path)
  const start = source.indexOf(startMarker)
  const end = source.indexOf(endMarker, start)
  if (start < 0 || end < 0 || end <= start) {
    throw new Error(`Expected bounded patch target missing in ${path}`)
  }
  write(path, source.slice(0, start) + replacement + source.slice(end))
}

const host = 'native/flutter_v1/lib/features/live/stream_host_live_screen.dart'
replaceOnce(
  host,
  "import 'native_live_components.dart';\nimport 'native_live_stage.dart';",
  "import 'native_live_components.dart';\nimport 'native_live_profile_sheet.dart';\nimport 'native_live_rankings.dart';\nimport 'native_live_stage.dart';",
)
replaceBetween(
  host,
  '  void _showProfileSheet() {',
  '  void _showViewerSheet() {',
  `  void _showProfileSheet() {\n    unawaited(\n      showNativeLiveProfileSheet(\n        context: context,\n        liveBackend: widget.liveBackend,\n        identity: widget.identity,\n        roomId: widget.room.id,\n        profile: widget.room.host,\n      ),\n    );\n  }\n\n`,
)
replaceOnce(
  host,
  "                        const SizedBox(width: 8),\n                        FilledButton(\n                          key: const Key('native-end-live'),",
  "                        const SizedBox(width: 4),\n                        IconButton(\n                          key: const Key('host-live-rankings-button'),\n                          onPressed: () =>\n                              unawaited(showNativeLiveRankings(context)),\n                          constraints: const BoxConstraints.tightFor(\n                            width: 32,\n                            height: 32,\n                          ),\n                          padding: EdgeInsets.zero,\n                          visualDensity: VisualDensity.compact,\n                          icon: const Icon(\n                            Icons.emoji_events_rounded,\n                            size: 17,\n                            color: Color(0xFFFFC75A),\n                          ),\n                          tooltip: 'Rankings',\n                        ),\n                        const SizedBox(width: 4),\n                        FilledButton(\n                          key: const Key('native-end-live'),",
)

const viewer = 'native/flutter_v1/lib/features/live/stream_viewer_live_screen.dart'
replaceOnce(
  viewer,
  "import 'native_live_components.dart';\nimport 'native_live_stage.dart';",
  "import 'native_live_components.dart';\nimport 'native_live_profile_sheet.dart';\nimport 'native_live_rankings.dart';\nimport 'native_live_stage.dart';",
)
replaceBetween(
  viewer,
  '  void _showProfileSheet() {',
  '  void _showViewerSheet() {',
  `  void _showProfileSheet() {\n    unawaited(\n      showNativeLiveProfileSheet(\n        context: context,\n        liveBackend: widget.liveBackend,\n        backend: widget.backend,\n        identity: widget.identity,\n        roomId: widget.room.id,\n        profile: widget.room.host,\n        onFollowingChanged: (following) {\n          if (mounted) setState(() => _following = following);\n        },\n      ),\n    );\n  }\n\n`,
)
replaceOnce(
  viewer,
  "                          _ViewerStatChip(\n                            icon: Icons.local_fire_department_rounded,\n                            text: '${_fameTaps + _tapBuffer.length}',\n                          ),",
  "                          _ViewerStatChip(\n                            icon: Icons.local_fire_department_rounded,\n                            text: '${_fameTaps + _tapBuffer.length}',\n                          ),\n                          const SizedBox(width: 3),\n                          IconButton(\n                            key: const Key('viewer-live-rankings-button'),\n                            onPressed: () =>\n                                unawaited(showNativeLiveRankings(context)),\n                            constraints: const BoxConstraints.tightFor(\n                              width: 28,\n                              height: 28,\n                            ),\n                            padding: EdgeInsets.zero,\n                            visualDensity: VisualDensity.compact,\n                            icon: const Icon(\n                              Icons.emoji_events_rounded,\n                              size: 16,\n                              color: Color(0xFFFFC75A),\n                            ),\n                            tooltip: 'Rankings',\n                          ),",
)

const contract = `import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Native Live profile and rankings contract', () {
    test('earned gifter badge stays tied to real gifting progression', () {
      final profile = File(
        'lib/features/live/native_live_profile_sheet.dart',
      ).readAsStringSync();
      expect(profile, contains('totalCoinsSent <= 0'));
      expect(profile, contains("label: 'Spark Gifter'"));
      expect(profile, contains("label: 'Silver Gifter'"));
      expect(profile, contains("label: 'Fame Icon'"));
      expect(profile, contains('LinearProgressIndicator'));
      expect(profile, contains("return 'Follow Back'"));
      expect(profile, contains("return 'Friends'"));
      expect(profile, contains('loadViewerIdentityStats'));
    });

    test('rankings use the authoritative backend instead of placeholders', () {
      final rankings = File(
        'lib/features/live/native_live_rankings.dart',
      ).readAsStringSync();
      expect(rankings, contains("'get_fameverse_rankings'"));
      expect(rankings, contains("('gifters', 'Gifters')"));
      expect(rankings, contains("('tappers', 'Tappers')"));
      expect(rankings, contains("('creators', 'Creators')"));
      expect(rankings, contains("'p_limit': 20"));
      expect(rankings, isNot(contains('fake')));
    });

    test('host and viewer both expose Live profile and rankings entry points', () {
      final host = File(
        'lib/features/live/stream_host_live_screen.dart',
      ).readAsStringSync();
      final viewer = File(
        'lib/features/live/stream_viewer_live_screen.dart',
      ).readAsStringSync();
      expect(host, contains('showNativeLiveProfileSheet'));
      expect(viewer, contains('showNativeLiveProfileSheet'));
      expect(host, contains("Key('host-live-rankings-button')"));
      expect(viewer, contains("Key('viewer-live-rankings-button')"));
      expect(host, contains('showNativeLiveRankings'));
      expect(viewer, contains('showNativeLiveRankings'));
    });
  });
}
`
write('native/flutter_v1/test/live_profile_rankings_contract_test.dart', contract)

console.log('Applied native Live profile and rankings repair wiring.')

import 'dart:io';

void main() {
  final replacements = <String, Map<String, String>>{
    'lib/features/live/stream_host_live_screen.dart': <String, String>{
      "const FvLiveBackground(icon: Icons.videocam_off_rounded),":
          'const FvLiveBackground(),',
      '''const Icon(
            Icons.local_fire_department_rounded,
            size: 13,
            color: Color(0xFFFF9D2E),
          ),''':
          'const FvFameTapMark(size: 13),',
    },
    'lib/features/live/native_camera_screen.dart': <String, String>{
      "hintText: 'Example: 1,000 likes or 20 gifts',":
          "hintText: 'Example: 1,000 FameTaps or 20 gifts',",
      '''Cash earnings are not calculated in beta because Fameverse payout conversion is not configured yet.''':
          '''Creator cash earnings stay separate from Fame Coins. Open Creator Studio to see cleared, pending, in-review, and paid earnings.''',
    },
    'lib/features/live/stream_live_shared.dart': <String, String>{
      '''style: TextStyle(
                color: Color(0xFFE1B5FF),''': '''style: TextStyle(
                // Keep this non-const spelling because the locked regression
                // contract verifies the canonical FameTaps purple literal.
                // ignore: prefer_const_constructors
                color: Color(0xFFE1B5FF),''',
    },
    'lib/features/stories/creator_stories_screen_v2.dart': <String, String>{
      '''      }

      final caption = await Navigator.of(context).push<String>(''': '''      }

      if (!mounted) return;
      final caption = await Navigator.of(context).push<String>(''',
    },
  };

  var changed = false;
  for (final entry in replacements.entries) {
    final file = File(entry.key);
    if (!file.existsSync()) {
      stderr.writeln('Missing release source: ${entry.key}');
      exitCode = 1;
      return;
    }

    var source = file.readAsStringSync();
    var fileChanged = false;
    for (final replacement in entry.value.entries) {
      if (!source.contains(replacement.key)) {
        if (!source.contains(replacement.value)) {
          stderr.writeln(
            'Release repair contract drifted in ${entry.key}: '
            'expected old or repaired source was not found.',
          );
          exitCode = 1;
          return;
        }
        continue;
      }
      source = source.replaceFirst(replacement.key, replacement.value);
      fileChanged = true;
    }

    if (fileChanged) {
      file.writeAsStringSync(source);
      stdout.writeln('Applied final release repair: ${entry.key}');
      changed = true;
    }
  }

  if (!changed) {
    stdout.writeln('Final release repair already applied.');
  }
}

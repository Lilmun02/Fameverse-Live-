import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('End Live never waits on SDK/backend cleanup before leaving host UI', () {
    final source = File(
      'lib/features/live/stream_host_live_screen.dart',
    ).readAsStringSync();

    expect(source, contains("FocusManager.instance.primaryFocus?.unfocus()"));
    expect(source, contains("WidgetsBinding.instance.addPostFrameCallback"));
    expect(source, contains("navigator.pop(true)"));
    expect(source, contains("unawaited(_finishEndLive())"));
    expect(source, contains("Key('host-live-ending-curtain')"));
    expect(source, contains('if (_cleanupStarted) return;'));
    expect(source, contains('if (_roomEndSent) return;'));

    expect(
      source,
      isNot(
        contains(
          'await _disposeTransport();\n    if (mounted) Navigator.of(context).pop(true);',
        ),
      ),
    );
  });
}

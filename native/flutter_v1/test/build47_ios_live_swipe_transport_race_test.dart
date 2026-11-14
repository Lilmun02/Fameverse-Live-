import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final src = File(
    'lib/features/live/stream_viewer_live_screen.dart',
  ).readAsStringSync();

  test('old Stream cleanup snapshot precedes first async suspension', () {
    final start = src.indexOf('Future<void> _connect() async {');
    final previous = src.indexOf(
      'final previousCleanup = NativeViewerLiveScreen._lastTransportCleanup;',
      start,
    );
    final frame = src.indexOf('await WidgetsBinding.instance.endOfFrame;', start);
    final wait = src.indexOf('await previousCleanup;', start);

    expect(start, greaterThan(0));
    expect(previous, greaterThan(start));
    expect(frame, greaterThan(previous));
    expect(wait, greaterThan(frame));
    expect(src, isNot(contains('await NativeViewerLiveScreen._lastTransportCleanup;')));
  });

  test('in-flight viewer connection has cancellation gates after awaits', () {
    final start = src.indexOf('Future<void> _connect() async {');
    final finish = src.indexOf('_connectFinished.complete();', start);
    expect(finish, greaterThan(start));
    final region = src.substring(start, finish);
    expect(
      region.split('if (_connectCancelled) return;').length - 1,
      5,
    );
    expect(
      src,
      contains('!mounted || _leaving || _transportCleanup != null'),
    );
    expect(
      src,
      contains('final Completer<void> _connectFinished = Completer<void>();'),
    );
  });

  test('cleanup waits for connection to settle before leaving Stream', () {
    final connect = src.indexOf('Future<void> _connect() async {');
    final catchBlock = src.indexOf('} catch (error) {', connect);
    final complete = src.indexOf('_connectFinished.complete();', catchBlock);
    final cleanup = src.indexOf('Future<void> _performTransportCleanup() async {');
    final wait = src.indexOf('await _connectFinished.future;', cleanup);
    final leave = src.indexOf('await call.leave();', cleanup);
    final reset = src.indexOf('await StreamVideo.reset(disconnect: true);', cleanup);
    expect(catchBlock, greaterThan(connect));
    expect(
      src.substring(catchBlock, complete),
      contains('unawaited(_disposeTransport());'),
    );
    expect(
      src.substring(catchBlock, complete),
      isNot(contains('await _disposeTransport();')),
    );
    expect(complete, greaterThan(catchBlock));
    expect(wait, greaterThan(cleanup));
    expect(leave, greaterThan(wait));
    expect(reset, greaterThan(leave));
  });
}

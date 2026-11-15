import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Build 48 host Live performance — Android and iOS', () {
    final host = File('lib/features/live/stream_host_live_screen.dart')
        .readAsStringSync();

    test('host lifecycle observer is registered and removed', () {
      expect(host, contains('with WidgetsBindingObserver {'));
      expect(host, contains('WidgetsBinding.instance.addObserver(this);'));
      expect(host, contains('WidgetsBinding.instance.removeObserver(this);'));
    });

    test('backgrounding pauses only cosmetic polling, not Live heartbeat', () {
      final lifecycle = host
          .split('void didChangeAppLifecycleState(AppLifecycleState state) {')
          .last
          .split('Future<void> _refreshTapTotal() async {')
          .first;
      expect(lifecycle, contains('state == AppLifecycleState.resumed'));
      expect(lifecycle, contains('_tapRefresh?.cancel();'));
      expect(lifecycle, contains('_tapRefresh = null;'));
      expect(lifecycle, isNot(contains('_heartbeat?.cancel();')));
      expect(
        host,
        contains('_heartbeat = Timer.periodic(const Duration(seconds: 15)'),
      );
    });

    test('resume refresh does not start duplicate polling timers', () {
      final starter = host
          .split('void _startTapRefresh() {')
          .last
          .split('void didChangeAppLifecycleState(')
          .first;
      expect(starter, contains('_tapRefresh?.isActive == true'));
      expect(starter, contains('!_appIsForeground'));
      expect(starter, contains('_connecting'));
      expect(starter, contains('_ending'));
      expect(starter, contains('_ended'));
      expect(starter, contains('const Duration(seconds: 2)'));
      final connect = host
          .split('Future<void> _connect() async {')
          .last
          .split('Future<void> _refreshTapTotal() async {')
          .first;
      expect(
        connect.indexOf('setState(() => _connecting = false);'),
        lessThan(connect.indexOf('_startTapRefresh();')),
      );
    });

    test('slow backend responses cannot pile up parallel tap reads', () {
      final refresh = host
          .split('Future<void> _refreshTapTotal() async {')
          .last
          .split('void _onViewerRosterChanged(')
          .first;
      expect(refresh, contains('_tapRefreshBusy || !mounted'));
      expect(refresh, contains('_tapRefreshBusy = true;'));
      expect(refresh, contains('_tapRefreshBusy = false;'));
      expect(refresh, contains('finally {'));
      expect(refresh, contains('_appIsForeground'));
    });

    test('both native build paths remain in CodeMagic', () {
      final codemagic = File('../../codemagic.yaml').readAsStringSync();
      expect(codemagic, contains('flutter build apk --debug'));
      expect(codemagic, contains('flutter build ipa --release'));
      expect(codemagic, contains('native-foundation:'));
      expect(codemagic, contains('native-testflight:'));
    });
  });
}

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Build 48 host Live performance — Android and iOS', () {
    final path = 'lib/features/live/stream_host_live_screen.dart';
    final host = File(path).readAsStringSync();

    test('host lifecycle observer is registered and removed', () {
      expect(host, contains('with WidgetsBindingObserver {'));
      expect(host, contains('WidgetsBinding.instance.addObserver(this);'));
      expect(host, contains('WidgetsBinding.instance.removeObserver(this);'));
    });

    test('backgrounding pauses only cosmetic polling, not Live heartbeat', () {
      final start = 'void didChangeAppLifecycleState(';
      final end = 'Future<void> _refreshTapTotal()';
      final lifecycle = host.split(start).last.split(end).first;
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
      final start = 'void _startTapRefresh() {';
      final end = 'void didChangeAppLifecycleState(';
      final starter = host.split(start).last.split(end).first;
      expect(starter, contains('_tapRefresh?.isActive == true'));
      expect(starter, contains('!_appIsForeground'));
      expect(starter, contains('_connecting'));
      expect(starter, contains('_ending'));
      expect(starter, contains('_ended'));
      expect(starter, contains('const Duration(seconds: 2)'));
      final connectStart = 'Future<void> _connect() async {';
      final connectEnd = 'Future<void> _refreshTapTotal() async {';
      final connect = host.split(connectStart).last.split(connectEnd).first;
      expect(
        connect.indexOf('setState(() => _connecting = false);'),
        lessThan(connect.indexOf('_startTapRefresh();')),
      );
    });

    test('slow backend responses cannot pile up parallel tap reads', () {
      final start = 'Future<void> _refreshTapTotal() async {';
      final end = 'void _onViewerRosterChanged(';
      final refresh = host.split(start).last.split(end).first;
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

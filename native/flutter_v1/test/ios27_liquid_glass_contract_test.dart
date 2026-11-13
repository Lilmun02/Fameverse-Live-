import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('future iOS glass preserves four native tab destinations', () {
    final source = File(
      'lib/features/shell/fameverse_ios27_glass_nav.dart',
    ).readAsStringSync();
    for (final label in ['Home', 'Discover', 'Live', 'Profile']) {
      expect(source, contains("label: '$label'"));
    }
    expect(source, contains('LiquidGlassBottomBar('));
    expect(source, contains('onTap: onDestinationSelected'));
    expect(source, contains('selectedIndex'));
    expect(source, contains('height: 76'));
  });

  test('Build 47 and Android navigation remain unchanged', () {
    final shell = File(
      'lib/features/shell/fameverse_shell_build23.dart',
    ).readAsStringSync();
    expect(shell, contains('defaultTargetPlatform == TargetPlatform.iOS'));
    expect(shell, contains('_tab != 2'));
    expect(shell, contains('extendBody: iosGlassNavigation'));
    expect(shell, contains("Key('fameverse-bottom-nav')"));
    expect(shell, contains('NavigationBar('));
    expect(shell, contains('onDestinationSelected: _setTab'));
    expect(shell, contains('onLiveEnded: _refreshAll'));
    expect(shell, contains('NativeViewerLiveScreen('));
    expect(shell, contains('NativeProfileBuild23Screen('));
  });

  test('plugin version is pinned and money + Stream remain locked', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(pubspec, contains('real_liquid_glass: 0.3.0'));
    expect(pubspec, contains('stream_video_flutter: 1.6.0'));
    expect(pubspec, contains('in_app_purchase: ^3.3.1'));
  });
}

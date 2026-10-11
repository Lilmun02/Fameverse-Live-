import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Fameboard info exposes all three server-backed ranking rules', () {
    final source = File(
      'lib/features/live/native_live_rankings.dart',
    ).readAsStringSync();

    expect(source, contains("Key('fameboard-ranking-info')"));
    expect(source, contains('How Fameboard rankings work'));
    expect(source, contains('onPressed: () => _showRankingGuide(context)'));
    expect(source, contains('Ranked by cash-backed Fame Coins gifted'));
    expect(source, contains('Ranked by eligible FameTaps you send'));
    expect(source, contains('Ranked by eligible FameTaps received'));
    expect(source, contains('Promotional and test gifts'));
    expect(source, contains('Fixed UTC resets are not active'));
    expect(source, contains("Icons.info_outline_rounded"));
  });
}

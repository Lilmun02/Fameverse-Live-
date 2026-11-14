import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Native Live profile and Fameboard contract', () {
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

    test('Fameboard uses the authoritative windowed backend', () {
      final rankings = File(
        'lib/features/live/native_live_rankings.dart',
      ).readAsStringSync();
      expect(rankings, contains("'get_fameverse_rankings_v2'"));
      expect(rankings, contains("('supporters', 'Supporters'"));
      expect(rankings, contains("('pulse', 'Pulse'"));
      expect(rankings, contains("('creators', 'Creators'"));
      // Legacy RPC window params are unchanged for backward compatibility.
      // The approved new backend windows are calendar UTC boundaries.
      expect(rankings, contains("('24h', 'Daily')"));
      expect(rankings, contains("('7d', 'Weekly')"));
      expect(rankin
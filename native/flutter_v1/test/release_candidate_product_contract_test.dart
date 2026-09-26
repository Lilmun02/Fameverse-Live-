import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('next TestFlight candidate product contract', () {
    test('existing users land on sign in and do not get forced into signup', () async {
      final auth = await File('lib/features/auth/auth_screen.dart').readAsString();

      expect(auth, contains('_AuthMode _mode = _AuthMode.signIn'));
      expect(auth, contains("Key('auth-mode-sign-in')"));
      expect(auth, contains("label: 'Sign in'"));
      expect(
        auth,
        contains('await widget.backend.signIn(email: email, password: password)'),
      );
      expect(
        auth,
        contains('That email already has a Fameverse account. Sign in instead.'),
      );
    });

    test('pre-live setup has no wishlist and clears title after End Live', () async {
      final camera = await File(
        'lib/features/live/native_camera_screen.dart',
      ).readAsString();

      expect(camera, isNot(contains('Wishlist gifts')));
      expect(camera, isNot(contains('_wishlist')));
      expect(camera, contains('wishlistGiftIds: const []'));
      expect(camera, contains('Future<void> _resetLiveSetupAfterEnd()'));
      expect(camera, contains('draft: FvLiveDraft.empty'));
      expect(camera, contains("_title.clear();"));
      expect(camera, contains("_goal.clear();"));
      expect(camera, contains('if (ended == true) {'));
      expect(camera, contains('await _resetLiveSetupAfterEnd();'));
    });

    test('recharge exposes exactly three fixed reference packs plus custom', () async {
      final pricing = await File(
        '../../supabase/migrations/20260926_owner_qa_coin_pricing_v2.sql',
      ).readAsString();
      final recharge = await File(
        'lib/features/profile/native_recharge_screen.dart',
      ).readAsString();
      final api = await File(
        '../../supabase/functions/recharge/index.ts',
      ).readAsString();

      expect(
        pricing,
        contains("('owner-qa-100', '100 Fame Coins', 100, 99"),
      );
      expect(
        pricing,
        contains("('owner-qa-1000', '1,000 Fame Coins', 1000, 999"),
      );
      expect(
        pricing,
        contains("('owner-qa-5000', '5,000 Fame Coins', 5000, 4999"),
      );
      expect(
        pricing,
        contains("('owner-qa-custom', 'Custom Fame Coins'"),
      );
      expect(pricing, isNot(contains("('owner-qa-500',")));
      expect(pricing, isNot(contains("('owner-qa-2500',")));
      expect(recharge, contains("Key('custom-fame-coins-card')"));
      expect(api, contains('paypal'));
      expect(recharge.toLowerCase(), isNot(contains('stripe')));
      expect(api.toLowerCase(), isNot(contains('stripe')));
    });
  });
}

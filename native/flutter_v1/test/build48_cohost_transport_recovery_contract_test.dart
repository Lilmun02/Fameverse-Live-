import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Build 48 co-host transport recovery — Android and iOS', () {
    final host = File(
      'lib/features/live/stream_host_live_screen.dart',
    ).readAsStringSync();
    final viewer = File(
      'lib/features/live/stream_viewer_live_screen.dart',
    ).readAsStringSync();

    test('failed host invite sends release the pending lock', () {
      final invite = host.split('Future<void> _inviteCohost(').last
          .split('Future<void> _acceptCohostRequest(').first;
      expect(invite, contains("await activity.send('cohost-invite'"));
      expect(invite, contains('} catch (_) {'));
      expect(invite, contains('_cohostInviteTimeout?.cancel();'));
      expect(invite, contains('_pendingInviteUserId = null'));
      expect(invite, contains('Co-host invite failed to send. Try again.'));
    });

    test('stale host invites expire without a recurring poll', () {
      final invite = host.split('Future<void> _inviteCohost(').last
          .split('Future<void> _acceptCohostRequest(').first;
      expect(host, contains('Timer? _cohostInviteTimeout;'));
      expect(invite, contains('Timer(const Duration(seconds: 45)'));
      expect(invite, contains('unawaited(_cancelInvite());'));
      final cancel = host.split('Future<void> _cancelInvite() async {').last
          .split('Future<void> _shareLive() async {').first;
      expect(cancel, contains('_pendingInviteUserId = null'));
      expect(cancel, contains('} catch (_) {'));
      expect(host, contains('_cohostInviteTimeout?.cancel();'));
    });

    test('viewer accept failure resets connecting without faking active', () {
      final accept = viewer.split('Future<void> _acceptInvite() async {').last
          .split('Future<void> _declineInvite() async {').first;
      expect(accept, contains("await activity.send('cohost-invite-accepted'"));
      expect(accept, contains("if (_selfCohostState == 'connecting')"));
      expect(accept, contains('setState(() => _selfCohostState = null)'));
      expect(accept, isNot(contains("_selfCohostState = 'active'")));
    });

    test('viewer decline failures do not leave unhandled send errors', () {
      final decline = viewer.split('Future<void> _declineInvite() async {').last
          .split('Future<void> _activateSelfCohost() async {').first;
      expect(decline, contains('_incomingInvite = null'));
      expect(decline, contains('_selfCohostState = null'));
      expect(decline, contains('} catch (_) {'));
    });

    test('cross-platform native build scripts remain present', () {
      final codemagic = File('../../codemagic.yaml').readAsStringSync();
      expect(codemagic, contains('native-foundation:'));
      expect(codemagic, contains('flutter build apk --debug'));
      expect(codemagic, contains('native-testflight:'));
      expect(codemagic, contains('flutter build ipa --release'));
    });
  });
}

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('owner/admin host gift tray stays wired to QA-only gifting', () {
    final wrapper = File(
      'lib/features/live/stream_owner_host_live_screen.dart',
    ).readAsStringSync();
    final host = File(
      'lib/features/live/stream_host_live_screen.dart',
    ).readAsStringSync();
    final barrel = File(
      'lib/features/live/stream_live_screen.dart',
    ).readAsStringSync();
    final migration = File(
      '../../supabase/migrations/20260929_owner_host_qa_gift_preview.sql',
    ).readAsStringSync();

    expect(
      barrel,
      contains("export 'stream_owner_host_live_screen.dart';"),
      reason: 'Host Live must route through the owner/admin QA gift wrapper.',
    );
    expect(
      wrapper,
      contains("role == 'owner' || role == 'admin'"),
      reason: 'QA gift access must stay restricted to owner/admin accounts.',
    );
    expect(
      host,
      contains("Key('owner-host-gift-button')"),
      reason:
          'The privileged host gift entry point must stay beside the canonical composer.',
    );
    expect(
      wrapper,
      contains("'record_beta_gift'"),
      reason: 'Host QA gifts must use the QA RPC rather than public gifting.',
    );
    expect(
      wrapper,
      contains('onGiftPressed: _qaGiftAllowed ? _showGiftTray : null'),
      reason: 'Regular hosts must not receive the privileged QA gift control.',
    );
    expect(
      migration,
      contains('if v_recipient <> v_sender then'),
      reason: 'Gifts to another creator must keep using the normal gift path.',
    );
    expect(
      migration,
      contains("'host_qa_gift_preview'"),
      reason: 'Self-host QA gifts must remain separately auditable.',
    );
    expect(
      migration,
      contains('revoke all on function public.record_beta_gift'),
      reason: 'The SECURITY DEFINER QA RPC must not be executable by PUBLIC.',
    );
    expect(
      migration,
      contains('grant execute on function public.record_beta_gift'),
      reason: 'Authenticated owner/admin accounts still need explicit access.',
    );
  });
}

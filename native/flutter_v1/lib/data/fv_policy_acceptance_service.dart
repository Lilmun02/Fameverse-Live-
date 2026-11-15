import 'package:supabase_flutter/supabase_flutter.dart';

import 'fv_policy_access.dart';

/// Per-account notice and policy decision. The first notice, 7-day warning,
/// 3-day grace and 10-day restriction are calculated in Supabase server time.
class FvPolicyAcceptanceService {
  const FvPolicyAcceptanceService(this.client);

  final SupabaseClient client;

  static const requiredPolicyVersion = '2026-10';

  Future<FvPolicyAccess> submitDecision({
    required bool accept,
    bool checkboxChecked = false,
  }) async {
    if (accept && !checkboxChecked) {
      throw StateError('Agreement checkbox acknowledgment is required.');
    }
    final user = client.auth.currentUser;
    if (user == null) {
      throw StateError('Sign in before responding to the policy.');
    }
    // This upsert never changes the original notice_started_at: SQL trigger
    // guards that timestamp and blocks late acceptance without support.
    await client.from('policy_acceptances').upsert({
      'user_id': user.id,
      'policy_version': requiredPolicyVersion,
      'decision': accept ? 'accepted' : 'declined',
      // Client assertion only; server trigger supplies the audit timestamp.
      'checkbox_acknowledged': accept ? checkboxChecked : null,
    }, onConflict: 'user_id,policy_version');

    final verified = await loadCurrent();
    if (accept) {
      final evidence = await client
          .from('policy_acceptances')
          .select(
            'user_id,policy_version,checkbox_acknowledged,checkbox_acknowledged_at',
          )
          .eq('user_id', user.id)
          .eq('policy_version', requiredPolicyVersion)
          .maybeSingle();
      if (evidence == null ||
          evidence['user_id'] != user.id ||
          evidence['policy_version'] != requiredPolicyVersion ||
          evidence['checkbox_acknowledged'] != true ||
          DateTime.tryParse(
                evidence['checkbox_acknowledged_at']?.toString() ?? '',
              ) ==
              null) {
        throw StateError('Checkbox evidence could not be verified.');
      }
    }
    if (!verified.verifiedForAccount ||
        verified.decision !=
            (accept ? FvPolicyDecision.accepted : FvPolicyDecision.declined)) {
      throw StateError('Policy decision could not be verified.');
    }
    return verified;
  }

  Future<FvPolicyAccess> loadCurrent() async {
    final user = client.auth.currentUser;
    if (user == null) {
      return const FvPolicyAccess(
        accountId: '',
        policyVersion: requiredPolicyVersion,
        decision: FvPolicyDecision.unavailable,
        verifiedForAccount: false,
      );
    }
    try {
      // Inserts only if the account has never received this notice.
      // A subsequent login can never restart the 10-day countdown.
      await client
          .from('policy_acceptances')
          .upsert(
            {
              'user_id': user.id,
              'policy_version': requiredPolicyVersion,
              'decision': 'unsigned',
            },
            onConflict: 'user_id,policy_version',
            ignoreDuplicates: true,
          );

      final raw = await client.rpc(
        'get_my_fameverse_policy_status',
        params: {'p_policy_version': requiredPolicyVersion},
      );
      Map<String, dynamic>? record;
      if (raw is List && raw.isNotEmpty && raw.first is Map) {
        record = Map<String, dynamic>.from(raw.first as Map);
      } else if (raw is Map) {
        record = Map<String, dynamic>.from(raw);
      }

      final matched =
          record != null &&
          record['user_id']?.toString() == user.id &&
          record['policy_version'] == requiredPolicyVersion;
      final decision = switch (record?['decision']) {
        'accepted' => FvPolicyDecision.accepted,
        'declined' => FvPolicyDecision.declined,
        'unsigned' => FvPolicyDecision.unsigned,
        _ => FvPolicyDecision.unavailable,
      };
      final phase = record?['phase']?.toString();
      return FvPolicyAccess(
        accountId: user.id,
        policyVersion: requiredPolicyVersion,
        decision: decision,
        verifiedForAccount: matched,
        withinNoticeWindow:
            matched &&
            decision == FvPolicyDecision.unsigned &&
            record['can_use_restricted'] == true,
        isGracePeriod: matched && phase == 'grace',
        requiresSupport: matched && record['requires_support'] == true,
        noticeStartedAt: _parseDate(record?['notice_started_at']),
        graceStartsAt: _parseDate(record?['grace_starts_at']),
        noticeEndsAt: _parseDate(record?['notice_ends_at']),
      );
    } catch (_) {
      // Never manufacture a 10-day extension when the backend is unreachable.
      return FvPolicyAccess(
        accountId: user.id,
        policyVersion: requiredPolicyVersion,
        decision: FvPolicyDecision.unavailable,
        verifiedForAccount: false,
      );
    }
  }

  static DateTime? _parseDate(Object? raw) =>
      raw == null ? null : DateTime.tryParse(raw.toString())?.toUtc();
}

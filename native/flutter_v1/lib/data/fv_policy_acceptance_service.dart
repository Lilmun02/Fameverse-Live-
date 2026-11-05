import 'package:supabase_flutter/supabase_flutter.dart';

import 'fv_policy_access.dart';

/// Reads the authoritative account-linked policy decision.
/// A missing table, network failure or mismatched account must never unlock
/// restricted features. Backend actions must independently enforce this rule.
class FvPolicyAcceptanceService {
  const FvPolicyAcceptanceService(this.client);

  final SupabaseClient client;

  static const requiredPolicyVersion = '2026-10';

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
      final record = await client
          .from('policy_acceptances')
          .select('user_id, policy_version, decision')
          .eq('user_id', user.id)
          .eq('policy_version', requiredPolicyVersion)
          .maybeSingle();
      final matched = record != null &&
          record['user_id'] == user.id &&
          record['policy_version'] == requiredPolicyVersion;
      final decision = switch (record?['decision']) {
        'accepted' => FvPolicyDecision.accepted,
        'declined' => FvPolicyDecision.declined,
        _ => FvPolicyDecision.unsigned,
      };
      return FvPolicyAccess(
        accountId: user.id,
        policyVersion: requiredPolicyVersion,
        decision: decision,
        verifiedForAccount: matched,
      );
    } catch (_) {
      return FvPolicyAccess(
        accountId: user.id,
        policyVersion: requiredPolicyVersion,
        decision: FvPolicyDecision.unavailable,
        verifiedForAccount: false,
      );
    }
  }
}

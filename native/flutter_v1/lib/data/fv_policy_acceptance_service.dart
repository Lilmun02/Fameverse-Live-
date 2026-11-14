import 'package:supabase_flutter/supabase_flutter.dart';

import 'fv_policy_access.dart';

/// Per-account notice and policy decision. The first notice, 7-day warning,
/// 3-day grace and 10-day restriction are calculated in Supabase server time.
class FvPolicyAcceptanceService {
  const FvPolicyAcceptanceService(this.client);

  final SupabaseClient client;

  static const requiredPolicyVersion = '2026-10';

  Future<FvPolicyAccess> submitDecision({required bool accept}) async {
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
    }, onConflict: 'user_id,policy_version');

    final verified = await loadCurrent();
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
        policyVersion: requiredPolicyVer
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/fameverse_backend.dart';

class FvBuild23ShellAccountService {
  const FvBuild23ShellAccountService({
    required this.backend,
    required this.identityId,
  });

  final FameverseBackend backend;
  final String identityId;

  Future<({FvProfile profile, String? role})?> load() async {
    try {
      final raw = await Supabase.instance.client.rpc(
        'get_my_fameverse_identity',
      );
      Map<String, dynamic>? row;
      if (raw is List && raw.isNotEmpty && raw.first is Map) {
        row = Map<String, dynamic>.from(raw.first as Map);
      } else if (raw is Map) {
        row = Map<String, dynamic>.from(raw);
      }
      if (row == null) return null;

      final userId = (row['user_id'] as String?)?.trim() ?? '';
      if (userId != identityId) {
        throw StateError('current-account-mismatch');
      }
      final username = (row['username'] as String?)?.trim();
      final displayName = (row['display_name'] as String?)?.trim();
      final role = (row['role'] as String?)?.trim().toLowerCase();
      final profile = FvProfile(
        id: userId,
        displayName: displayName == null || displayName.isEmpty
            ? (username?.isNotEmpty == true ? username! : 'Fameverse User')
            : displayName,
        username: username == null || username.isEmpty ? null : username,
        bio: (row['bio'] as String?) ?? '',
        avatarUrl: row['avatar_url'] as String?,
        createdAt: null,
      );
      return (profile: profile, role: role);
    } catch (_) {
      final liveIdentity = backend.currentIdentity;
      if (liveIdentity == null || liveIdentity.id != identityId) return null;
      final results = await Future.wait<dynamic>([
        backend.loadProfile(identityId),
        backend.loadAccountRole(identityId),
      ]);
      final profile = results[0] as FvProfile?;
      if (profile == null) return null;
      final role = (results[1] as String?)?.trim().toLowerCase();
      return (profile: profile, role: role);
    }
  }
}

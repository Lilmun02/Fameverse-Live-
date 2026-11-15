import 'package:supabase_flutter/supabase_flutter.dart';

/// Only published public system notices. Private messages need a separate,
/// account-scoped, RLS-protected backend before they can be shown in Inbox.
class FvSystemNotice {
  const FvSystemNotice({
    required this.id,
    required this.title,
    required this.summary,
    this.versionLabel,
    this.publishedAt,
  });

  final String id;
  final String title;
  final String summary;
  final String? versionLabel;
  final DateTime? publishedAt;

  factory FvSystemNotice.fromRow(Map<String, dynamic> row) {
    final rawTitle = (row['title']?.toString() ?? '').trim();
    final rawVersion = (row['version_label']?.toString() ?? '').trim();
    return FvSystemNotice(
      id: row['id']?.toString() ?? '',
      title: rawTitle.isEmpty ? 'Fameverse update' : rawTitle,
      summary: (row['summary']?.toString() ?? '').trim(),
      versionLabel: rawVersion.isEmpty ? null : rawVersion,
      publishedAt: DateTime.tryParse(
        row['published_at']?.toString() ?? '',
      ),
    );
  }
}

abstract class FvSystemInboxRepository {
  Future<List<FvSystemNotice>> loadForUser(String userId);
}

class SupabaseFvSystemInboxRepository implements FvSystemInboxRepository {
  const SupabaseFvSystemInboxRepository(this.client);

  final SupabaseClient client;

  @override
  Future<List<FvSystemNotice>> loadForUser(String userId) async {
    // Never keep account-specific screens alive across an auth switch.
    if (userId.isEmpty || client.auth.currentUser?.id != userId) {
      throw StateError('Inbox session does not match the signed-in account.');
    }

    // app_update_notices has a SELECT RLS policy for active notices.
    // No insert, update, fake unread status, or private-message queries.
    final rows = await client
        .from('app_update_notices')
        .select('id,title,summary,version_label,published_at')
        .eq('active', true)
        .order('published_at', ascending: false)
        .limit(25);
    return rows.map(FvSystemNotice.fromRow).toList(growable: false);
  }
}

import 'package:supabase_flutter/supabase_flutter.dart';

class FvStartupUpdateNotice {
  const FvStartupUpdateNotice({
    required this.updateType,
    required this.title,
    required this.summary,
    required this.changelog,
    required this.requiresAcknowledgement,
    this.versionLabel,
    this.buildNumber,
  });

  final String updateType;
  final String title;
  final String summary;
  final List<String> changelog;
  final bool requiresAcknowledgement;
  final String? versionLabel;
  final int? buildNumber;

  String get badgeLabel => switch (updateType) {
    'app' => 'APP UPDATE',
    'maintenance' => 'SERVICE UPDATE',
    'feature' => 'WHAT’S NEW',
    _ => 'BACKEND UPDATE',
  };
}

class FvStartupUpdateService {
  FvStartupUpdateService(this._client);

  final SupabaseClient _client;

  Future<FvStartupUpdateNotice?> loadLatest({
    required String channel,
  }) async {
    final rows = await _client
        .from('app_update_notices')
        .select(
          'update_type, title, summary, version_label, build_number, '
          'changelog, requires_acknowledgement, published_at',
        )
        .eq('active', true)
        .eq('channel', channel)
        .order('published_at', ascending: false)
        .limit(1);

    if (rows.isEmpty) return null;
    final row = Map<String, dynamic>.from(rows.first);
    final rawChangelog = row['changelog'];
    final changelog = rawChangelog is List
        ? rawChangelog.map((item) => item.toString()).toList()
        : const <String>[];

    return FvStartupUpdateNotice(
      updateType: (row['update_type'] as String?) ?? 'backend',
      title: (row['title'] as String?) ?? 'Fameverse update',
      summary: (row['summary'] as String?) ?? '',
      versionLabel: row['version_label'] as String?,
      buildNumber: (row['build_number'] as num?)?.toInt(),
      changelog: changelog,
      requiresAcknowledgement:
          (row['requires_acknowledgement'] as bool?) ?? true,
    );
  }
}

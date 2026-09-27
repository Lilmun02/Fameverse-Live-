import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

int _storyInt(dynamic value) {
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

DateTime? _storyDate(dynamic value) {
  final text = value?.toString();
  if (text == null || text.isEmpty) return null;
  return DateTime.tryParse(text);
}

class FvCreatorStory {
  const FvCreatorStory({
    required this.id,
    required this.creatorUserId,
    required this.displayName,
    required this.username,
    required this.avatarUrl,
    required this.mediaType,
    required this.mediaPath,
    required this.mediaUrl,
    required this.caption,
    required this.createdAt,
    required this.expiresAt,
    required this.viewCount,
    required this.viewedByMe,
    required this.isMine,
  });

  final String id;
  final String creatorUserId;
  final String displayName;
  final String? username;
  final String? avatarUrl;
  final String mediaType;
  final String mediaPath;
  final String mediaUrl;
  final String caption;
  final DateTime? createdAt;
  final DateTime? expiresAt;
  final int viewCount;
  final bool viewedByMe;
  final bool isMine;

  bool get isVideo => mediaType == 'video';
}

class FvStorySummary {
  const FvStorySummary({
    required this.activeStoryCount,
    required this.totalViews,
    required this.newestExpiresAt,
  });

  final int activeStoryCount;
  final int totalViews;
  final DateTime? newestExpiresAt;

  static const empty = FvStorySummary(
    activeStoryCount: 0,
    totalViews: 0,
    newestExpiresAt: null,
  );
}

class SupabaseFameverseStoryBackend {
  SupabaseFameverseStoryBackend(this._client);

  final SupabaseClient _client;
  static const bucketName = 'fameverse-stories';

  List<Map<String, dynamic>> _rows(dynamic response) {
    if (response is! List) return const [];
    return response
        .whereType<Map>()
        .map((row) => Map<String, dynamic>.from(row))
        .toList();
  }

  FvCreatorStory _storyFromMap(Map<String, dynamic> row) {
    final path = row['media_path']?.toString() ?? '';
    final publicUrl = path.isEmpty
        ? ''
        : _client.storage.from(bucketName).getPublicUrl(path);
    return FvCreatorStory(
      id: row['story_id']?.toString() ?? row['id']?.toString() ?? '',
      creatorUserId: row['creator_user_id']?.toString() ?? '',
      displayName: row['display_name']?.toString() ?? 'Fameverse Creator',
      username: row['username'] as String?,
      avatarUrl: row['avatar_url'] as String?,
      mediaType: row['media_type']?.toString() ?? 'photo',
      mediaPath: path,
      mediaUrl: publicUrl,
      caption: row['caption']?.toString() ?? '',
      createdAt: _storyDate(row['created_at']),
      expiresAt: _storyDate(row['expires_at']),
      viewCount: _storyInt(row['view_count']),
      viewedByMe: row['viewed_by_me'] == true,
      isMine: row['is_mine'] == true,
    );
  }

  Future<List<FvCreatorStory>> listActiveStories() async {
    final response = await _client.rpc('list_active_creator_stories');
    return _rows(response).map(_storyFromMap).toList();
  }

  Future<FvStorySummary> loadMySummary() async {
    final response = await _client.rpc('get_my_active_story_summary');
    final rows = _rows(response);
    if (rows.isEmpty) return FvStorySummary.empty;
    final row = rows.first;
    return FvStorySummary(
      activeStoryCount: _storyInt(row['active_story_count']),
      totalViews: _storyInt(row['total_views']),
      newestExpiresAt: _storyDate(row['newest_expires_at']),
    );
  }

  Future<FvCreatorStory> createStory({
    required String userId,
    required Uint8List bytes,
    required String mediaType,
    required String extension,
    required String contentType,
    String caption = '',
  }) async {
    final normalizedType = mediaType.trim().toLowerCase();
    if (normalizedType != 'photo' && normalizedType != 'video') {
      throw ArgumentError.value(mediaType, 'mediaType');
    }
    if (bytes.isEmpty || bytes.length > 50 * 1024 * 1024) {
      throw StateError('Story media must be 50 MB or smaller.');
    }

    const photoTypes = {'image/jpeg', 'image/png', 'image/webp'};
    const videoTypes = {'video/mp4', 'video/quicktime'};
    if (normalizedType == 'photo' && !photoTypes.contains(contentType)) {
      throw StateError('Story photo must be JPG, PNG, or WEBP.');
    }
    if (normalizedType == 'video' && !videoTypes.contains(contentType)) {
      throw StateError('Story video must be MP4 or MOV.');
    }

    final safeExtension = extension.trim().toLowerCase().replaceAll(
      RegExp(r'[^a-z0-9]'),
      '',
    );
    final ext = safeExtension.isEmpty
        ? (normalizedType == 'photo' ? 'jpg' : 'mp4')
        : safeExtension;
    final nonce = DateTime.now().microsecondsSinceEpoch;
    final path = '$userId/$nonce.$ext';
    final bucket = _client.storage.from(bucketName);

    await bucket.uploadBinary(
      path,
      bytes,
      fileOptions: FileOptions(contentType: contentType, upsert: false),
    );

    try {
      final response = await _client.rpc(
        'create_creator_story',
        params: <String, dynamic>{
          'p_media_type': normalizedType,
          'p_media_path': path,
          'p_caption': caption.trim(),
        },
      );
      final rows = _rows(response);
      if (rows.isEmpty) throw StateError('story-create-result-missing');
      final created = Map<String, dynamic>.from(rows.first);
      created.addAll(<String, dynamic>{
        'creator_user_id': userId,
        'display_name': 'You',
        'username': null,
        'avatar_url': null,
        'view_count': 0,
        'viewed_by_me': false,
        'is_mine': true,
      });
      return _storyFromMap(created);
    } catch (_) {
      try {
        await bucket.remove([path]);
      } catch (_) {}
      rethrow;
    }
  }

  Future<int> recordView(String storyId) async {
    final response = await _client.rpc(
      'record_creator_story_view',
      params: <String, dynamic>{'p_story_id': storyId},
    );

    // First Verse progress is deliberately best-effort. Non-beta users receive
    // a harmless false/no-op from the beta RPC, and Stories never depends on it.
    try {
      await _client.rpc(
        'record_beta_test_mission',
        params: const <String, dynamic>{'p_mission_key': 'view_story'},
      );
    } catch (_) {}

    return _storyInt(response);
  }

  Future<void> deleteStory(FvCreatorStory story) async {
    final response = await _client.rpc(
      'delete_creator_story',
      params: <String, dynamic>{'p_story_id': story.id},
    );
    final path = response?.toString().trim();
    if (path == null || path.isEmpty) return;
    try {
      await _client.storage.from(bucketName).remove([path]);
    } catch (_) {
      // The row is already hidden immediately. Storage cleanup can safely retry
      // later without resurrecting the deleted Story.
    }
  }
}

import 'package:supabase_flutter/supabase_flutter.dart';

import 'fameverse_inbox_models.dart';

/// Supabase RLS enforces membership for every SELECT, INSERT and read receipt.
/// No messaging or notification data is stored in local fake/demo lists.
class SupabaseFameverseInboxRepository implements FameverseInboxRepository {
  SupabaseFameverseInboxRepository(this.client);

  final SupabaseClient client;

  void _requireAccount(String userId) {
    if (client.auth.currentUser?.id != userId) {
      throw StateError('Inbox account does not match the signed-in account');
    }
  }

  @override
  Future<FvInboxSnapshot> load(String userId) async {
    _requireAccount(userId);
    final activities = await client
        .from('user_inbox_items')
        .select('id, title, body, created_at, read_at')
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(100);
    final conversations = await client
        .from('direct_conversations')
        .select('id, user_low, user_high, updated_at')
        .or('user_low.eq.$userId,user_high.eq.$userId')
        .order('updated_at', ascending: false)
        .limit(100);

    final peerIds = conversations
        .map(
          (row) => row['user_low'] == userId
              ? row['user_high'].toString()
              : row['user_low'].toString(),
        )
        .toSet()
        .toList();
    final roomIds = conversations.map((row) => row['id'].toString()).toList();
    final profiles = peerIds.isEmpty
        ? <Map<String, dynamic>>[]
        : await client
              .from('profiles')
              .select('id, display_name, username')
              .inFilter('id', peerIds);
    final latestMessages = roomIds.isEmpty
        ? <Map<String, dynamic>>[]
        : await client
              .from('direct_messages')
              .select(
                'id, conversation_id, sender_id, body, created_at, read_at',
              )
              .inFilter('conversation_id', roomIds)
              .order('created_at', ascending: false)
              .limit(500);

    final profileById = <String, Map<String, dynamic>>{
      for (final row in profiles) row['id'].toString(): row,
    };
    final newestByRoom = <String, FvInboxMessage>{};
    final unreadByRoom = <String, int>{};
    for (final row in latestMessages) {
      final message = FvInboxMessage.fromRow(row);
      newestByRoom.putIfAbsent(message.conversationId, () => message);
      if (message.senderId != userId && message.readAt == null) {
        unreadByRoom.update(
          message.conversationId,
          (value) => value + 1,
          ifAbsent: () => 1,
        );
      }
    }

    return FvInboxSnapshot(
      activities: activities.map(FvInboxActivity.fromRow).toList(),
      conversations: conversations.map((row) {
        final id = row['id'].toString();
        final peerId = row['user_low'] == userId
            ? row['user_high'].toString()
            : row['user_low'].toString();
        final profile = profileById[peerId];
        return FvInboxConversation(
          id: id,
          peerId: peerId,
          peerName: profile?['display_name']?.toString() ?? 'Fameverse user',
          peerHandle: profile?['username']?.toString() ?? '',
          preview: newestByRoom[id]?.body ?? 'Start the conversation',
          unreadCount: unreadByRoom[id] ?? 0,
          updatedAt: DateTime.tryParse(row['updated_at']?.toString() ?? ''),
        );
      }).toList(),
    );
  }

  @override
  Future<List<FvInboxContact>> searchContacts(
    String userId,
    String query,
  ) async {
    _requireAccount(userId);
    final clean = query.trim().replaceAll(RegExp(r'[^a-zA-Z0-9_.]'), '');
    if (clean.length < 2) return const [];
    final rows = await client
        .from('profiles')
        .select('id, display_name, username')
        .ilike('username', '%${clean.substring(0, clean.length.clamp(0, 32))}%')
        .neq('id', userId)
        .limit(20);
    return rows
        .map(
          (row) => FvInboxContact(
            id: row['id'].toString(),
            displayName: row['display_name']?.toString() ?? 'Fameverse user',
            username: row['username']?.toString() ?? '',
          ),
        )
        .toList();
  }

  @override
  Future<String> startConversation(String userId, String otherUserId) async {
    _requireAccount(userId);
    if (userId == otherUserId) throw StateError('Cannot message yourself');
    final id = await client.rpc(
      'start_direct_conversation',
      params: {'p_other_user_id': otherUserId},
    );
    if (id == null) throw StateError('Conversation could not be created');
    return id.toString();
  }

  @override
  Future<List<FvInboxMessage>> loadMessages(
    String userId,
    String conversationId,
  ) async {
    _requireAccount(userId);
    final rows = await client
        .from('direct_messages')
        .select('id, conversation_id, sender_id, body, created_at, read_at')
        .eq('conversation_id', conversationId)
        .order('created_at', ascending: false)
        .limit(100);
    return rows.map(FvInboxMessage.fromRow).toList().reversed.toList();
  }

  @override
  Future<void> sendMessage(
    String userId,
    String conversationId,
    String body,
  ) async {
    _requireAccount(userId);
    final message = body.trim();
    if (message.isEmpty || message.length > 2000) {
      throw ArgumentError('Messages must contain 1–2000 characters');
    }
    await client.from('direct_messages').insert({
      'conversation_id': conversationId,
      'sender_id': userId,
      'body': message,
    });
  }

  @override
  Future<void> readConversation(String userId, String conversationId) async {
    _requireAccount(userId);
    await client
        .from('direct_messages')
        .update({'read_at': DateTime.now().toUtc().toIso8601String()})
        .eq('conversation_id', conversationId)
        .neq('sender_id', userId)
        .isFilter('read_at', null);
  }

  @override
  Future<void> readActivity(String userId, String activityId) async {
    _requireAccount(userId);
    await client
        .from('user_inbox_items')
        .update({'read_at': DateTime.now().toUtc().toIso8601String()})
        .eq('user_id', userId)
        .eq('id', activityId);
  }
  @override
  Future<void> blockUser(String userId, String blockedUserId) async {
    _requireAccount(userId);
    if (userId == blockedUserId) {
      throw StateError('You cannot block your own account');
    }
    await client.from('direct_user_blocks').insert({
      'blocker_id': userId,
      'blocked_id': blockedUserId,
    });
  }

  @override
  Future<void> reportUser(
    String userId,
    String targetUserId,
    String reason,
  ) async {
    _requireAccount(userId);
    final clean = reason.trim();
    if (targetUserId == userId || clean.length < 5 || clean.length > 1000) {
      throw ArgumentError('Choose another account and a valid report reason');
    }
    await client.from('direct_user_reports').insert({
      'reporter_id': userId,
      'reported_user_id': targetUserId,
      'reason': clean,
    });
  }

}

class FvInboxActivity {
  const FvInboxActivity({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    required this.readAt,
  });

  final String id;
  final String title;
  final String body;
  final DateTime? createdAt;
  final DateTime? readAt;

  bool get unread => readAt == null;

  factory FvInboxActivity.fromRow(Map<String, dynamic> row) =>
      FvInboxActivity(
        id: row['id']?.toString() ?? '',
        title: row['title']?.toString() ?? '',
        body: row['body']?.toString() ?? '',
        createdAt: DateTime.tryParse(row['created_at']?.toString() ?? ''),
        readAt: DateTime.tryParse(row['read_at']?.toString() ?? ''),
      );
}

class FvInboxConversation {
  const FvInboxConversation({
    required this.id,
    required this.peerId,
    required this.peerName,
    required this.peerHandle,
    required this.preview,
    required this.unreadCount,
    this.updatedAt,
  });

  final String id;
  final String peerId;
  final String peerName;
  final String peerHandle;
  final String preview;
  final int unreadCount;
  final DateTime? updatedAt;
}

class FvInboxMessage {
  const FvInboxMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.body,
    required this.createdAt,
    this.readAt,
  });

  final String id;
  final String conversationId;
  final String senderId;
  final String body;
  final DateTime? createdAt;
  final DateTime? readAt;

  factory FvInboxMessage.fromRow(Map<String, dynamic> row) => FvInboxMessage(
    id: row['id']?.toString() ?? '',
    conversationId: row['conversation_id']?.toString() ?? '',
    senderId: row['sender_id']?.toString() ?? '',
    body: row['body']?.toString() ?? '',
    createdAt: DateTime.tryParse(row['created_at']?.toString() ?? ''),
    readAt: DateTime.tryParse(row['read_at']?.toString() ?? ''),
  );
}

class FvInboxContact {
  const FvInboxContact({
    required this.id,
    required this.displayName,
    required this.username,
  });

  final String id;
  final String displayName;
  final String username;
}

class FvInboxSnapshot {
  const FvInboxSnapshot({
    required this.conversations,
    required this.activities,
  });

  final List<FvInboxConversation> conversations;
  final List<FvInboxActivity> activities;
}

abstract class FameverseInboxRepository {
  Future<FvInboxSnapshot> load(String userId);
  Future<List<FvInboxContact>> searchContacts(String userId, String query);
  Future<String> startConversation(String userId, String otherUserId);
  Future<List<FvInboxMessage>> loadMessages(
    String userId,
    String conversationId,
  );
  Future<void> sendMessage(
    String userId,
    String conversationId,
    String body,
  );
  Future<void> readConversation(String userId, String conversationId);
  Future<void> readActivity(String userId, String activityId);
}

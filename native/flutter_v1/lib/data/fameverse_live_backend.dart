import 'package:supabase_flutter/supabase_flutter.dart';

import 'fameverse_backend.dart';

class FvLiveCredentials {
  const FvLiveCredentials({
    required this.serverUrl,
    required this.participantToken,
    required this.roomName,
  });

  final String serverUrl;
  final String participantToken;
  final String roomName;
}

abstract class FameverseLiveBackend {
  Future<FvLiveRoom> startLiveRoom({
    required FvIdentity identity,
    required FvProfile profile,
    required String title,
  });

  Future<void> heartbeatLiveRoom({
    required String roomId,
    required String hostUserId,
  });

  Future<void> endLiveRoom({
    required String roomId,
    required String hostUserId,
  });

  Future<FvLiveCredentials> issueLiveCredentials({
    required String roomId,
    required String role,
  });
}

class SupabaseFameverseLiveBackend implements FameverseLiveBackend {
  SupabaseFameverseLiveBackend(this._client);

  final SupabaseClient _client;

  String _cleanTitle(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return 'Live on Fameverse';
    return trimmed.length <= 120 ? trimmed : trimmed.substring(0, 120);
  }

  @override
  Future<FvLiveRoom> startLiveRoom({
    required FvIdentity identity,
    required FvProfile profile,
    required String title,
  }) async {
    final now = DateTime.now().toUtc().toIso8601String();

    await _client
        .from('live_rooms')
        .update({
          'status': 'ended',
          'ended_at': now,
          'heartbeat_at': now,
          'updated_at': now,
        })
        .eq('host_user_id', identity.id)
        .eq('status', 'live');

    final row = await _client
        .from('live_rooms')
        .insert({
          'host_user_id': identity.id,
          'title': _cleanTitle(title),
          'status': 'live',
          'started_at': now,
          'heartbeat_at': now,
          'updated_at': now,
        })
        .select('id, host_user_id, title')
        .single();

    return FvLiveRoom(
      id: row['id'] as String,
      hostUserId: row['host_user_id'] as String,
      title: row['title'] as String,
      fameTaps: 0,
      host: profile,
    );
  }

  @override
  Future<void> heartbeatLiveRoom({
    required String roomId,
    required String hostUserId,
  }) async {
    final now = DateTime.now().toUtc().toIso8601String();
    await _client
        .from('live_rooms')
        .update({'heartbeat_at': now, 'updated_at': now})
        .eq('id', roomId)
        .eq('host_user_id', hostUserId)
        .eq('status', 'live');
  }

  @override
  Future<void> endLiveRoom({
    required String roomId,
    required String hostUserId,
  }) async {
    final now = DateTime.now().toUtc().toIso8601String();
    await _client
        .from('live_rooms')
        .update({
          'status': 'ended',
          'ended_at': now,
          'heartbeat_at': now,
          'updated_at': now,
        })
        .eq('id', roomId)
        .eq('host_user_id', hostUserId)
        .eq('status', 'live');
  }

  @override
  Future<FvLiveCredentials> issueLiveCredentials({
    required String roomId,
    required String role,
  }) async {
    try {
      final response = await _client.functions.invoke(
        'livekit-token',
        body: {'room_id': roomId, 'role': role},
      );
      final raw = response.data;
      if (raw is! Map) throw Exception('invalid-livekit-token-response');
      final data = Map<String, dynamic>.from(raw);
      final serverUrl = (data['server_url'] as String?)?.trim() ?? '';
      final participantToken =
          (data['participant_token'] as String?)?.trim() ?? '';
      final roomName = (data['room_name'] as String?)?.trim() ?? '';
      if (serverUrl.isEmpty || participantToken.isEmpty || roomName.isEmpty) {
        throw Exception('invalid-livekit-token-response');
      }
      return FvLiveCredentials(
        serverUrl: serverUrl,
        participantToken: participantToken,
        roomName: roomName,
      );
    } on FunctionException catch (error) {
      final details = error.details;
      if (details is Map && details['error'] == 'livekit-not-configured') {
        throw Exception('livekit-not-configured');
      }
      rethrow;
    }
  }
}

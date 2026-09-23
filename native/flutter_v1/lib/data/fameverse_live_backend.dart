import 'package:supabase_flutter/supabase_flutter.dart';

import 'fameverse_backend.dart';

class FvLiveCredentials {
  const FvLiveCredentials({
    required this.apiKey,
    required this.userToken,
    required this.userId,
    required this.callId,
  });

  final String apiKey;
  final String userToken;
  final String userId;
  final String callId;
}

class FvGiftDefinition {
  const FvGiftDefinition({
    required this.id,
    required this.label,
    required this.cost,
    required this.category,
    this.emoji,
    this.activityEmoji,
    this.videoUrl,
    this.cinematic = false,
    this.singleSendOnly = false,
  });

  final String id;
  final String label;
  final int cost;
  final String category;
  final String? emoji;
  final String? activityEmoji;
  final String? videoUrl;
  final bool cinematic;
  final bool singleSendOnly;

  String get symbol => activityEmoji ?? emoji ?? '✦';
}

const fvGiftCatalog = <FvGiftDefinition>[
  FvGiftDefinition(
    id: 'welcome-to-fameverse',
    label: 'Welcome to Fameverse',
    cost: 100,
    category: 'fameverse',
    activityEmoji: '✦',
    videoUrl:
        'https://d2ol7oe51mr4n9.cloudfront.net/user_3IL6AXXAqcrsLZJmbjvrquIP0Bd/8d3fd7e2-9073-4e1b-8ef6-843a1514aae6.mp4',
    cinematic: true,
  ),
  FvGiftDefinition(
    id: 'ember-dragon',
    label: 'Ember Dragon',
    cost: 1000,
    category: 'fameverse',
    activityEmoji: '🐉',
    videoUrl:
        'https://d2ol7oe51mr4n9.cloudfront.net/user_3IL6AXXAqcrsLZJmbjvrquIP0Bd/6ef5d526-e0d8-42ca-a382-28d53d3fe2aa.mp4',
    cinematic: true,
    singleSendOnly: true,
  ),
  FvGiftDefinition(
    id: 'celestial-phoenix',
    label: 'Celestial Phoenix',
    cost: 1000,
    category: 'fameverse',
    activityEmoji: '🔥',
    videoUrl:
        'https://d2ol7oe51mr4n9.cloudfront.net/user_3IL6AXXAqcrsLZJmbjvrquIP0Bd/e4da59e7-2d55-4ee2-b546-cae61cf56de3.mp4',
    cinematic: true,
    singleSendOnly: true,
  ),
  FvGiftDefinition(
    id: 'pocket-comet',
    label: 'Pocket Comet',
    cost: 1000,
    category: 'fameverse',
    activityEmoji: '☄️',
    cinematic: true,
    singleSendOnly: true,
  ),
  FvGiftDefinition(
    id: 'rose',
    label: 'Rose',
    cost: 1,
    category: 'classic',
    emoji: '🌹',
  ),
  FvGiftDefinition(
    id: 'heart',
    label: 'Heart',
    cost: 1,
    category: 'classic',
    emoji: '💜',
  ),
  FvGiftDefinition(
    id: 'fire',
    label: 'Fire',
    cost: 1,
    category: 'classic',
    emoji: '🔥',
  ),
  FvGiftDefinition(
    id: 'star',
    label: 'Star',
    cost: 1,
    category: 'classic',
    emoji: '⭐',
  ),
  FvGiftDefinition(
    id: 'crown',
    label: 'Crown',
    cost: 1,
    category: 'classic',
    emoji: '👑',
  ),
];

FvGiftDefinition? fvGiftById(String? id) {
  if (id == null) return null;
  for (final gift in fvGiftCatalog) {
    if (gift.id == id) return gift;
  }
  return null;
}

class FvGifterStats {
  const FvGifterStats({
    required this.totalCoinsSent,
    required this.giftCount,
    required this.level,
  });

  final int totalCoinsSent;
  final int giftCount;
  final int level;

  static const empty = FvGifterStats(
    totalCoinsSent: 0,
    giftCount: 0,
    level: 1,
  );
}

class FvGiftSendResult {
  const FvGiftSendResult({
    required this.totalCoinsSent,
    required this.giftCount,
    required this.level,
    required this.walletBalance,
  });

  final int totalCoinsSent;
  final int giftCount;
  final int level;
  final int walletBalance;
}

class FvTapBatchResult {
  const FvTapBatchResult({
    required this.rawTapCount,
    required this.eligibleTapCount,
    required this.classification,
    required this.totalRawTaps,
    required this.totalEligibleTaps,
  });

  final int rawTapCount;
  final int eligibleTapCount;
  final String classification;
  final int totalRawTaps;
  final int totalEligibleTaps;
}

class FvLiveDraft {
  const FvLiveDraft({
    required this.title,
    required this.goal,
    required this.wishlistGiftIds,
  });

  final String title;
  final String goal;
  final List<String> wishlistGiftIds;

  static const empty = FvLiveDraft(title: '', goal: '', wishlistGiftIds: []);
}

class FvCreatorLiveSummary {
  const FvCreatorLiveSummary({
    required this.roomId,
    required this.title,
    required this.goal,
    required this.status,
    required this.startedAt,
    required this.endedAt,
    required this.rawTaps,
    required this.giftCount,
    required this.giftCoins,
  });

  final String roomId;
  final String title;
  final String goal;
  final String status;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final int rawTaps;
  final int giftCount;
  final int giftCoins;
}

class FvCreatorGiftActivity {
  const FvCreatorGiftActivity({
    required this.id,
    required this.roomId,
    required this.senderUserId,
    required this.senderDisplayName,
    required this.giftId,
    required this.quantity,
    required this.coinsSpent,
    required this.createdAt,
  });

  final String id;
  final String roomId;
  final String senderUserId;
  final String senderDisplayName;
  final String giftId;
  final int quantity;
  final int coinsSpent;
  final DateTime? createdAt;
}

class FvViewerIdentityStats {
  const FvViewerIdentityStats({
    required this.userId,
    required this.username,
    required this.displayName,
    required this.avatarUrl,
    required this.totalCoinsSent,
    required this.gifterLevel,
    required this.roomGiftCount,
    required this.roomFameTaps,
    required this.accountRole,
  });

  final String userId;
  final String? username;
  final String displayName;
  final String? avatarUrl;
  final int totalCoinsSent;
  final int gifterLevel;
  final int roomGiftCount;
  final int roomFameTaps;
  final String? accountRole;
}

class FvLiveActivitySession {
  FvLiveActivitySession(this._client, this._channel);

  final SupabaseClient _client;
  final RealtimeChannel _channel;

  Future<void> send(String event, Map<String, dynamic> payload) async {
    await _channel.sendBroadcastMessage(event: event, payload: payload);
  }

  Future<void> close() async {
    await _client.removeChannel(_channel);
  }
}

typedef FvActivityCallback = void Function(Map<String, dynamic> payload);

abstract class FameverseLiveBackend {
  Future<FvLiveRoom> startLiveRoom({
    required FvIdentity identity,
    required FvProfile profile,
    required String title,
    String goal = '',
    List<String> wishlistGiftIds = const [],
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

  Future<FvLiveDraft> loadLiveDraft(String userId);
  Future<void> saveLiveDraft({
    required String userId,
    required FvLiveDraft draft,
  });
  Future<int> loadWalletBalance(String userId);
  Future<int> refillBetaWallet();
  Future<FvGifterStats> loadGifterStats(String userId);
  Future<FvGiftSendResult> recordGift({
    required String roomId,
    required String giftId,
    required int quantity,
  });
  Future<int> loadTapTotal(String roomId);
  Future<FvTapBatchResult> recordTapBatch({
    required String roomId,
    required String batchId,
    required List<double> timestamps,
  });
  Future<List<FvViewerIdentityStats>> loadViewerIdentityStats({
    required String roomId,
    required List<String> userIds,
  });
  Future<List<FvCreatorLiveSummary>> loadCreatorLiveHistory({int limit = 20});
  Future<List<FvCreatorGiftActivity>> loadCreatorGiftActivity({int limit = 50});
  Future<bool> setCreatorModerator({
    required String moderatorUserId,
    required bool enabled,
  });
  FvLiveActivitySession openLiveActivity({
    required String roomId,
    FvActivityCallback? onComment,
    FvActivityCallback? onGift,
    FvActivityCallback? onCohost,
    void Function(RealtimeSubscribeStatus status)? onStatus,
  });
}

class SupabaseFameverseLiveBackend implements FameverseLiveBackend {
  SupabaseFameverseLiveBackend(this._client);

  final SupabaseClient _client;

  String _cleanTitle(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return 'Live on Fameverse';
    return trimmed.length <= 80 ? trimmed : trimmed.substring(0, 80);
  }

  String _cleanGoal(String value) {
    final trimmed = value.trim();
    return trimmed.length <= 60 ? trimmed : trimmed.substring(0, 60);
  }

  List<String> _cleanWishlist(List<String> ids) {
    final allowed = fvGiftCatalog.map((gift) => gift.id).toSet();
    return ids.where(allowed.contains).toSet().toList();
  }

  @override
  Future<FvLiveRoom> startLiveRoom({
    required FvIdentity identity,
    required FvProfile profile,
    required String title,
    String goal = '',
    List<String> wishlistGiftIds = const [],
  }) async {
    final now = DateTime.now().toUtc().toIso8601String();
    final cleanWishlist = _cleanWishlist(wishlistGiftIds);

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
          'goal': _cleanGoal(goal),
          'wishlist_gift_ids': cleanWishlist,
          'status': 'live',
          'started_at': now,
          'heartbeat_at': now,
          'updated_at': now,
        })
        .select('id, host_user_id, title, goal, wishlist_gift_ids')
        .single();

    return FvLiveRoom(
      id: row['id'] as String,
      hostUserId: row['host_user_id'] as String,
      title: row['title'] as String,
      goal: (row['goal'] as String?) ?? '',
      wishlistGiftIds: ((row['wishlist_gift_ids'] as List?) ?? const [])
          .map((value) => value.toString())
          .toList(),
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
        'stream-token',
        body: {'room_id': roomId, 'role': role},
      );
      final raw = response.data;
      if (raw is! Map) throw Exception('invalid-stream-token-response');
      final data = Map<String, dynamic>.from(raw);
      final apiKey = (data['api_key'] as String?)?.trim() ?? '';
      final userToken = (data['user_token'] as String?)?.trim() ?? '';
      final userId = (data['user_id'] as String?)?.trim() ?? '';
      final callId = (data['call_id'] as String?)?.trim() ?? '';
      if (apiKey.isEmpty || userToken.isEmpty || userId.isEmpty || callId.isEmpty) {
        throw Exception('invalid-stream-token-response');
      }
      return FvLiveCredentials(
        apiKey: apiKey,
        userToken: userToken,
        userId: userId,
        callId: callId,
      );
    } on FunctionException catch (error) {
      final details = error.details;
      if (details is Map && details['error'] == 'stream-not-configured') {
        throw Exception('stream-not-configured');
      }
      rethrow;
    }
  }

  @override
  Future<FvLiveDraft> loadLiveDraft(String userId) async {
    final row = await _client
        .from('creator_live_drafts')
        .select('title, goal, wishlist_gift_ids')
        .eq('user_id', userId)
        .maybeSingle();
    if (row == null) return FvLiveDraft.empty;
    return FvLiveDraft(
      title: (row['title'] as String?) ?? '',
      goal: (row['goal'] as String?) ?? '',
      wishlistGiftIds: ((row['wishlist_gift_ids'] as List?) ?? const [])
          .map((value) => value.toString())
          .toList(),
    );
  }

  @override
  Future<void> saveLiveDraft({
    required String userId,
    required FvLiveDraft draft,
  }) async {
    await _client.from('creator_live_drafts').upsert({
      'user_id': userId,
      'title': _cleanTitle(draft.title) == 'Live on Fameverse' && draft.title.trim().isEmpty
          ? ''
          : _cleanTitle(draft.title),
      'goal': _cleanGoal(draft.goal),
      'wishlist_gift_ids': _cleanWishlist(draft.wishlistGiftIds),
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  @override
  Future<int> loadWalletBalance(String userId) async {
    final row = await _client
        .from('beta_coin_wallets')
        .select('balance')
        .eq('user_id', userId)
        .maybeSingle();
    return (row?['balance'] as num?)?.toInt() ?? 0;
  }

  @override
  Future<int> refillBetaWallet() async {
    final data = await _client.rpc('refill_beta_wallet', params: {'p_amount': 10000});
    return (data as num?)?.toInt() ?? 0;
  }

  @override
  Future<FvGifterStats> loadGifterStats(String userId) async {
    final row = await _client
        .from('gifter_stats')
        .select('total_coins_sent, gift_count, level')
        .eq('user_id', userId)
        .maybeSingle();
    if (row == null) return FvGifterStats.empty;
    return FvGifterStats(
      totalCoinsSent: (row['total_coins_sent'] as num?)?.toInt() ?? 0,
      giftCount: (row['gift_count'] as num?)?.toInt() ?? 0,
      level: (row['level'] as num?)?.toInt() ?? 1,
    );
  }

  Map<String, dynamic> _firstRpcRow(dynamic data) {
    if (data is List && data.isNotEmpty && data.first is Map) {
      return Map<String, dynamic>.from(data.first as Map);
    }
    if (data is Map) return Map<String, dynamic>.from(data);
    return const {};
  }

  @override
  Future<FvGiftSendResult> recordGift({
    required String roomId,
    required String giftId,
    required int quantity,
  }) async {
    final data = await _client.rpc(
      'record_beta_gift',
      params: {
        'p_room_id': roomId,
        'p_gift_id': giftId,
        'p_quantity': quantity,
      },
    );
    final row = _firstRpcRow(data);
    if (row.isEmpty) throw Exception('gift-result-missing');
    return FvGiftSendResult(
      totalCoinsSent: (row['total_coins_sent'] as num?)?.toInt() ?? 0,
      giftCount: (row['gift_count'] as num?)?.toInt() ?? 0,
      level: (row['level'] as num?)?.toInt() ?? 1,
      walletBalance: (row['wallet_balance'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  Future<int> loadTapTotal(String roomId) async {
    final row = await _client
        .from('live_tap_totals')
        .select('raw_taps')
        .eq('room_id', roomId)
        .maybeSingle();
    return (row?['raw_taps'] as num?)?.toInt() ?? 0;
  }

  @override
  Future<FvTapBatchResult> recordTapBatch({
    required String roomId,
    required String batchId,
    required List<double> timestamps,
  }) async {
    final data = await _client.rpc(
      'record_live_tap_batch',
      params: {
        'p_room_id': roomId,
        'p_batch_id': batchId,
        'p_timestamps': timestamps,
      },
    );
    final row = _firstRpcRow(data);
    if (row.isEmpty) throw Exception('tap-result-missing');
    return FvTapBatchResult(
      rawTapCount: (row['raw_tap_count'] as num?)?.toInt() ?? 0,
      eligibleTapCount: (row['eligible_tap_count'] as num?)?.toInt() ?? 0,
      classification: (row['classification'] as String?) ?? 'unknown',
      totalRawTaps: (row['total_raw_taps'] as num?)?.toInt() ?? 0,
      totalEligibleTaps: (row['total_eligible_taps'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  Future<List<FvViewerIdentityStats>> loadViewerIdentityStats({
    required String roomId,
    required List<String> userIds,
  }) async {
    if (userIds.isEmpty) return const [];
    final data = await _client.rpc(
      'get_live_viewer_identity_stats',
      params: {'p_room_id': roomId, 'p_user_ids': userIds.toSet().toList()},
    );
    return (data as List? ?? const []).map((raw) {
      final row = Map<String, dynamic>.from(raw as Map);
      return FvViewerIdentityStats(
        userId: row['user_id'] as String,
        username: row['username'] as String?,
        displayName: (row['display_name'] as String?) ?? 'Fameverse viewer',
        avatarUrl: row['avatar_url'] as String?,
        totalCoinsSent: (row['total_coins_sent'] as num?)?.toInt() ?? 0,
        gifterLevel: (row['gifter_level'] as num?)?.toInt() ?? 1,
        roomGiftCount: (row['room_gift_count'] as num?)?.toInt() ?? 0,
        roomFameTaps: (row['room_fame_taps'] as num?)?.toInt() ?? 0,
        accountRole: row['account_role'] as String?,
      );
    }).toList();
  }

  @override
  Future<List<FvCreatorLiveSummary>> loadCreatorLiveHistory({int limit = 20}) async {
    final data = await _client.rpc('get_creator_live_history', params: {'p_limit': limit});
    return (data as List? ?? const []).map((raw) {
      final row = Map<String, dynamic>.from(raw as Map);
      return FvCreatorLiveSummary(
        roomId: row['room_id'] as String,
        title: (row['title'] as String?) ?? 'Live on Fameverse',
        goal: (row['goal'] as String?) ?? '',
        status: (row['status'] as String?) ?? 'ended',
        startedAt: DateTime.tryParse((row['started_at'] as String?) ?? ''),
        endedAt: DateTime.tryParse((row['ended_at'] as String?) ?? ''),
        rawTaps: (row['raw_taps'] as num?)?.toInt() ?? 0,
        giftCount: (row['gift_count'] as num?)?.toInt() ?? 0,
        giftCoins: (row['gift_coins'] as num?)?.toInt() ?? 0,
      );
    }).toList();
  }

  @override
  Future<List<FvCreatorGiftActivity>> loadCreatorGiftActivity({int limit = 50}) async {
    final data = await _client.rpc('get_creator_gift_activity', params: {'p_limit': limit});
    return (data as List? ?? const []).map((raw) {
      final row = Map<String, dynamic>.from(raw as Map);
      return FvCreatorGiftActivity(
        id: row['gift_event_id'] as String,
        roomId: row['room_id'] as String,
        senderUserId: row['sender_user_id'] as String,
        senderDisplayName: (row['sender_display_name'] as String?) ?? 'Fameverse viewer',
        giftId: row['gift_id'] as String,
        quantity: (row['quantity'] as num?)?.toInt() ?? 1,
        coinsSpent: (row['coins_spent'] as num?)?.toInt() ?? 0,
        createdAt: DateTime.tryParse((row['created_at'] as String?) ?? ''),
      );
    }).toList();
  }

  @override
  Future<bool> setCreatorModerator({
    required String moderatorUserId,
    required bool enabled,
  }) async {
    final data = await _client.rpc(
      'set_creator_moderator',
      params: {
        'p_moderator_user_id': moderatorUserId,
        'p_enabled': enabled,
      },
    );
    final row = _firstRpcRow(data);
    return row['is_moderator'] == true;
  }

  Map<String, dynamic> _broadcastPayload(Map<String, dynamic> raw) {
    final nested = raw['payload'];
    return nested is Map ? Map<String, dynamic>.from(nested) : raw;
  }

  @override
  FvLiveActivitySession openLiveActivity({
    required String roomId,
    FvActivityCallback? onComment,
    FvActivityCallback? onGift,
    FvActivityCallback? onCohost,
    void Function(RealtimeSubscribeStatus status)? onStatus,
  }) {
    final channel = _client.channel(
      'live-activity:$roomId',
      opts: const RealtimeChannelConfig(ack: false, self: false),
    );
    if (onComment != null) {
      channel.onBroadcast(
        event: 'comment',
        callback: (payload) => onComment(_broadcastPayload(payload)),
      );
    }
    if (onGift != null) {
      channel.onBroadcast(
        event: 'gift',
        callback: (payload) => onGift(_broadcastPayload(payload)),
      );
    }
    if (onCohost != null) {
      const cohostEvents = <String>[
        'cohost-request',
        'cohost-invite',
        'cohost-invite-accepted',
        'cohost-invite-declined',
        'cohost-invite-cancelled',
        'cohost-accept',
        'cohost-decline',
        'cohost-active',
        'cohost-source-left',
        'cohost-ended',
      ];
      for (final event in cohostEvents) {
        channel.onBroadcast(
          event: event,
          callback: (payload) {
            final data = _broadcastPayload(payload);
            onCohost({...data, '_event': event});
          },
        );
      }
    }
    channel.subscribe((status, error) => onStatus?.call(status));
    return FvLiveActivitySession(_client, channel);
  }
}

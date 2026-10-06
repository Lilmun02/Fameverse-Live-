import 'package:supabase_flutter/supabase_flutter.dart';

import 'fameverse_backend.dart';
import 'fameverse_gift_catalog.dart';
import 'fameverse_live_contract.dart';
import 'fameverse_live_models.dart';

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
      if (apiKey.isEmpty ||
          userToken.isEmpty ||
          userId.isEmpty ||
          callId.isEmpty) {
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
      'title':
          _cleanTitle(draft.title) == 'Live on Fameverse' &&
              draft.title.trim().isEmpty
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
  Future<FvCoinFundingBreakdown> loadCoinFundingBreakdown() async {
    final data = await _client.rpc('get_my_coin_funding_breakdown');
    final row = _firstRpcRow(data);
    if (row.isEmpty) return FvCoinFundingBreakdown.empty;
    return FvCoinFundingBreakdown(
      realCoins: (row['cash_backed_coins'] as num?)?.toInt() ?? 0,
      testCoins: (row['promo_coins'] as num?)?.toInt() ?? 0,
      totalCoins: (row['total_balance'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  Future<int> refillBetaWallet() async {
    final data = await _client.rpc(
      'refill_beta_wallet',
      params: {'p_amount': 10000},
    );
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
      'send_fameverse_gift',
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
      realCoinsSpent: (row['cash_backed_coins_spent'] as num?)?.toInt() ?? 0,
      testCoinsSpent: (row['promo_coins_spent'] as num?)?.toInt() ?? 0,
      creatorEarningMicros:
          (row['creator_earning_micros'] as num?)?.toInt() ?? 0,
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
  Future<List<FvCreatorLiveSummary>> loadCreatorLiveHistory({
    int limit = 20,
  }) async {
    final data = await _client.rpc(
      'get_creator_live_history',
      params: {'p_limit': limit},
    );
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
  Future<List<FvCreatorGiftActivity>> loadCreatorGiftActivity({
    int limit = 50,
  }) async {
    final data = await _client.rpc(
      'get_creator_gift_activity',
      params: {'p_limit': limit},
    );
    return (data as List? ?? const []).map((raw) {
      final row = Map<String, dynamic>.from(raw as Map);
      return FvCreatorGiftActivity(
        id: row['gift_event_id'] as String,
        roomId: row['room_id'] as String,
        senderUserId: row['sender_user_id'] as String,
        senderDisplayName:
            (row['sender_display_name'] as String?) ?? 'Fameverse viewer',
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
      params: {'p_moderator_user_id': moderatorUserId, 'p_enabled': enabled},
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
      opts: const RealtimeChannelConfig(ack: true, self: false),
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

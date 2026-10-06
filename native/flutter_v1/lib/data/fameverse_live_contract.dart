import 'package:supabase_flutter/supabase_flutter.dart';

import 'fameverse_backend.dart';
import 'fameverse_live_models.dart';

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
  Future<FvCoinFundingBreakdown> loadCoinFundingBreakdown();
  Future<int> refillBetaWallet();
  Future<FvGifterStats> loadGifterStats(String userId);
  Future<FvGiftSendResult> recordGift({
    required String roomId,
    required String giftId,
    required int quantity,
    required String fundingMode,
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

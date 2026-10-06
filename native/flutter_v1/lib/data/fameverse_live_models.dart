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
  });

  final String id;
  final String label;
  final int cost;
  final String category;
  final String? emoji;
  final String? activityEmoji;
  final String? videoUrl;
  final bool cinematic;

  String get symbol => activityEmoji ?? emoji ?? '✦';
}

class FvCoinFundingBreakdown {
  const FvCoinFundingBreakdown({
    required this.realCoins,
    required this.testCoins,
    required this.totalCoins,
  });

  final int realCoins;
  final int testCoins;
  final int totalCoins;

  static const empty = FvCoinFundingBreakdown(
    realCoins: 0,
    testCoins: 0,
    totalCoins: 0,
  );
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

  static const empty = FvGifterStats(totalCoinsSent: 0, giftCount: 0, level: 1);
}

class FvGiftSendResult {
  const FvGiftSendResult({
    required this.totalCoinsSent,
    required this.giftCount,
    required this.level,
    required this.walletBalance,
    required this.realCoinsSpent,
    required this.testCoinsSpent,
    required this.creatorEarningMicros,
  });

  final int totalCoinsSent;
  final int giftCount;
  final int level;
  final int walletBalance;
  final int realCoinsSpent;
  final int testCoinsSpent;
  final int creatorEarningMicros;
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

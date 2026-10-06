import 'package:supabase_flutter/supabase_flutter.dart';

class FvGifterAccountStats {
  const FvGifterAccountStats({
    required this.totalCoinsSent,
    required this.giftCount,
    required this.accountRole,
  });

  final int totalCoinsSent;
  final int giftCount;
  final String? accountRole;

  static const empty = FvGifterAccountStats(
    totalCoinsSent: 0,
    giftCount: 0,
    accountRole: null,
  );
}

abstract class FameverseGifterBackend {
  Future<FvGifterAccountStats> loadAccountStats(String userId);
}

class SupabaseFameverseGifterBackend implements FameverseGifterBackend {
  SupabaseFameverseGifterBackend(this._client);

  final SupabaseClient _client;

  @override
  Future<FvGifterAccountStats> loadAccountStats(String userId) async {
    final results = await Future.wait<dynamic>([
      _client
          .from('gifter_stats')
          .select('total_coins_sent, gift_count')
          .eq('user_id', userId)
          .maybeSingle(),
      _client
          .from('account_roles')
          .select('role')
          .eq('user_id', userId)
          .maybeSingle(),
    ]);

    final stats = results[0] as Map<String, dynamic>?;
    final role = results[1] as Map<String, dynamic>?;
    return FvGifterAccountStats(
      totalCoinsSent: (stats?['total_coins_sent'] as num?)?.toInt() ?? 0,
      giftCount: (stats?['gift_count'] as num?)?.toInt() ?? 0,
      accountRole: role?['role']?.toString(),
    );
  }
}

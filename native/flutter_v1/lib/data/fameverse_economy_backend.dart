import 'dart:math' as math;

import 'package:supabase_flutter/supabase_flutter.dart';

int _economyInt(dynamic value) {
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

DateTime? _economyDate(dynamic value) {
  final valueText = value?.toString();
  if (valueText == null || valueText.isEmpty) return null;
  return DateTime.tryParse(valueText);
}

class FvCoinExchangeResult {
  const FvCoinExchangeResult({
    required this.exchangeId,
    required this.amountCents,
    required this.coinsCredited,
    required this.fameCoinBalance,
    required this.creatorAvailableCents,
  });

  final String exchangeId;
  final int amountCents;
  final int coinsCredited;
  final int fameCoinBalance;
  final int creatorAvailableCents;

  factory FvCoinExchangeResult.fromMap(Map<String, dynamic> row) {
    return FvCoinExchangeResult(
      exchangeId: row['exchange_id']?.toString() ?? '',
      amountCents: _economyInt(row['amount_cents']),
      coinsCredited: _economyInt(row['coins_credited']),
      fameCoinBalance: _economyInt(row['fame_coin_balance']),
      creatorAvailableCents: _economyInt(row['creator_available_cents']),
    );
  }
}

class FvCoinExchangeItem {
  const FvCoinExchangeItem({
    required this.exchangeId,
    required this.amountCents,
    required this.coinsCredited,
    required this.createdAt,
  });

  final String exchangeId;
  final int amountCents;
  final int coinsCredited;
  final DateTime? createdAt;

  factory FvCoinExchangeItem.fromMap(Map<String, dynamic> row) {
    return FvCoinExchangeItem(
      exchangeId: row['exchange_id']?.toString() ?? '',
      amountCents: _economyInt(row['amount_cents']),
      coinsCredited: _economyInt(row['coins_credited']),
      createdAt: _economyDate(row['created_at']),
    );
  }
}

class FvBetaReferralSummary {
  const FvBetaReferralSummary({
    required this.referralCode,
    required this.qualifiedReferrals,
    required this.promoCoinsEarned,
  });

  final String? referralCode;
  final int qualifiedReferrals;
  final int promoCoinsEarned;

  factory FvBetaReferralSummary.fromMap(Map<String, dynamic> row) {
    final code = row['referral_code']?.toString().trim();
    return FvBetaReferralSummary(
      referralCode: code == null || code.isEmpty ? null : code,
      qualifiedReferrals: _economyInt(row['qualified_referrals']),
      promoCoinsEarned: _economyInt(row['promo_coins_earned']),
    );
  }

  static const empty = FvBetaReferralSummary(
    referralCode: null,
    qualifiedReferrals: 0,
    promoCoinsEarned: 0,
  );
}

class FvBetaReferralClaim {
  const FvBetaReferralClaim({
    required this.accepted,
    required this.referrerRewardCoins,
    required this.referredRewardCoins,
    required this.referredBalance,
  });

  final bool accepted;
  final int referrerRewardCoins;
  final int referredRewardCoins;
  final int referredBalance;

  factory FvBetaReferralClaim.fromMap(Map<String, dynamic> row) {
    return FvBetaReferralClaim(
      accepted: row['accepted'] == true,
      referrerRewardCoins: _economyInt(row['referrer_reward_coins']),
      referredRewardCoins: _economyInt(row['referred_reward_coins']),
      referredBalance: _economyInt(row['referred_balance']),
    );
  }
}

class SupabaseFameverseEconomyBackend {
  SupabaseFameverseEconomyBackend(this._client);

  final SupabaseClient _client;

  List<Map<String, dynamic>> _rows(dynamic response) {
    if (response is! List) return const [];
    return response
        .whereType<Map>()
        .map((row) => Map<String, dynamic>.from(row))
        .toList();
  }

  Future<int> loadFameCoinBalance() async {
    final response = await _client.rpc('get_fame_coin_balance');
    final rows = _rows(response);
    if (rows.isEmpty) return 0;
    return _economyInt(rows.first['balance']);
  }

  Future<FvCoinExchangeResult> exchangeCreatorEarnings({
    required int amountCents,
    String? idempotencyKey,
  }) async {
    if (amountCents <= 0) {
      throw ArgumentError.value(amountCents, 'amountCents');
    }
    final key = idempotencyKey ?? _newIdempotencyKey();
    final response = await _client.rpc(
      'exchange_creator_earnings_for_coins',
      params: <String, dynamic>{
        'p_amount_cents': amountCents,
        'p_idempotency_key': key,
      },
    );
    final rows = _rows(response);
    if (rows.isEmpty) throw StateError('coin-exchange-result-missing');
    return FvCoinExchangeResult.fromMap(rows.first);
  }

  Future<List<FvCoinExchangeItem>> loadExchangeHistory({int limit = 30}) async {
    final response = await _client.rpc(
      'get_creator_coin_exchange_history',
      params: <String, dynamic>{'p_limit': limit},
    );
    return _rows(response).map(FvCoinExchangeItem.fromMap).toList();
  }

  Future<String> ensureBetaReferralCode() async {
    final response = await _client.rpc('ensure_beta_referral_code');
    final code = response?.toString().trim() ?? '';
    if (code.isEmpty) throw StateError('referral-code-unavailable');
    return code;
  }

  Future<FvBetaReferralSummary> loadBetaReferralSummary() async {
    final response = await _client.rpc('get_beta_referral_summary');
    final rows = _rows(response);
    if (rows.isEmpty) return FvBetaReferralSummary.empty;
    return FvBetaReferralSummary.fromMap(rows.first);
  }

  Future<FvBetaReferralClaim> qualifyBetaReferral(String code) async {
    final response = await _client.rpc(
      'qualify_beta_referral',
      params: <String, dynamic>{'p_code': code.trim()},
    );
    final rows = _rows(response);
    if (rows.isEmpty) throw StateError('referral-result-missing');
    return FvBetaReferralClaim.fromMap(rows.first);
  }

  String _newIdempotencyKey() {
    final now = DateTime.now().microsecondsSinceEpoch;
    final random = math.Random.secure().nextInt(1 << 32);
    return 'fv-exchange-$now-$random';
  }
}

import 'package:supabase_flutter/supabase_flutter.dart';

part 'fameverse_creator_payout_models.part.dart';

int _intValue(dynamic value) {
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

DateTime? _dateValue(dynamic value) {
  final text = value?.toString();
  if (text == null || text.isEmpty) return null;
  return DateTime.tryParse(text);
}

class FvCreatorVerificationProgress {
  const FvCreatorVerificationProgress({
    required this.verificationStatus,
    required this.followerCount,
    required this.followerRequirement,
    required this.eligibleReceivedCoins,
    required this.receivedCoinsRequirement,
    required this.eligible,
    required this.requestedAt,
    required this.reviewedAt,
    required this.publicNote,
    required this.updatedAt,
  });

  final String verificationStatus;
  final int followerCount;
  final int followerRequirement;
  final int eligibleReceivedCoins;
  final int receivedCoinsRequirement;
  final bool eligible;
  final DateTime? requestedAt;
  final DateTime? reviewedAt;
  final String? publicNote;
  final DateTime? updatedAt;

  bool get isVerified => verificationStatus == 'verified';
  bool get isPending => verificationStatus == 'pending';
  bool get needsInfo => verificationStatus == 'needs_info';

  factory FvCreatorVerificationProgress.fromMap(Map<String, dynamic> row) {
    return FvCreatorVerificationProgress(
      verificationStatus:
          row['verification_status']?.toString().trim().toLowerCase() ??
          'unverified',
      followerCount: _intValue(row['follower_count']),
      followerRequirement: _intValue(row['follower_requirement']),
      eligibleReceivedCoins: _intValue(row['eligible_received_coins']),
      receivedCoinsRequirement: _intValue(row['received_coins_requirement']),
      eligible: row['eligible'] == true,
      requestedAt: _dateValue(row['requested_at']),
      reviewedAt: _dateValue(row['reviewed_at']),
      publicNote: row['public_note']?.toString(),
      updatedAt: _dateValue(row['updated_at']),
    );
  }

  static const empty = FvCreatorVerificationProgress(
    verificationStatus: 'unverified',
    followerCount: 0,
    followerRequirement: 100,
    eligibleReceivedCoins: 0,
    receivedCoinsRequirement: 500000,
    eligible: false,
    requestedAt: null,
    reviewedAt: null,
    publicNote: null,
    updatedAt: null,
  );
}

class FvVerificationModerationItem {
  const FvVerificationModerationItem({
    required this.userId,
    required this.displayName,
    required this.username,
    required this.status,
    required this.requestedAt,
    required this.publicNote,
  });

  final String userId;
  final String displayName;
  final String? username;
  final String status;
  final DateTime? requestedAt;
  final String? publicNote;

  factory FvVerificationModerationItem.fromMap(Map<String, dynamic> row) {
    return FvVerificationModerationItem(
      userId: row['user_id']?.toString() ?? '',
      displayName: row['display_name']?.toString() ?? 'Fameverse User',
      username: row['username'] as String?,
      status: row['status']?.toString() ?? 'pending',
      requestedAt: _dateValue(row['requested_at']),
      publicNote: row['public_note'] as String?,
    );
  }
}

class SupabaseFameverseCreatorBackend {
  SupabaseFameverseCreatorBackend(this._client);

  final SupabaseClient _client;

  List<Map<String, dynamic>> _rows(dynamic response) {
    if (response is! List) return const [];
    return response
        .whereType<Map>()
        .map((row) => Map<String, dynamic>.from(row))
        .toList();
  }

  Future<String?> loadRole(String userId) async {
    final row = await _client
        .from('account_roles')
        .select('role')
        .eq('user_id', userId)
        .maybeSingle();
    return (row?['role'] as String?)?.trim().toLowerCase();
  }

  Future<FvCreatorPayoutMethod?> loadPayoutMethod() async {
    final response = await _client.rpc('get_creator_payout_method');
    final rows = _rows(response);
    if (rows.isEmpty) return null;
    return FvCreatorPayoutMethod.fromMap(rows.first);
  }

  Future<FvCreatorPayoutMethod> setPayoutMethod({
    required String recipientEmail,
  }) async {
    final response = await _client.rpc(
      'set_creator_payout_method',
      params: {
        'p_provider': 'paypal',
        'p_recipient_email': recipientEmail.trim(),
      },
    );
    final rows = _rows(response);
    if (rows.isEmpty) throw Exception('Payout method was not saved.');
    return FvCreatorPayoutMethod.fromMap(rows.first);
  }

  Future<FvCreatorPayoutSummary> loadPayoutSummary() async {
    final response = await _client.rpc('get_creator_payout_summary');
    final rows = _rows(response);
    if (rows.isEmpty) return FvCreatorPayoutSummary.empty;
    return FvCreatorPayoutSummary.fromMap(rows.first);
  }

  Future<List<FvCreatorPayoutRequest>> listPayoutRequests({
    int limit = 20,
  }) async {
    final response = await _client.rpc(
      'get_creator_payout_requests',
      params: {'p_limit': limit},
    );
    return _rows(response).map(FvCreatorPayoutRequest.fromMap).toList();
  }

  Future<FvCreatorVerificationProgress> loadVerificationProgress() async {
    final response = await _client.rpc('get_creator_verification_progress');
    final rows = _rows(response);
    if (rows.isEmpty) return FvCreatorVerificationProgress.empty;
    return FvCreatorVerificationProgress.fromMap(rows.first);
  }

  Future<String> requestVerification() async {
    final response = await _client.rpc('request_creator_verification');
    return response?.toString() ?? 'pending';
  }

  Future<FvCreatorPayoutRequest> requestPayout(int amountCents) async {
    final response = await _client.rpc(
      'request_creator_payout',
      params: {'p_amount_cents': amountCents},
    );
    final rows = _rows(response);
    if (rows.isEmpty) throw Exception('Payout request was not created.');
    return FvCreatorPayoutRequest.fromMap(rows.first);
  }

  Future<List<FvVerificationModerationItem>> listVerificationQueue({
    int limit = 50,
  }) async {
    final response = await _client.rpc(
      'get_creator_verification_moderation_queue',
      params: {'p_limit': limit},
    );
    return _rows(response).map(FvVerificationModerationItem.fromMap).toList();
  }

  Future<String> reviewVerification({
    required String userId,
    required String status,
    String? publicNote,
  }) async {
    final response = await _client.rpc(
      'review_creator_verification',
      params: {
        'p_user_id': userId,
        'p_status': status,
        'p_public_note': publicNote,
      },
    );
    return response?.toString() ?? status;
  }

  Future<List<FvPayoutModerationItem>> listPayoutQueue({int limit = 50}) async {
    final response = await _client.rpc(
      'get_creator_payout_moderation_queue',
      params: {'p_limit': limit},
    );
    return _rows(response).map(FvPayoutModerationItem.fromMap).toList();
  }

  Future<String> reviewPayout({
    required String payoutId,
    required String status,
    String? moderationNote,
    String? externalReference,
  }) async {
    final response = await _client.rpc(
      'review_creator_payout',
      params: {
        'p_payout_id': payoutId,
        'p_status': status,
        'p_moderation_note': moderationNote,
        'p_external_reference': externalReference,
      },
    );
    return response?.toString() ?? status;
  }
}

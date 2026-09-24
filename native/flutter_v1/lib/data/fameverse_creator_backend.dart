import 'package:supabase_flutter/supabase_flutter.dart';

int _intValue(dynamic value) {
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

DateTime? _dateValue(dynamic value) {
  final text = value?.toString();
  if (text == null || text.isEmpty) return null;
  return DateTime.tryParse(text);
}

class FvCreatorPayoutSummary {
  const FvCreatorPayoutSummary({
    required this.verificationStatus,
    required this.pendingCents,
    required this.availableCents,
    required this.reservedCents,
    required this.withdrawableCents,
    required this.paidCents,
    required this.minimumPayoutCents,
  });

  final String verificationStatus;
  final int pendingCents;
  final int availableCents;
  final int reservedCents;
  final int withdrawableCents;
  final int paidCents;
  final int minimumPayoutCents;

  bool get isVerified => verificationStatus == 'verified';
  bool get canRequestPayout =>
      isVerified && withdrawableCents >= minimumPayoutCents;

  factory FvCreatorPayoutSummary.fromMap(Map<String, dynamic> row) {
    return FvCreatorPayoutSummary(
      verificationStatus:
          (row['verification_status'] as String?)?.trim().toLowerCase() ??
          'unverified',
      pendingCents: _intValue(row['pending_cents']),
      availableCents: _intValue(row['available_cents']),
      reservedCents: _intValue(row['reserved_cents']),
      withdrawableCents: _intValue(row['withdrawable_cents']),
      paidCents: _intValue(row['paid_cents']),
      minimumPayoutCents: _intValue(row['minimum_payout_cents']),
    );
  }

  static const empty = FvCreatorPayoutSummary(
    verificationStatus: 'unverified',
    pendingCents: 0,
    availableCents: 0,
    reservedCents: 0,
    withdrawableCents: 0,
    paidCents: 0,
    minimumPayoutCents: 2500,
  );
}

class FvCreatorPayoutRequest {
  const FvCreatorPayoutRequest({
    required this.id,
    required this.amountCents,
    required this.status,
    required this.requestedAt,
    required this.reviewedAt,
    required this.paidAt,
    required this.moderationNote,
    required this.externalReference,
  });

  final String id;
  final int amountCents;
  final String status;
  final DateTime? requestedAt;
  final DateTime? reviewedAt;
  final DateTime? paidAt;
  final String? moderationNote;
  final String? externalReference;

  factory FvCreatorPayoutRequest.fromMap(Map<String, dynamic> row) {
    return FvCreatorPayoutRequest(
      id: row['payout_id']?.toString() ?? row['id']?.toString() ?? '',
      amountCents: _intValue(row['amount_cents']),
      status: (row['status'] as String?) ?? 'pending_review',
      requestedAt: _dateValue(row['requested_at']),
      reviewedAt: _dateValue(row['reviewed_at']),
      paidAt: _dateValue(row['paid_at']),
      moderationNote: row['moderation_note'] as String?,
      externalReference: row['external_reference'] as String?,
    );
  }
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

class FvPayoutModerationItem {
  const FvPayoutModerationItem({
    required this.payoutId,
    required this.creatorUserId,
    required this.displayName,
    required this.username,
    required this.verificationStatus,
    required this.amountCents,
    required this.status,
    required this.requestedAt,
    required this.moderationNote,
    required this.externalReference,
  });

  final String payoutId;
  final String creatorUserId;
  final String displayName;
  final String? username;
  final String verificationStatus;
  final int amountCents;
  final String status;
  final DateTime? requestedAt;
  final String? moderationNote;
  final String? externalReference;

  factory FvPayoutModerationItem.fromMap(Map<String, dynamic> row) {
    return FvPayoutModerationItem(
      payoutId: row['payout_id']?.toString() ?? '',
      creatorUserId: row['creator_user_id']?.toString() ?? '',
      displayName: row['display_name']?.toString() ?? 'Fameverse User',
      username: row['username'] as String?,
      verificationStatus:
          row['verification_status']?.toString() ?? 'unverified',
      amountCents: _intValue(row['amount_cents']),
      status: row['status']?.toString() ?? 'pending_review',
      requestedAt: _dateValue(row['requested_at']),
      moderationNote: row['moderation_note'] as String?,
      externalReference: row['external_reference'] as String?,
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

  Future<List<FvPayoutModerationItem>> listPayoutQueue({
    int limit = 50,
  }) async {
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

part of 'fameverse_creator_backend.dart';

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
    required this.providerStatus,
    required this.providerBatchId,
    required this.providerStatusUpdatedAt,
    required this.payoutEnvironment,
    required this.isQa,
  });

  final String id;
  final int amountCents;
  final String status;
  final DateTime? requestedAt;
  final DateTime? reviewedAt;
  final DateTime? paidAt;
  final String? moderationNote;
  final String? externalReference;
  final String? providerStatus;
  final String? providerBatchId;
  final DateTime? providerStatusUpdatedAt;
  final String payoutEnvironment;
  final bool isQa;

  factory FvCreatorPayoutRequest.fromMap(Map<String, dynamic> row) {
    return FvCreatorPayoutRequest(
      id: row['payout_id']?.toString() ?? row['id']?.toString() ?? '',
      amountCents: _intValue(row['amount_cents']),
      status: (row['status'] as String?) ?? 'pending_review',
      requestedAt: _dateValue(row['requested_at']),
      reviewedAt: _dateValue(row['reviewed_at']),
      paidAt: _dateValue(row['paid_at']),
      moderationNote: row['moderation_note']?.toString(),
      externalReference: row['external_reference']?.toString(),
      providerStatus: row['provider_status']?.toString(),
      providerBatchId: row['provider_batch_id']?.toString(),
      providerStatusUpdatedAt: _dateValue(row['provider_status_updated_at']),
      payoutEnvironment:
          row['payout_environment']?.toString().toLowerCase() == 'sandbox'
          ? 'sandbox'
          : 'live',
      isQa: row['is_qa'] == true,
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

class FvCreatorPayoutMethod {
  const FvCreatorPayoutMethod({
    required this.provider,
    required this.liveRecipientEmail,
    required this.sandboxRecipientEmail,
    required this.enabled,
  });

  final String provider;
  final String liveRecipientEmail;
  final String sandboxRecipientEmail;
  final bool enabled;

  String get recipientEmail => liveRecipientEmail;

  factory FvCreatorPayoutMethod.fromMap(Map<String, dynamic> row) {
    return FvCreatorPayoutMethod(
      provider: row['provider']?.toString() ?? 'paypal',
      liveRecipientEmail: row['live_recipient_email']?.toString() ?? '',
      sandboxRecipientEmail:
          row['sandbox_recipient_email']?.toString() ?? '',
      enabled: row['enabled'] == true,
    );
  }
}

class FvCreatorQaPayoutSummary {
  const FvCreatorQaPayoutSummary({
    required this.availableCents,
    required this.reservedCents,
    required this.withdrawableCents,
    required this.paidCents,
    required this.minimumPayoutCents,
  });

  final int availableCents;
  final int reservedCents;
  final int withdrawableCents;
  final int paidCents;
  final int minimumPayoutCents;

  bool get canRequestPayout => withdrawableCents >= minimumPayoutCents;

  factory FvCreatorQaPayoutSummary.fromMap(Map<String, dynamic> row) {
    return FvCreatorQaPayoutSummary(
      availableCents: _intValue(row['qa_available_cents']),
      reservedCents: _intValue(row['qa_reserved_cents']),
      withdrawableCents: _intValue(row['qa_withdrawable_cents']),
      paidCents: _intValue(row['qa_paid_cents']),
      minimumPayoutCents: _intValue(row['minimum_qa_payout_cents']),
    );
  }

  static const empty = FvCreatorQaPayoutSummary(
    availableCents: 0,
    reservedCents: 0,
    withdrawableCents: 0,
    paidCents: 0,
    minimumPayoutCents: 100,
  );
}


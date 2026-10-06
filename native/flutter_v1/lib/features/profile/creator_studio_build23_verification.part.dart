part of 'creator_studio_build23.dart';

class _VerificationCard extends StatelessWidget {
  const _VerificationCard({
    required this.isOwner,
    required this.summary,
    required this.progress,
    required this.busy,
    required this.onRequest,
  });

  final bool isOwner;
  final FvCreatorPayoutSummary summary;
  final FvCreatorVerificationProgress progress;
  final bool busy;
  final VoidCallback onRequest;

  @override
  Widget build(BuildContext context) {
    if (isOwner) {
      return Container(
        key: const Key('owner-verification-bypass'),
        padding: const EdgeInsets.all(17),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF6F4A2A)),
          color: const Color(0xFF17111B),
        ),
        child: const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.verified_rounded, color: Color(0xFFFFCE78)),
            SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Owner access',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'Creator verification requirements do not apply to the Fameverse Owner.',
                    style: TextStyle(
                      color: Color(0xFFB8ACBC),
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final status = progress.verificationStatus.isEmpty
        ? summary.verificationStatus
        : progress.verificationStatus;
    final verified = status == 'verified';
    final pending = status == 'pending';
    final needsInfo = status == 'needs_info';
    final rejected = status == 'rejected';
    final canRequest = progress.eligible && !busy && !pending && !verified;
    final statusTime =
        progress.reviewedAt ?? progress.requestedAt ?? progress.updatedAt;
    final statusLabel = switch (status) {
      'verified' => 'Verified',
      'pending' => 'Under review',
      'needs_info' => 'Needs information',
      'rejected' => 'Not approved',
      'suspended' => 'Suspended',
      _ => 'Not submitted',
    };
    var statusMessage =
        'Complete both requirements below to unlock the verification request.';
    if (verified) {
      statusMessage = 'Your creator account is verified.';
    } else if (pending) {
      statusMessage =
          'Verification is processing in Fameverse review. '
          'You do not need to submit it again.';
    } else if (needsInfo) {
      statusMessage =
          'Fameverse needs more information before verification can be approved.';
    } else if (rejected) {
      statusMessage =
          'The last verification request was not approved. '
          'You can submit again after the requirements are met.';
    }
    final statusTimeText = statusTime == null
        ? ''
        : '${pending ? 'Submitted' : 'Updated'} '
              '${_creatorStatusTime(statusTime)}';

    return Container(
      key: const Key('creator-verification-center'),
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF513862)),
        color: const Color(0xFF17111B),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                verified ? Icons.verified_rounded : Icons.verified_outlined,
                color: verified
                    ? const Color(0xFF72D49B)
                    : const Color(0xFFC78BFA),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Creator verification',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                ),
              ),
              if (verified)
                const Icon(
                  Icons.check_circle_rounded,
                  color: Color(0xFF72D49B),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            statusMessage,
            style: const TextStyle(
              color: Color(0xFFB8ACBC),
              fontSize: 12,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          Chip(
            key: const Key('creator-verification-status'),
            label: Text(statusLabel),
          ),
          if (statusTime != null) ...[
            const SizedBox(height: 6),
            Text(
              statusTimeText,
              key: const Key('creator-verification-status-time'),
              style: const TextStyle(color: Color(0xFF96899C), fontSize: 10),
            ),
          ],
          if ((progress.publicNote ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              progress.publicNote!.trim(),
              key: const Key('creator-verification-review-note'),
              style: const TextStyle(
                color: Color(0xFFC7B8CD),
                fontSize: 11,
                height: 1.35,
              ),
            ),
          ],
          const SizedBox(height: 16),
          _VerificationProgressLine(
            key: const Key('creator-verification-followers-progress'),
            label: 'Followers',
            value: progress.followerCount,
            requirement: progress.followerRequirement,
          ),
          const SizedBox(height: 14),
          _VerificationProgressLine(
            key: const Key('creator-verification-coins-progress'),
            label: 'Eligible Fame Coins received',
            value: progress.eligibleReceivedCoins,
            requirement: progress.receivedCoinsRequirement,
          ),
          const SizedBox(height: 10),
          const Text(
            'Only legitimate cash-backed gifts count. Promotional, referral, owner-QA and self-gifts do not count toward verification.',
            style: TextStyle(
              color: Color(0xFF96899C),
              fontSize: 10,
              height: 1.4,
            ),
          ),
          if (!verified) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                key: const Key('creator-verification-request'),
                onPressed: canRequest ? onRequest : null,
                child: Text(
                  pending
                      ? 'Under review'
                      : needsInfo
                      ? 'Resubmit verification'
                      : 'Request verification',
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _VerificationProgressLine extends StatelessWidget {
  const _VerificationProgressLine({
    required this.label,
    required this.value,
    required this.requirement,
    super.key,
  });

  final String label;
  final int value;
  final int requirement;

  @override
  Widget build(BuildContext context) {
    final safeRequirement = requirement <= 0 ? 1 : requirement;
    final ratio = (value / safeRequirement).clamp(0.0, 1.0).toDouble();
    final complete = value >= safeRequirement;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ),
            Text(
              '$value / $requirement',
              style: TextStyle(
                color: complete
                    ? const Color(0xFF72D49B)
                    : const Color(0xFFC7B8CD),
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 8,
            backgroundColor: const Color(0xFF2A2030),
          ),
        ),
      ],
    );
  }
}

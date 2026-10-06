part of 'owner_control_center_build23.dart';

class _VerificationReviewCard extends StatelessWidget {
  const _VerificationReviewCard({
    required this.request,
    required this.busy,
    required this.onApprove,
    required this.onNeedsInfo,
    required this.onReject,
  });

  final Map<String, dynamic> request;
  final bool busy;
  final VoidCallback onApprove;
  final VoidCallback onNeedsInfo;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final displayName =
        request['display_name']?.toString() ?? 'Fameverse Creator';
    final username = request['username']?.toString();
    final status = request['status']?.toString() ?? 'pending';
    final userId = request['user_id']?.toString() ?? 'unknown';
    return Container(
      key: Key('owner-verification-$userId'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF17111B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF4A3553)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            displayName,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
          ),
          if (username != null && username.isNotEmpty)
            Text(
              '@$username',
              style: const TextStyle(color: Color(0xFFA89CAE)),
            ),
          const SizedBox(height: 8),
          Chip(label: Text(status.replaceAll('_', ' '))),
          if ((request['public_note']?.toString() ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              request['public_note'].toString().trim(),
              style: const TextStyle(color: Color(0xFFB8ACBC), fontSize: 11),
            ),
          ],
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton(
                key: const Key('owner-verification-approve'),
                onPressed: busy ? null : onApprove,
                child: const Text('Verify'),
              ),
              FilledButton.tonal(
                key: const Key('owner-verification-needs-info'),
                onPressed: busy ? null : onNeedsInfo,
                child: const Text('Needs info'),
              ),
              TextButton(
                key: const Key('owner-verification-reject'),
                onPressed: busy ? null : onReject,
                child: const Text('Reject'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PayoutCard extends StatelessWidget {
  const _PayoutCard({
    required this.payout,
    required this.busy,
    required this.onApprove,
    required this.onHold,
    required this.onReject,
    required this.onProcess,
    required this.onSync,
  });

  final Map<String, dynamic> payout;
  final bool busy;
  final VoidCallback onApprove;
  final VoidCallback onHold;
  final VoidCallback onReject;
  final VoidCallback onProcess;
  final VoidCallback onSync;

  @override
  Widget build(BuildContext context) {
    final status = payout['status']?.toString() ?? 'pending_review';
    final creator = payout['display_name']?.toString() ?? 'Fameverse Creator';
    final username = payout['username']?.toString();
    final verification =
        payout['verification_status']?.toString() ?? 'unverified';
    final amount = _money((payout['amount_cents'] as num?)?.toInt() ?? 0);
    final providerStatus = payout['provider_status']?.toString() ?? '';
    final providerBatchId = payout['provider_batch_id']?.toString() ?? '';
    final needsProviderRecovery =
        status == 'processing' &&
        providerBatchId.isEmpty &&
        (providerStatus == 'SUBMISSION_UNKNOWN' ||
            providerStatus == 'SUBMITTING');
    return Container(
      key: Key('owner-payout-${payout['payout_id']}'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF17111B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF4A3553)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      creator,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (username != null && username.isNotEmpty)
                      Text(
                        '@$username',
                        style: const TextStyle(color: Color(0xFFA89CAE)),
                      ),
                  ],
                ),
              ),
              Text(
                amount,
                style: const TextStyle(
                  color: Color(0xFFFFD38E),
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Chip(label: Text(status.replaceAll('_', ' '))),
              Chip(label: Text('Verification: $verification')),
              if (providerStatus.isNotEmpty)
                Chip(
                  label: Text('PayPal: ${providerStatus.replaceAll('_', ' ')}'),
                ),
            ],
          ),
          if ((payout['moderation_note']?.toString() ?? '').isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              payout['moderation_note'].toString(),
              style: const TextStyle(color: Color(0xFFB8ACBC), fontSize: 11),
            ),
          ],
          const SizedBox(height: 12),
          if (status == 'pending_review')
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton(
                  key: const Key('owner-payout-approve'),
                  onPressed: busy ? null : onApprove,
                  child: const Text('Approve'),
                ),
                FilledButton.tonal(
                  onPressed: busy ? null : onHold,
                  child: const Text('Hold'),
                ),
                TextButton(
                  onPressed: busy ? null : onReject,
                  child: const Text('Reject'),
                ),
              ],
            )
          else if (status == 'approved')
            FilledButton.icon(
              key: const Key('owner-payout-begin-processing'),
              onPressed: busy ? null : onProcess,
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('Send with PayPal sandbox'),
            )
          else if (status == 'processing' && needsProviderRecovery)
            FilledButton.icon(
              key: const Key('owner-payout-recover-provider'),
              onPressed: busy ? null : onProcess,
              icon: const Icon(Icons.restart_alt_rounded),
              label: const Text('Recover PayPal submission'),
            )
          else if (status == 'processing')
            FilledButton.icon(
              key: const Key('owner-payout-sync-provider'),
              onPressed: busy ? null : onSync,
              icon: const Icon(Icons.sync_rounded),
              label: const Text('Sync PayPal status'),
            ),
        ],
      ),
    );
  }
}

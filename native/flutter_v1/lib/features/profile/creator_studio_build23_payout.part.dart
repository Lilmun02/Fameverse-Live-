part of 'creator_studio_build23.dart';

class _PayoutMethodCard extends StatelessWidget {
  const _PayoutMethodCard({
    required this.method,
    required this.busy,
    required this.onEdit,
  });

  final FvCreatorPayoutMethod? method;
  final bool busy;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final email = method?.recipientEmail.trim() ?? '';
    return _ActionCard(
      icon: Icons.paypal_outlined,
      title: 'PayPal payout method',
      subtitle: email.isEmpty ? 'No payout email saved' : email,
      trailing: TextButton(
        onPressed: busy ? null : onEdit,
        child: Text(email.isEmpty ? 'Add' : 'Edit'),
      ),
    );
  }
}

class _PayoutCard extends StatelessWidget {
  const _PayoutCard({
    required this.summary,
    required this.hasMethod,
    required this.busy,
    required this.onRequest,
  });

  final FvCreatorPayoutSummary summary;
  final bool hasMethod;
  final bool busy;
  final VoidCallback onRequest;

  @override
  Widget build(BuildContext context) {
    final canRequest = summary.canRequestPayout && hasMethod && !busy;
    return _ActionCard(
      icon: Icons.payments_outlined,
      title: 'Request payout',
      subtitle:
          'Minimum ${_money(summary.minimumPayoutCents)} · available ${_money(summary.withdrawableCents)}',
      trailing: FilledButton(
        key: const Key('build23-request-payout'),
        onPressed: canRequest ? onRequest : null,
        child: const Text('Request'),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF3A2B42)),
        color: const Color(0xFF151018),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFC78BFA)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFFA99DAD),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          trailing,
        ],
      ),
    );
  }
}

class _PayoutTile extends StatelessWidget {
  const _PayoutTile({required this.request});
  final FvCreatorPayoutRequest request;

  @override
  Widget build(BuildContext context) {
    final providerStatus = (request.providerStatus ?? '').trim().toUpperCase();
    final processing = request.status == 'processing';
    final missingProviderBatch =
        processing && (request.providerBatchId ?? '').trim().isEmpty;
    final statusText = request.status.replaceAll('_', ' ');
    var providerText = '';
    if (processing &&
        missingProviderBatch &&
        (providerStatus == 'SUBMISSION_UNKNOWN' ||
            providerStatus == 'SUBMITTING')) {
      providerText =
          'PayPal submission is being recovered. Funds remain reserved.';
    } else if (processing && providerStatus.isNotEmpty) {
      providerText = 'PayPal: ${providerStatus.replaceAll('_', ' ')}';
    } else if (processing) {
      providerText = 'PayPal processing is waiting for a provider update.';
    }
    final providerStatusTime = request.providerStatusUpdatedAt;
    final providerStatusTimeText = providerStatusTime == null
        ? ''
        : 'Provider update ${_creatorStatusTime(providerStatusTime)}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFF34283A)),
          color: const Color(0xFF151018),
        ),
        child: Row(
          children: [
            const Icon(Icons.receipt_long_outlined, color: Color(0xFFC68AFF)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _money(request.amountCents),
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    statusText,
                    key: const Key('creator-payout-status'),
                    style: const TextStyle(
                      color: Color(0xFFA99DAD),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (providerText.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      providerText,
                      key: const Key('creator-payout-provider-status'),
                      style: const TextStyle(
                        color: Color(0xFFC7B8CD),
                        fontSize: 10,
                        height: 1.3,
                      ),
                    ),
                    if (request.providerStatusUpdatedAt != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        providerStatusTimeText,
                        key: const Key('creator-payout-provider-status-time'),
                        style: const TextStyle(
                          color: Color(0xFF96899C),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ],
                  if ((request.moderationNote ?? '').trim().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      request.moderationNote!.trim(),
                      style: const TextStyle(
                        color: Color(0xFF96899C),
                        fontSize: 10,
                        height: 1.3,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF3B2C43)),
        color: const Color(0xFF151018),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFFC78AFF)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: const TextStyle(
                    color: Color(0xFFA99DAD),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFF8D7F94),
        fontSize: 10,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.5,
      ),
    );
  }
}

String _money(int cents) => '\$${(cents / 100).toStringAsFixed(2)}';

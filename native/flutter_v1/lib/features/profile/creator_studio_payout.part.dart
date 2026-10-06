part of 'creator_studio_screen.dart';

class _PayoutEligibilityCard extends StatelessWidget {
  const _PayoutEligibilityCard({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final normalized = status.trim().toLowerCase();
    final title = switch (normalized) {
      'verified' => 'Payout eligibility approved',
      'pending' => 'Payout setup under review',
      'needs_info' => 'Payout setup needs information',
      'rejected' => 'Payout setup not approved',
      'suspended' => 'Payout access suspended',
      _ => 'Payout setup not started',
    };
    final body = switch (normalized) {
      'verified' =>
        'Your creator payout eligibility is approved. This is separate from any public profile verification badge.',
      'pending' =>
        'Your payout eligibility is being reviewed. This review is separate from public account verification.',
      'needs_info' =>
        'Fameverse needs additional payout information. The external beta does not collect that information on this screen yet.',
      'rejected' =>
        'Payout eligibility was not approved. A future payout setup flow will show the required next steps.',
      'suspended' =>
        'Payout requests are currently disabled for this creator account.',
      _ =>
        'Payout onboarding is not open in this external beta yet. We will not ask you to press a vague verification button or submit incomplete information.',
    };
    final icon = normalized == 'verified'
        ? Icons.check_circle_rounded
        : normalized == 'pending'
        ? Icons.schedule_rounded
        : Icons.account_balance_outlined;

    return Container(
      key: const Key('payout-eligibility-card'),
      padding: const EdgeInsets.all(18),
      decoration: _panelDecoration(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFFB784FF)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  body,
                  style: const TextStyle(color: Color(0xFFB7ACBF), height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

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
    final configured =
        method?.enabled == true && method!.recipientEmail.isNotEmpty;
    return Container(
      key: const Key('creator-paypal-payout-method'),
      padding: const EdgeInsets.all(18),
      decoration: _panelDecoration(),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF1C2B55),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.paypal_outlined, color: Color(0xFF8BB7FF)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'PayPal payout method',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 3),
                Text(
                  configured
                      ? method!.recipientEmail
                      : 'No PayPal payout email added',
                  style: TextStyle(
                    color: configured
                        ? const Color(0xFFDAD0DF)
                        : const Color(0xFFFFB5C2),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Fame Coins are not cashable. Approved Creator Earnings are paid separately.',
                  style: TextStyle(
                    color: Color(0xFF93889B),
                    fontSize: 10,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: busy ? null : onEdit,
            child: Text(configured ? 'Change' : 'Add'),
          ),
        ],
      ),
    );
  }
}

class _PayoutCard extends StatelessWidget {
  const _PayoutCard({
    required this.summary,
    required this.hasPayoutMethod,
    required this.busy,
    required this.onRequest,
  });

  final FvCreatorPayoutSummary summary;
  final bool hasPayoutMethod;
  final bool busy;
  final VoidCallback onRequest;

  @override
  Widget build(BuildContext context) {
    final disabledReason = !hasPayoutMethod
        ? 'Add PayPal payout email'
        : !summary.isVerified
        ? 'Payout setup required'
        : summary.withdrawableCents < summary.minimumPayoutCents
        ? '${_money(summary.minimumPayoutCents)} minimum'
        : null;

    return Container(
      key: const Key('creator-payout-card'),
      padding: const EdgeInsets.all(18),
      decoration: _panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.payments_outlined),
              SizedBox(width: 10),
              Text(
                'Payouts',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            r'Minimum payout: $25.00',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          const Text(
            'Only cleared creator earnings can be requested. Every payout enters review before processing.',
            style: TextStyle(color: Color(0xFFB7ACBF), height: 1.4),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              key: const Key('request-creator-payout'),
              onPressed: busy || !hasPayoutMethod || !summary.canRequestPayout
                  ? null
                  : onRequest,
              child: Text(disabledReason ?? 'Request payout'),
            ),
          ),
        ],
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: _panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 19, color: const Color(0xFFB784FF)),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(color: Color(0xFFAFA4B8), fontSize: 12),
          ),
        ],
      ),
    );
  }
}

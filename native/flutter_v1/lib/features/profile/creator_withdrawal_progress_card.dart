import 'package:flutter/material.dart';

import '../../data/fameverse_creator_backend.dart';

/// Displays only cleared, unreserved creator earnings toward the minimum.
/// Promotional/test gifts and pending money cannot advance this progress bar.
class FvWithdrawalProgressCard extends StatelessWidget {
  const FvWithdrawalProgressCard({required this.summary, super.key});

  final FvCreatorPayoutSummary summary;

  String _usd(int cents) => r'$' + (cents / 100).toStringAsFixed(2);

  @override
  Widget build(BuildContext context) {
    final minimum = summary.minimumPayoutCents > 0
        ? summary.minimumPayoutCents
        : 2500;
    final available = summary.withdrawableCents > 0
        ? summary.withdrawableCents
        : 0;
    final reached = available >= minimum;
    final remaining = reached ? 0 : minimum - available;
    final fraction = reached ? 1.0 : available / minimum;

    return Container(
      key: const Key('creator-withdrawal-progress-card'),
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
              const Expanded(
                child: Text(
                  'Minimum withdrawal',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                ),
              ),
              Text(
                _usd(minimum),
                key: const Key('creator-withdrawal-minimum'),
                style: const TextStyle(
                  color: Color(0xFFD6ACFF),
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _usd(available) + ' / ' + _usd(minimum) + ' available',
            key: const Key('creator-withdrawal-earned-label'),
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 9),
          LinearProgressIndicator(
            key: const Key('creator-withdrawal-progress-bar'),
            value: fraction,
            minHeight: 10,
            borderRadius: BorderRadius.circular(9),
            backgroundColor: const Color(0xFF37283D),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFC78BFA)),
          ),
          const SizedBox(height: 10),
          Text(
            reached
                ? 'Withdrawal minimum reached. Verification and payout setup still apply.'
                : _usd(remaining) +
                      ' more in cleared earnings to reach the minimum.',
            key: const Key('creator-withdrawal-remaining-label'),
            style: const TextStyle(
              color: Color(0xFFD4C3DC),
              fontSize: 12,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Pending earnings and promotional/test gifts do not count toward withdrawals.',
            style: TextStyle(
              color: Color(0xFFAA9CB2),
              fontSize: 11,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

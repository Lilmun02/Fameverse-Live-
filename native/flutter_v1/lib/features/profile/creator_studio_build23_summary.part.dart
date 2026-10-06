part of 'creator_studio_build23.dart';

class _Hero extends StatelessWidget {
  const _Hero({required this.isOwner});
  final bool isOwner;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isOwner ? const Color(0xFFAA7436) : const Color(0xFF5A3973),
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isOwner
              ? const [Color(0xFF472B17), Color(0xFF24132A), Color(0xFF110B17)]
              : const [Color(0xFF482164), Color(0xFF21112D), Color(0xFF110B17)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isOwner ? 'FAMEVERSE OWNER PREMIUM' : 'FAMEVERSE CREATOR',
            style: TextStyle(
              color: isOwner
                  ? const Color(0xFFFFD69A)
                  : const Color(0xFFD6B7FF),
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 9),
          const Text(
            'Build. Earn. Grow.',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          const Text(
            'Real payout money and promotional QA value are shown separately so test gifts can never be mistaken for withdrawable cash.',
            style: TextStyle(color: Color(0xFFC4B8CC), height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _OwnerPremiumCard extends StatelessWidget {
  const _OwnerPremiumCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('owner-premium-unlocked-card'),
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF9C6B36)),
        color: const Color(0xFF201518),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.workspace_premium_rounded, color: Color(0xFFFFD17A)),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Premium owner access',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                SizedBox(height: 4),
                Text(
                  'Owner-facing previews stay readable. Build 23 removes the blurred/locked Creator Studio preview from the owner experience.',
                  style: TextStyle(
                    color: Color(0xFFC2B4C5),
                    fontSize: 12,
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

class _PromoCard extends StatelessWidget {
  const _PromoCard({
    required this.grossCoins,
    required this.creatorEquivalentCents,
  });

  final int grossCoins;
  final int creatorEquivalentCents;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('promotional-non-withdrawable-earnings'),
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF5E4770)),
        color: const Color(0xFF17121B),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.science_outlined, color: Color(0xFFC68AFF)),
              SizedBox(width: 9),
              Expanded(
                child: Text(
                  'Promotional (non-withdrawable)',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _Metric(
                  label: 'Promo gifts received',
                  value: '$grossCoins coins',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _Metric(
                  label: 'Creator test value',
                  value: _money(creatorEquivalentCents),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'This balance proves promo/test gifting is being recorded. It is not cash-backed, cannot be withdrawn, and is never added to real Creator Earnings.',
            style: TextStyle(
              color: Color(0xFFA99DAE),
              fontSize: 11,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        color: const Color(0xFF211829),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: const TextStyle(color: Color(0xFF9E91A3), fontSize: 10),
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
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF3C2B45)),
        color: const Color(0xFF151018),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: const Color(0xFFC98BFF)),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: const TextStyle(color: Color(0xFFA195A5), fontSize: 11),
          ),
        ],
      ),
    );
  }
}

String _creatorStatusTime(DateTime? value) {
  if (value == null) return '';
  final local = value.toLocal();
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '${local.month}/${local.day}/${local.year} $hour:$minute';
}

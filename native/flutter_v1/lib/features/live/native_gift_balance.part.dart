part of 'native_live_components.dart';

class _GiftFundingBalance extends StatelessWidget {
  const _GiftFundingBalance({
    required this.realCoins,
    required this.testCoins,
    required this.totalCoins,
  });

  final int realCoins;
  final int testCoins;
  final int totalCoins;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      key: const Key('gift-funding-balance'),
      spacing: 7,
      runSpacing: 7,
      alignment: WrapAlignment.end,
      children: [
        _FundingChip(
          key: const Key('gift-real-coin-balance'),
          label: 'Real',
          value: realCoins,
          icon: Icons.attach_money_rounded,
        ),
        _FundingChip(
          key: const Key('gift-test-coin-balance'),
          label: 'Test',
          value: testCoins,
          icon: Icons.science_outlined,
        ),
        _FundingChip(
          key: const Key('gift-total-coin-balance'),
          label: 'Total',
          value: totalCoins,
          icon: Icons.toll_rounded,
        ),
      ],
    );
  }
}

class _FundingChip extends StatelessWidget {
  const _FundingChip({
    required this.label,
    required this.value,
    required this.icon,
    super.key,
  });

  final String label;
  final int value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF21182A),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFF4B365B)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: const Color(0xFFCBA5EA)),
          const SizedBox(width: 4),
          Text(
            '$label $value',
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

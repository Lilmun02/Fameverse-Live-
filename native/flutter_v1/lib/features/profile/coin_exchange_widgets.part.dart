part of 'coin_exchange_screen.dart';

class _ExchangeHero extends StatelessWidget {
  const _ExchangeHero();

  @override
  Widget build(BuildContext context) {
    return const _ExchangeCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'KEEP THE FAME MOVING',
            style: TextStyle(
              color: Color(0xFFD09AFF),
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.3,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Turn earnings into Fame Coins',
            style: TextStyle(fontSize: 23, fontWeight: FontWeight.w900),
          ),
          SizedBox(height: 7),
          Text(
            'Use Available Creator Earnings to get spendable Fame Coins for gifting. Pending or payout-reserved earnings cannot be exchanged.',
            style: TextStyle(color: Color(0xFFBDB1C5), height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _Balance extends StatelessWidget {
  const _Balance({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return _ExchangeCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFFC580FF)),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: Color(0xFF9E92A4), fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _ExchangeCard extends StatelessWidget {
  const _ExchangeCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF151018),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF493154)),
      ),
      child: child,
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.item});

  final FvCoinExchangeItem item;

  @override
  Widget build(BuildContext context) {
    final when = item.createdAt?.toLocal();
    final stamp = when == null
        ? 'Completed'
        : '${when.month}/${when.day}/${when.year}';
    return _ExchangeCard(
      child: Row(
        children: [
          const Icon(Icons.swap_horiz_rounded, color: Color(0xFFCB8BFF)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_money(item.amountCents)} → ${item.coinsCredited} Fame Coins',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 3),
                Text(
                  stamp,
                  style: const TextStyle(
                    color: Color(0xFF968A9B),
                    fontSize: 11,
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

class _ConfirmRow extends StatelessWidget {
  const _ConfirmRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(label, style: const TextStyle(color: Color(0xFFB7ABBE))),
        ),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w900)),
      ],
    );
  }
}

String _money(int cents) => '\$${(cents / 100).toStringAsFixed(2)}';

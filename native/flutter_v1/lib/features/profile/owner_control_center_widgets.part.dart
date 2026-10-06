part of 'owner_control_center_build23.dart';

class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFB27A36)),
        gradient: const LinearGradient(
          colors: [Color(0xFF4A2B16), Color(0xFF25152C), Color(0xFF100B15)],
        ),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'OWNER MONEY CONTROL',
            style: TextStyle(
              color: Color(0xFFFFD38E),
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Revenue, reserve & payouts',
            style: TextStyle(fontSize: 25, fontWeight: FontWeight.w900),
          ),
          SizedBox(height: 7),
          Text(
            'Promo Fame Coins are test-only and have no cash value. Reward Reserve is real business money set aside for rewards. Cash-Backed Fame Coins use that reserve and can create real creator earnings.',
            style: TextStyle(color: Color(0xFFC8BBCB), height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _LiabilityCard extends StatelessWidget {
  const _LiabilityCard({
    required this.reserveCents,
    required this.cashBackedOutstandingCents,
    required this.creatorUnpaidCents,
  });

  final int reserveCents;
  final int cashBackedOutstandingCents;
  final int creatorUnpaidCents;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF704F32)),
        color: const Color(0xFF1B1514),
      ),
      child: Column(
        children: [
          _Line(label: 'Reward Reserve available', value: _money(reserveCents)),
          const SizedBox(height: 10),
          _Line(
            label: 'Unspent cash-backed coin value',
            value: _money(cashBackedOutstandingCents),
          ),
          const SizedBox(height: 10),
          _Line(
            label: 'Unpaid creator earnings',
            value: _money(creatorUnpaidCents),
          ),
          const SizedBox(height: 12),
          const Text(
            'Do not treat these protected buckets as owner profit. Payout requests may overlap unpaid creator earnings, so they are displayed separately rather than double-counted here.',
            style: TextStyle(
              color: Color(0xFFB6A9AC),
              fontSize: 11,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(label, style: const TextStyle(color: Color(0xFFB7AAB9))),
        ),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w900)),
      ],
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value, required this.icon});
  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF3E2E46)),
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
            style: const TextStyle(color: Color(0xFFA195A5), fontSize: 10),
          ),
        ],
      ),
    );
  }
}

class _Action extends StatelessWidget {
  const _Action({
    required super.key,
    required this.icon,
    required this.title,
    required this.body,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String body;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFF3B2B43)),
          color: const Color(0xFF151018),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFFC88BFF)),
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
                      fontSize: 11,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            FilledButton.tonal(onPressed: onTap, child: Text(label)),
          ],
        ),
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.icon, required this.title, required this.body});
  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF3A2B42)),
        color: const Color(0xFF151018),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFFC58AFA)),
          const SizedBox(width: 11),
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
                    fontSize: 11,
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
}

class _Section extends StatelessWidget {
  const _Section(this.value);
  final String value;

  @override
  Widget build(BuildContext context) {
    return Text(
      value,
      style: const TextStyle(
        color: Color(0xFF8D7F94),
        fontSize: 10,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.45,
      ),
    );
  }
}

String _money(int cents) => '\$${(cents / 100).toStringAsFixed(2)}';

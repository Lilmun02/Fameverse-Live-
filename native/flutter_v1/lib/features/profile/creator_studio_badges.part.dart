part of 'creator_studio_screen.dart';

class _BadgeTransferPreviewCard extends StatelessWidget {
  const _BadgeTransferPreviewCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('badge-transfer-preview-card'),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF4E3560)),
        color: const Color(0xFF15101B),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFF291B35),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.workspace_premium_outlined,
                  color: Color(0xFFD6A8FF),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bring your badge',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Future Fameverse badge transfer',
                      style: TextStyle(color: Color(0xFFAFA2B7), fontSize: 11),
                    ),
                  ],
                ),
              ),
              const DecoratedBox(
                decoration: BoxDecoration(
                  color: Color(0xFF31203E),
                  borderRadius: BorderRadius.all(Radius.circular(999)),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                  child: Text(
                    'COMING SOON',
                    style: TextStyle(
                      color: Color(0xFFD9B8F5),
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: .6,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              _BadgeSourceChip('TikTok'),
              _BadgeSourceChip('Favorited'),
              _BadgeSourceChip('EPIC'),
            ],
          ),
          const SizedBox(height: 13),
          const Text(
            'Transfer one eligible badge. Your screen recording must show the same account and badge you submit. Fameverse reviews every transfer before approval.',
            style: TextStyle(color: Color(0xFFC0B6C6), height: 1.4),
          ),
          const SizedBox(height: 10),
          const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.videocam_outlined, size: 18, color: Color(0xFFB784FF)),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Mismatch = denied. You can record a new video and try again. Only one transferred badge can be active.',
                  style: TextStyle(
                    color: Color(0xFF9F93A8),
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BadgeSourceChip extends StatelessWidget {
  const _BadgeSourceChip(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF24192D),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFF493456)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFFD8CDE0),
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _OwnerRechargeCard extends StatelessWidget {
  const _OwnerRechargeCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: const Key('owner-native-paypal-recharge'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.all(17),
          decoration: _panelDecoration(),
          child: const Row(
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: Color(0xFF342047),
                  borderRadius: BorderRadius.all(Radius.circular(14)),
                ),
                child: Padding(
                  padding: EdgeInsets.all(11),
                  child: Icon(
                    Icons.account_balance_wallet_rounded,
                    color: Color(0xFFC69BFF),
                    size: 22,
                  ),
                ),
              ),
              SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PayPal sandbox recharge',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Owner QA · native Fameverse checkout · no Vercel page',
                      style: TextStyle(color: Color(0xFF9F93A8), fontSize: 12),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: Color(0xFFBBAFC4)),
            ],
          ),
        ),
      ),
    );
  }
}

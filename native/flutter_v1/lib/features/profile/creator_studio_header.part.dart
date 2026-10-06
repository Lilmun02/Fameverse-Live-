part of 'creator_studio_screen.dart';

class _StudioHero extends StatelessWidget {
  const _StudioHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF5A3973)),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF482164), Color(0xFF21112D), Color(0xFF110B17)],
        ),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'FAMEVERSE CREATOR',
            style: TextStyle(
              color: Color(0xFFD6B7FF),
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
          SizedBox(height: 9),
          Text(
            'Build. Earn. Grow.',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
          ),
          SizedBox(height: 6),
          Text(
            'Manage creator earnings and payout setup without mixing internal tools into your public profile.',
            style: TextStyle(color: Color(0xFFC4B8CC), height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _ProLivePreviewCard extends StatelessWidget {
  const _ProLivePreviewCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('pro-live-preview-card'),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF7E46B8), width: 1.2),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF28133A), Color(0xFF17101F), Color(0xFF0E0A12)],
        ),
        boxShadow: const [BoxShadow(color: Color(0x332B0A45), blurRadius: 20)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Color(0xFFC176FF), Color(0xFF6530A5)],
                  ),
                ),
                child: const Icon(Icons.workspace_premium_rounded),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Fameverse Pro Live Achievements',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Future creator program · read-only preview',
                      style: TextStyle(color: Color(0xFFAFA2B7), fontSize: 11),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFF3A2050),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  '10% PREVIEW',
                  style: TextStyle(
                    color: Color(0xFFE0B7FF),
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .7,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Silver  •  Gold  •  Diamond',
            style: TextStyle(
              color: Color(0xFFEADAF4),
              fontWeight: FontWeight.w900,
              letterSpacing: .4,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Consistency in Live performance will matter. The rest stays a surprise for now.',
            style: TextStyle(color: Color(0xFFB9AEC1), height: 1.4),
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              alignment: Alignment.center,
              children: [
                ExcludeSemantics(
                  child: ImageFiltered(
                    imageFilter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      color: const Color(0xFF21152A),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Qualification targets and grace windows'),
                          SizedBox(height: 8),
                          Text('Status perks, progression and badge details'),
                          SizedBox(height: 8),
                          Text('Creator rewards and future Pro Live benefits'),
                        ],
                      ),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xE6191020),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: const Color(0xFF6D3C8E)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.lock_outline_rounded, size: 15),
                      SizedBox(width: 6),
                      Text(
                        '90% hidden until the feature is ready',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
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

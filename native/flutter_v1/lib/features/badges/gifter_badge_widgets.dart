import 'package:flutter/material.dart';

import 'gifter_badge_system.dart';

enum FvGifterBadgeSize { small, medium, large }

class FvGifterBadge extends StatelessWidget {
  const FvGifterBadge({
    required this.totalCoinsSent,
    this.size = FvGifterBadgeSize.medium,
    this.showLevel = true,
    super.key,
  });

  final int totalCoinsSent;
  final FvGifterBadgeSize size;
  final bool showLevel;

  @override
  Widget build(BuildContext context) {
    final badge = fvEarnedGifterBadge(totalCoinsSent);
    if (badge == null) return const SizedBox.shrink();

    final level = fvComputeGifterLevel(totalCoinsSent);
    final metrics = switch (size) {
      FvGifterBadgeSize.small => (10.0, 6.0, 14.0, 10.0),
      FvGifterBadgeSize.medium => (12.0, 8.0, 18.0, 11.0),
      FvGifterBadgeSize.large => (15.0, 10.0, 24.0, 12.0),
    };

    return Semantics(
      label: '${badge.label}, level $level',
      child: Container(
        key: Key('native-gifter-badge-${badge.id}'),
        padding: EdgeInsets.symmetric(
          horizontal: metrics.$2,
          vertical: metrics.$2 * .65,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          gradient: const LinearGradient(
            colors: [Color(0xFF4E2767), Color(0xFF24152E)],
          ),
          border: Border.all(color: const Color(0xFF9B61C4)),
          boxShadow: const [
            BoxShadow(color: Color(0x448E4DFF), blurRadius: 10),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(badge.icon, style: TextStyle(fontSize: metrics.$3)),
            SizedBox(width: metrics.$2 * .6),
            Text(
              badge.label,
              style: TextStyle(
                fontSize: metrics.$1,
                fontWeight: FontWeight.w900,
              ),
            ),
            if (showLevel) ...[
              SizedBox(width: metrics.$2 * .6),
              Text(
                'Lv. $level',
                style: TextStyle(
                  color: const Color(0xFFD3C4DB),
                  fontSize: metrics.$4,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class FvGifterProgressSection extends StatefulWidget {
  const FvGifterProgressSection({
    required this.totalCoinsSent,
    required this.giftCount,
    super.key,
  });

  final int totalCoinsSent;
  final int giftCount;

  @override
  State<FvGifterProgressSection> createState() =>
      _FvGifterProgressSectionState();
}

class _FvGifterProgressSectionState extends State<FvGifterProgressSection> {
  bool _showInfo = false;

  int _tierRequirement(FvGifterBadgeTier tier) {
    if (tier.minLevel == 1) return 1;
    return fvGifterLevelRequirement(tier.minLevel);
  }

  @override
  Widget build(BuildContext context) {
    final totalCoins = widget.totalCoinsSent < 0 ? 0 : widget.totalCoinsSent;
    final giftCount = widget.giftCount < 0 ? 0 : widget.giftCount;
    final progress = fvGifterProgress(totalCoins);
    final currentTier = fvGifterBadgeForLevel(progress.level);
    final hasEarnedBadge = totalCoins > 0;
    FvGifterBadgeTier? nextBadge;
    for (final tier in fvGifterBadgeTiers) {
      if (!hasEarnedBadge || tier.minLevel > progress.level) {
        nextBadge = tier;
        break;
      }
    }
    final nextRequirement =
        nextBadge == null ? null : _tierRequirement(nextBadge);
    final coinsToNextBadge =
        nextRequirement == null ? 0 : (nextRequirement - totalCoins).clamp(0, nextRequirement);

    return Container(
      key: const Key('native-gifter-progression-section'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF17101F),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF3D2B45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'GIFTER PROGRESSION',
                      style: TextStyle(
                        color: Color(0xFFB98CFF),
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      currentTier.label,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    const Text(
                      'Gift coins build your level. Levels unlock Fameverse gifter badges.',
                      style: TextStyle(
                        color: Color(0xFFAEA1B4),
                        fontSize: 11,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () => setState(() => _showInfo = !_showInfo),
                child: Text(_showInfo ? 'Hide info' : 'How it works'),
              ),
            ],
          ),
          if (_showInfo) ...[
            const SizedBox(height: 10),
            const Text(
              'Gifter progress is based only on gift coins sent. FameTaps do not increase gifter level. Unearned badge artwork stays locked until its requirement is reached.',
              style: TextStyle(
                color: Color(0xFFC6B8CC),
                fontSize: 11,
                height: 1.35,
              ),
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              if (hasEarnedBadge)
                FvGifterBadge(
                  totalCoinsSent: totalCoins,
                  size: FvGifterBadgeSize.large,
                  showLevel: false,
                )
              else
                const _LockedBadgePreview(),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Lv. ${progress.level}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: progress.progress,
                      minHeight: 7,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      progress.isMaxLevel
                          ? 'Max gifter level reached'
                          : '$totalCoins / ${progress.nextRequirement} coins · ${progress.coinsToNext} coins to Lv. ${progress.nextLevel}',
                      style: const TextStyle(
                        color: Color(0xFFAA9EAF),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _ProgressStat(
                  value: '$totalCoins',
                  label: 'Total gift coins sent',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ProgressStat(
                  value: '$giftCount',
                  label: 'Gifts sent',
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 112,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: fvGifterBadgeTiers.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final tier = fvGifterBadgeTiers[index];
                final requirement = _tierRequirement(tier);
                final earned =
                    hasEarnedBadge && progress.level >= tier.minLevel;
                final current =
                    earned &&
                    progress.level >= tier.minLevel &&
                    progress.level <= tier.maxLevel;
                return Container(
                  width: 132,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: current
                        ? const Color(0xFF352148)
                        : const Color(0xFF21182A),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: current
                          ? const Color(0xFFAD73FF)
                          : Colors.white10,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Opacity(
                        opacity: earned ? 1 : .4,
                        child: Text(
                          tier.icon,
                          style: const TextStyle(fontSize: 20),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        tier.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        tier.minLevel == tier.maxLevel
                            ? 'Lv. ${tier.minLevel}'
                            : 'Lv. ${tier.minLevel}–${tier.maxLevel}',
                        style: const TextStyle(
                          color: Color(0xFFB5A8BB),
                          fontSize: 9,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        earned
                            ? 'Unlocked'
                            : tier.minLevel == 1
                            ? 'Send your first gift'
                            : '$requirement coins',
                        style: const TextStyle(
                          color: Color(0xFF93869A),
                          fontSize: 8,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text(
                'NEXT BADGE',
                style: TextStyle(
                  color: Color(0xFF9F92A4),
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Spacer(),
              Flexible(
                child: Text(
                  nextBadge == null
                      ? 'Fame Icon earned'
                      : '${nextBadge.label} · $coinsToNextBadge coins remaining',
                  textAlign: TextAlign.end,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
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

class _LockedBadgePreview extends StatelessWidget {
  const _LockedBadgePreview();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 66,
      height: 66,
      decoration: BoxDecoration(
        color: const Color(0xFF21182A),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white10),
      ),
      child: const Center(
        child: Opacity(
          opacity: .4,
          child: Text('✦', style: TextStyle(fontSize: 30)),
        ),
      ),
    );
  }
}

class _ProgressStat extends StatelessWidget {
  const _ProgressStat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1F1725),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: const TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF9F92A4),
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }
}

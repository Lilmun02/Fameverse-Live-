part of 'native_live_rankings.dart';

class _RunnerSpotlight extends StatelessWidget {
  const _RunnerSpotlight({
    required this.entry,
    required this.scoreCopy,
    required this.secondaryCopy,
  });

  final _RankingEntry entry;
  final String scoreCopy;
  final String secondaryCopy;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF3C2B45)),
        color: const Color(0xFF161019),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _Avatar(
                entry: entry,
                radius: 23,
                border: const Color(0xFF6E557A),
              ),
              const Spacer(),
              Text(
                '#${entry.position}',
                style: const TextStyle(
                  color: Color(0xFFBA8BDA),
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            entry.displayName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 5),
          Text(
            scoreCopy,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800),
          ),
          Text(
            secondaryCopy,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Color(0xFF8E8294), fontSize: 9),
          ),
        ],
      ),
    );
  }
}

class _RankingRow extends StatelessWidget {
  const _RankingRow({
    required this.entry,
    required this.scoreCopy,
    required this.secondaryCopy,
  });

  final _RankingEntry entry;
  final String scoreCopy;
  final String secondaryCopy;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 7),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: const Color(0xFF141017),
        border: Border.all(color: const Color(0xFF2A202F)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 31,
            child: Text(
              '${entry.position}',
              style: const TextStyle(
                color: Color(0xFF9C8DA4),
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          _Avatar(entry: entry, radius: 18, border: const Color(0xFF44344D)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (entry.username?.isNotEmpty == true)
                  Text(
                    '@${entry.username}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF8F8395),
                      fontSize: 9,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                scoreCopy,
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                secondaryCopy,
                style: const TextStyle(color: Color(0xFF8C8092), fontSize: 8),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({
    required this.entry,
    required this.radius,
    required this.border,
  });

  final _RankingEntry entry;
  final double radius;
  final Color border;

  @override
  Widget build(BuildContext context) {
    final avatarUrl = entry.avatarUrl?.trim();
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: border),
      ),
      child: CircleAvatar(
        radius: radius,
        foregroundImage: avatarUrl != null && avatarUrl.isNotEmpty
            ? NetworkImage(avatarUrl)
            : null,
        child: Text(
          entry.displayName.trim().isEmpty
              ? 'F'
              : entry.displayName.trim()[0].toUpperCase(),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.waves_rounded, size: 34, color: Color(0xFF8F65AA)),
            SizedBox(height: 10),
            Text('No Fameboard activity in this window yet.'),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => unawaited(onRetry()),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

String _compact(int value) {
  if (value >= 1000000) {
    final scaled = value / 1000000;
    return '${scaled.toStringAsFixed(scaled >= 10 ? 0 : 1)}M';
  }
  if (value >= 1000) {
    final scaled = value / 1000;
    return '${scaled.toStringAsFixed(scaled >= 10 ? 0 : 1)}K';
  }
  return '$value';
}

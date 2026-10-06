part of 'native_live_rankings.dart';

class _RankingEntry {
  const _RankingEntry({
    required this.position,
    required this.userId,
    required this.username,
    required this.displayName,
    required this.avatarUrl,
    required this.score,
    required this.secondary,
  });

  final int position;
  final String userId;
  final String? username;
  final String displayName;
  final String? avatarUrl;
  final int score;
  final int secondary;
}

class _WindowButton extends StatelessWidget {
  const _WindowButton({
    required super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(11),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF6E35B4) : Colors.transparent,
          borderRadius: BorderRadius.circular(11),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            color: selected ? Colors.white : const Color(0xFF8F8297),
          ),
        ),
      ),
    );
  }
}

class _KindButton extends StatelessWidget {
  const _KindButton({
    required super.key,
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF261631) : const Color(0xFF151018),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? const Color(0xFFA65BEC) : const Color(0xFF302437),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: selected
                  ? const Color(0xFFD6A8FF)
                  : const Color(0xFF8E8294),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: selected ? Colors.white : const Color(0xFF978B9D),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FameboardBoard extends StatelessWidget {
  const _FameboardBoard({
    required this.rows,
    required this.scoreBuilder,
    required this.secondaryBuilder,
  });

  final List<_RankingEntry> rows;
  final String Function(_RankingEntry entry) scoreBuilder;
  final String Function(_RankingEntry entry) secondaryBuilder;

  @override
  Widget build(BuildContext context) {
    final first = rows.isNotEmpty ? rows[0] : null;
    final second = rows.length > 1 ? rows[1] : null;
    final third = rows.length > 2 ? rows[2] : null;
    final rest = rows.skip(3).toList(growable: false);

    return ListView(
      key: const Key('fameboard-list'),
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
      children: [
        if (first != null)
          _FirstSpotlight(
            entry: first,
            scoreCopy: scoreBuilder(first),
            secondaryCopy: secondaryBuilder(first),
          ),
        if (second != null || third != null) ...[
          const SizedBox(height: 9),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (second != null)
                Expanded(
                  child: _RunnerSpotlight(
                    entry: second,
                    scoreCopy: scoreBuilder(second),
                    secondaryCopy: secondaryBuilder(second),
                  ),
                ),
              if (second != null && third != null) const SizedBox(width: 9),
              if (third != null)
                Expanded(
                  child: _RunnerSpotlight(
                    entry: third,
                    scoreCopy: scoreBuilder(third),
                    secondaryCopy: secondaryBuilder(third),
                  ),
                ),
            ],
          ),
        ],
        if (rest.isNotEmpty) ...[
          const SizedBox(height: 22),
          const Text(
            'THE BOARD',
            style: TextStyle(
              color: Color(0xFF887B8F),
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 7),
          ...rest.map(
            (entry) => _RankingRow(
              entry: entry,
              scoreCopy: scoreBuilder(entry),
              secondaryCopy: secondaryBuilder(entry),
            ),
          ),
        ],
      ],
    );
  }
}

class _FirstSpotlight extends StatelessWidget {
  const _FirstSpotlight({
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
      key: const Key('fameboard-first-spotlight'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF8D4BD0)),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF39204B), Color(0xFF1B1023), Color(0xFF100B14)],
        ),
      ),
      child: Row(
        children: [
          _Avatar(entry: entry, radius: 34, border: const Color(0xFFC07DFF)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'FRONT OF THE WAVE · #1',
                  style: TextStyle(
                    color: Color(0xFFD2A0FF),
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  entry.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (entry.username?.isNotEmpty == true)
                  Text(
                    '@${entry.username}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFFA99DAE),
                      fontSize: 10,
                    ),
                  ),
                const SizedBox(height: 8),
                Text(
                  scoreCopy,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  secondaryCopy,
                  style: const TextStyle(
                    color: Color(0xFF9F92A5),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.auto_awesome_rounded, color: Color(0xFFC37FFF)),
        ],
      ),
    );
  }
}

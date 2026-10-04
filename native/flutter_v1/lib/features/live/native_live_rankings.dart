import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> showNativeLiveRankings(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const NativeLiveRankingsSheet(),
  );
}

class NativeLiveRankingsSheet extends StatefulWidget {
  const NativeLiveRankingsSheet({super.key});

  @override
  State<NativeLiveRankingsSheet> createState() =>
      _NativeLiveRankingsSheetState();
}

class _NativeLiveRankingsSheetState extends State<NativeLiveRankingsSheet> {
  static const _kinds = <(String, String)>[
    ('gifters', 'Gifters'),
    ('tappers', 'Tappers'),
    ('creators', 'Creators'),
  ];

  String _kind = 'gifters';
  bool _loading = true;
  String? _error;
  List<_RankingEntry> _rows = const [];

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final data = await Supabase.instance.client.rpc(
        'get_fameverse_rankings',
        params: <String, dynamic>{'p_kind': _kind, 'p_limit': 20},
      );
      final rows = (data as List? ?? const []).map((raw) {
        final row = Map<String, dynamic>.from(raw as Map);
        return _RankingEntry(
          position: (row['rank_position'] as num?)?.toInt() ?? 0,
          userId: row['user_id']?.toString() ?? '',
          username: row['username'] as String?,
          displayName: (row['display_name'] as String?) ?? 'Fameverse Creator',
          avatarUrl: row['avatar_url'] as String?,
          score: (row['score'] as num?)?.toInt() ?? 0,
          secondary: (row['secondary'] as num?)?.toInt() ?? 0,
        );
      }).toList();
      if (!mounted) return;
      setState(() {
        _rows = rows;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Rankings could not refresh right now.';
      });
    }
  }

  Future<void> _selectKind(String kind) async {
    if (kind == _kind || _loading) return;
    setState(() => _kind = kind);
    await _load();
  }

  String _scoreCopy(_RankingEntry entry) {
    return switch (_kind) {
      'gifters' => '${entry.score} coins',
      'tappers' => '${entry.score} taps',
      'creators' => '${entry.score} taps',
      _ => '${entry.score}',
    };
  }

  String _secondaryCopy(_RankingEntry entry) {
    return switch (_kind) {
      'gifters' => '${entry.secondary} gifts',
      'tappers' => 'Fame taps',
      'creators' => '${entry.secondary} followers',
      _ => '',
    };
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        key: const Key('native-live-rankings-sheet'),
        height: MediaQuery.sizeOf(context).height * .78,
        margin: const EdgeInsets.fromLTRB(8, 38, 8, 8),
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
        decoration: BoxDecoration(
          color: const Color(0xFF120C17),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: const Color(0xFF493353)),
          boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 28)],
        ),
        child: Column(
          children: [
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 12),
            const Row(
              children: [
                Icon(
                  Icons.emoji_events_rounded,
                  size: 20,
                  color: Color(0xFFFFC75A),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Live rankings',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: _kinds
                  .map(
                    (item) => Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: ChoiceChip(
                          key: Key('live-ranking-${item.$1}'),
                          label: SizedBox(
                            width: double.infinity,
                            child: Text(
                              item.$2,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 11),
                            ),
                          ),
                          selected: _kind == item.$1,
                          onSelected: (_) => unawaited(_selectKind(item.$1)),
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                  ? Center(
                      child: Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Color(0xFFB8ACBC)),
                      ),
                    )
                  : _rows.isEmpty
                  ? const Center(
                      child: Text(
                        'No ranking activity yet.',
                        style: TextStyle(color: Color(0xFFA99CAC)),
                      ),
                    )
                  : _RankingBoard(
                      rows: _rows,
                      scoreBuilder: _scoreCopy,
                      secondaryBuilder: _secondaryCopy,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

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

class _RankingBoard extends StatelessWidget {
  const _RankingBoard({
    required this.rows,
    required this.scoreBuilder,
    required this.secondaryBuilder,
  });

  final List<_RankingEntry> rows;
  final String Function(_RankingEntry entry) scoreBuilder;
  final String Function(_RankingEntry entry) secondaryBuilder;

  @override
  Widget build(BuildContext context) {
    final top = rows.take(3).toList(growable: false);
    final rest = rows.skip(3).toList(growable: false);
    final podium = <_RankingEntry>[];
    if (top.length > 1) podium.add(top[1]);
    if (top.isNotEmpty) podium.add(top[0]);
    if (top.length > 2) podium.add(top[2]);

    return Column(
      children: [
        if (podium.isNotEmpty)
          SizedBox(
            height: 158,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: podium
                  .map(
                    (entry) => Expanded(
                      child: _PodiumEntry(
                        entry: entry,
                        scoreCopy: scoreBuilder(entry),
                        secondaryCopy: secondaryBuilder(entry),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        if (rest.isNotEmpty) ...[
          const SizedBox(height: 6),
          const Divider(height: 1, color: Color(0xFF2E2234)),
          const SizedBox(height: 2),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.only(top: 2),
              itemCount: rest.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, color: Color(0xFF2E2234)),
              itemBuilder: (context, index) {
                final entry = rest[index];
                return _RankingRow(
                  entry: entry,
                  scoreCopy: scoreBuilder(entry),
                  secondaryCopy: secondaryBuilder(entry),
                );
              },
            ),
          ),
        ] else
          const Spacer(),
      ],
    );
  }
}

class _PodiumEntry extends StatelessWidget {
  const _PodiumEntry({
    required this.entry,
    required this.scoreCopy,
    required this.secondaryCopy,
  });

  final _RankingEntry entry;
  final String scoreCopy;
  final String secondaryCopy;

  @override
  Widget build(BuildContext context) {
    final isFirst = entry.position == 1;
    final avatarUrl = entry.avatarUrl?.trim();
    final badgeColor = switch (entry.position) {
      1 => const Color(0xFFFFC75A),
      2 => const Color(0xFFC7CBD4),
      3 => const Color(0xFFCF8B5D),
      _ => const Color(0xFF9A80B8),
    };

    return Padding(
      padding: EdgeInsets.fromLTRB(4, isFirst ? 0 : 18, 4, 0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            width: isFirst ? 66 : 56,
            height: isFirst ? 66 : 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: badgeColor, width: isFirst ? 3 : 2),
              boxShadow: [
                BoxShadow(
                  color: badgeColor.withValues(alpha: .25),
                  blurRadius: 18,
                ),
              ],
            ),
            child: CircleAvatar(
              foregroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                  ? NetworkImage(avatarUrl)
                  : null,
              child: Text(
                entry.displayName.trim().isEmpty
                    ? 'F'
                    : entry.displayName.trim()[0].toUpperCase(),
              ),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            '#${entry.position}',
            style: TextStyle(
              color: badgeColor,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            entry.displayName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 2),
          Text(
            scoreCopy,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFFE0D5E4),
              fontSize: 9,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            secondaryCopy,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF998DA0), fontSize: 8),
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
    final avatarUrl = entry.avatarUrl?.trim();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 30,
            child: Text(
              '#${entry.position}',
              style: const TextStyle(
                color: Color(0xFFA99CAE),
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          CircleAvatar(
            radius: 17,
            foregroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                ? NetworkImage(avatarUrl)
                : null,
            child: Text(
              entry.displayName.trim().isEmpty
                  ? 'F'
                  : entry.displayName.trim()[0].toUpperCase(),
            ),
          ),
          const SizedBox(width: 9),
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
                      color: Color(0xFF9F92A5),
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
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFFD4C7D9),
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                secondaryCopy,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Color(0xFF8F8395), fontSize: 8),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

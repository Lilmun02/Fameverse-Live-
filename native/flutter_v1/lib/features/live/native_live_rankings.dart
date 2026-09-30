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
          displayName:
              (row['display_name'] as String?) ?? 'Fameverse Creator',
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
      'gifters' => '${entry.score} coins · ${entry.secondary} gifts',
      'tappers' => '${entry.score} Fame taps',
      'creators' => '${entry.score} Fame taps · ${entry.secondary} followers',
      _ => '${entry.score}',
    };
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        key: const Key('native-live-rankings-sheet'),
        height: MediaQuery.sizeOf(context).height * .72,
        margin: const EdgeInsets.fromLTRB(8, 48, 8, 8),
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
        decoration: BoxDecoration(
          color: const Color(0xFF120C17),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: const Color(0xFF493353)),
          boxShadow: const [
            BoxShadow(color: Colors.black54, blurRadius: 28),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 14),
            const Row(
              children: [
                Icon(
                  Icons.emoji_events_rounded,
                  color: Color(0xFFFFC75A),
                ),
                SizedBox(width: 9),
                Expanded(
                  child: Text(
                    'Live Rankings',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
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
                            child: Text(item.$2, textAlign: TextAlign.center),
                          ),
                          selected: _kind == item.$1,
                          onSelected: (_) => unawaited(_selectKind(item.$1)),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 12),
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
                  : ListView.separated(
                      itemCount: _rows.length,
                      separatorBuilder: (_, __) =>
                          const Divider(height: 1, color: Color(0xFF2E2234)),
                      itemBuilder: (context, index) {
                        final entry = _rows[index];
                        return _RankingRow(
                          entry: entry,
                          scoreCopy: _scoreCopy(entry),
                        );
                      },
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

class _RankingRow extends StatelessWidget {
  const _RankingRow({required this.entry, required this.scoreCopy});

  final _RankingEntry entry;
  final String scoreCopy;

  @override
  Widget build(BuildContext context) {
    final avatarUrl = entry.avatarUrl?.trim();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          SizedBox(
            width: 34,
            child: Text(
              '#${entry.position}',
              style: TextStyle(
                color: entry.position <= 3
                    ? const Color(0xFFFFC75A)
                    : const Color(0xFFA99CAE),
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          CircleAvatar(
            radius: 20,
            foregroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                ? NetworkImage(avatarUrl)
                : null,
            child: Text(
              entry.displayName.trim().isEmpty
                  ? 'F'
                  : entry.displayName.trim()[0].toUpperCase(),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                if (entry.username?.isNotEmpty == true)
                  Text(
                    '@${entry.username}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF9F92A5),
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              scoreCopy,
              maxLines: 2,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFFD4C7D9),
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

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
  static const _windows = <(String, String)>[('24h', '24H'), ('7d', '7D')];
  static const _kinds = <(String, String, IconData)>[
    ('supporters', 'Supporters', Icons.card_giftcard_rounded),
    ('pulse', 'Pulse', Icons.bolt_rounded),
    ('creators', 'Creators', Icons.auto_awesome_rounded),
  ];

  String _window = '24h';
  String _kind = 'supporters';
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
        'get_fameverse_rankings_v2',
        params: <String, dynamic>{
          'p_kind': _kind,
          'p_window': _window,
          'p_limit': 50,
        },
      );
      final rows = (data as List? ?? const [])
          .map((raw) {
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
          })
          .toList(growable: false);
      if (!mounted) return;
      setState(() {
        _rows = rows;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Fameboard could not refresh right now.';
      });
    }
  }

  Future<void> _selectKind(String kind) async {
    if (kind == _kind || _loading) return;
    setState(() => _kind = kind);
    await _load();
  }

  Future<void> _selectWindow(String window) async {
    if (window == _window || _loading) return;
    setState(() => _window = window);
    await _load();
  }

  String _windowCopy() => _window == '24h'
      ? 'Momentum from the last 24 hours'
      : 'Momentum from the last 7 days';

  String _scoreCopy(_RankingEntry entry) {
    return switch (_kind) {
      'supporters' => '${_compact(entry.score)} coins sent',
      'pulse' => '${_compact(entry.score)} Fame taps',
      'creators' => '${_compact(entry.score)} live taps',
      _ => _compact(entry.score),
    };
  }

  String _secondaryCopy(_RankingEntry entry) {
    return switch (_kind) {
      'supporters' => '${_compact(entry.secondary)} gifts',
      'pulse' => '${_compact(entry.secondary)} total taps',
      'creators' => '+${_compact(entry.secondary)} followers',
      _ => '',
    };
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        key: const Key('native-live-rankings-sheet'),
        height: MediaQuery.sizeOf(context).height * .88,
        margin: const EdgeInsets.fromLTRB(8, 28, 8, 8),
        decoration: BoxDecoration(
          color: const Color(0xFF0D0911),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: const Color(0xFF3A2944)),
          boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 30)],
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          gradient: const LinearGradient(
                            colors: [Color(0xFFA853FF), Color(0xFF5A2BCD)],
                          ),
                        ),
                        child: const Icon(Icons.leaderboard_rounded),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Fameboard',
                              key: Key('fameboard-title'),
                              style: TextStyle(
                                fontSize: 23,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -.4,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'See who is moving Fameverse right now.',
                              style: TextStyle(
                                color: Color(0xFFA99DAE),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF17111C),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: const Color(0xFF2F2237)),
                    ),
                    child: Row(
                      children: _windows
                          .map(
                            (item) => Expanded(
                              child: _WindowButton(
                                key: Key('fameboard-window-${item.$1}'),
                                label: item.$2,
                                selected: _window == item.$1,
                                onTap: () => unawaited(_selectWindow(item.$1)),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 40,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _kinds.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final item = _kinds[index];
                        return _KindButton(
                          key: Key('fameboard-kind-${item.$1}'),
                          label: item.$2,
                          icon: item.$3,
                          selected: _kind == item.$1,
                          onTap: () => unawaited(_selectKind(item.$1)),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(
                        Icons.schedule_rounded,
                        size: 14,
                        color: Color(0xFF9D8FA4),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        _windowCopy(),
                        style: const TextStyle(
                          color: Color(0xFF9D8FA4),
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                  ? _ErrorState(message: _error!, onRetry: _load)
                  : _rows.isEmpty
                  ? const _EmptyState()
                  : _FameboardBoard(
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

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
part 'native_live_rankings_board.part.dart';
part 'native_live_rankings_rows.part.dart';


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

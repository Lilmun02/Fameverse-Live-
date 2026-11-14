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
  static const _windows = <(String, String)>[
    ('24h', 'Daily'),
    ('7d', 'Weekly'),
  ];
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
          'p_kind': _kin
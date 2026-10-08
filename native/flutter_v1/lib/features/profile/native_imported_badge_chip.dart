import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Verified badge recognition, never an indicator of local coin spending.
class NativeImportedBadgeChip extends StatefulWidget {
  const NativeImportedBadgeChip({required this.userId, super.key});

  final String userId;

  @override
  State<NativeImportedBadgeChip> createState() =>
      _NativeImportedBadgeChipState();
}

class _NativeImportedBadgeChipState extends State<NativeImportedBadgeChip> {
  late Future<Map<String, dynamic>?> _badge;

  @override
  void initState() {
    super.initState();
    _badge = _fetch();
  }

  @override
  void didUpdateWidget(covariant NativeImportedBadgeChip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId) _badge = _fetch();
  }

  Future<Map<String, dynamic>?> _fetch() async {
    try {
      final row = await Supabase.instance.client
          .from('badge_imports')
          .select('approved_level,source_platform')
          .eq('user_id', widget.userId)
          .maybeSingle();
      return row;
    } catch (_) {
      // Import table may not be deployed yet; profiles must stay usable.
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _badge,
      builder: (context, snapshot) {
        final row = snapshot.data;
        final level = (row?['approved_level'] as num?)?.toInt() ?? 0;
        if (level < 1) return const SizedBox.shrink();
        final source = (row?['source_platform'] as String? ?? 'source')
            .toUpperCase();
        return Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Center(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xFF281630),
                border: Border.all(color: const Color(0xFFC18AF2)),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 13,
                  vertical: 7,
                ),
                child: Text(
                  'Verified transferred badge · Lv. $level · $source',
                  key: const Key('native-imported-gifter-badge'),
                  style: const TextStyle(
                    color: Color(0xFFF1D7FF),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

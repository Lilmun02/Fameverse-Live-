import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/fameverse_gifter_backend.dart';
import 'gifter_badge_system.dart';
import 'gifter_badge_widgets.dart';

class FvGifterProfileSection extends StatefulWidget {
  const FvGifterProfileSection({
    required this.userId,
    this.backend,
    super.key,
  });

  final String userId;
  final FameverseGifterBackend? backend;

  @override
  State<FvGifterProfileSection> createState() => _FvGifterProfileSectionState();
}

class _FvGifterProfileSectionState extends State<FvGifterProfileSection> {
  late final FameverseGifterBackend _backend;
  bool _loading = true;
  FvGifterAccountStats _stats = FvGifterAccountStats.empty;

  @override
  void initState() {
    super.initState();
    _backend =
        widget.backend ??
        SupabaseFameverseGifterBackend(Supabase.instance.client);
    unawaited(_load());
  }

  Future<void> _load() async {
    try {
      final stats = await _backend.loadAccountStats(widget.userId);
      if (!mounted) return;
      setState(() {
        _stats = stats;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: SizedBox.square(
            dimension: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    final privileged = fvIsPrivilegedIdentityRole(_stats.accountRole);
    return Column(
      children: [
        if (_stats.totalCoinsSent > 0 && !privileged) ...[
          FvGifterBadge(
            totalCoinsSent: _stats.totalCoinsSent,
            size: FvGifterBadgeSize.small,
          ),
          const SizedBox(height: 14),
        ],
        FvGifterProgressSection(
          totalCoinsSent: _stats.totalCoinsSent,
          giftCount: _stats.giftCount,
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Displays owner-awarded, non-monetary profile recognition.
class ProfileRecognitionBadges extends StatefulWidget {
  const ProfileRecognitionBadges({required this.userId, super.key});

  final String userId;

  @override
  State<ProfileRecognitionBadges> createState() =>
      _ProfileRecognitionBadgesState();
}

class _ProfileRecognitionBadgesState extends State<ProfileRecognitionBadges> {
  List<String> _awards = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant ProfileRecognitionBadges oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId) {
      _awards = const [];
      _load();
    }
  }

  Future<void> _load() async {
    final requestedId = widget.userId;
    try {
      final rows = await Supabase.instance.client
          .from('profile_recognition_awards')
          .select('award_code')
          .eq('user_id', requestedId);
      if (!mounted || widget.userId != requestedId) return;
      setState(() {
        _awards = rows
            .map((row) => row['award_code']?.toString() ?? '')
            .where((code) => code == 'verse_pioneer')
            .toList();
      });
    } catch (_) {
      // Recognition must never block loading a profile.
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_awards.contains('verse_pioneer')) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Center(
        child: Tooltip(
          message: 'Verse Pioneer — awarded for early Fameverse support',
          child: Container(
            key: const Key('verse-pioneer-profile-badge'),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF2A1739),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFC98DFF)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.workspace_premium_rounded,
                    size: 16, color: Color(0xFFFFD58F)),
                SizedBox(width: 6),
                Text('VERSE PIONEER',
                    style: TextStyle(
                      color: Color(0xFFE3B8FF),
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    )),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

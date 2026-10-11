import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Displays owner-awarded, non-monetary profile recognition.
class ProfileRecognitionBadges extends StatefulWidget {
  const ProfileRecognitionBadges({
    required this.userId,
    this.awardLoader,
    super.key,
  });

  final String userId;
  final Future<List<String>> Function(String userId)? awardLoader;

  @override
  State<ProfileRecognitionBadges> createState() =>
      _ProfileRecognitionBadgesState();
}

class _ProfileRecognitionBadgesState extends State<ProfileRecognitionBadges> {
  List<String> _awards = const [];
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant ProfileRecognitionBadges oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId ||
        oldWidget.awardLoader != widget.awardLoader) {
      _awards = const [];
      _loadError = null;
      _load();
    }
  }

  Future<void> _load() async {
    final requestedId = widget.userId;
    try {
      final codes = widget.awardLoader != null
          ? await widget.awardLoader!(requestedId)
          : (await Supabase.instance.client
                .from('profile_recognition_awards')
                .select('award_code')
                .eq('user_id', requestedId))
                .map((row) => row['award_code']?.toString() ?? '')
                .toList();
      if (!mounted || widget.userId != requestedId) return;
      setState(() {
        _loadError = null;
        _awards = codes.where((code) => code == 'verse_pioneer').toList();
      });
    } catch (error) {
      // Keep the profile usable while making a failed badge request visible to QA.
      if (!mounted || widget.userId != requestedId) return;
      setState(() => _loadError = 'Recognition badge unavailable. Pull to refresh.');
      debugPrint('Fameverse recognition badge fetch failed: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_awards.contains('verse_pioneer')) {
      if (_loadError == null) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text(
          _loadError!,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Color(0xFFC98DFF), fontSize: 11),
        ),
      );
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
                Icon(
                  Icons.workspace_premium_rounded,
                  size: 16,
                  color: Color(0xFFFFD58F),
                ),
                SizedBox(width: 6),
                Text(
                  'VERSE PIONEER',
                  style: TextStyle(
                    color: Color(0xFFE3B8FF),
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

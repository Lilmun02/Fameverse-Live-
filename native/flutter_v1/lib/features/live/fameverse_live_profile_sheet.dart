import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/fameverse_backend.dart';
import '../profile/fameverse_public_profile_screen.dart';

class FameverseLiveProfileSummary {
  const FameverseLiveProfileSummary({
    required this.profile,
    required this.followers,
    required this.following,
    required this.friends,
    required this.fameTaps,
    required this.totalCoinsSent,
    required this.giftCount,
    required this.gifterLevel,
    required this.viewerFollows,
    required this.targetFollowsViewer,
  });

  final FvProfile profile;
  final int followers;
  final int following;
  final int friends;
  final int fameTaps;
  final int totalCoinsSent;
  final int giftCount;
  final int gifterLevel;
  final bool viewerFollows;
  final bool targetFollowsViewer;

  factory FameverseLiveProfileSummary.fromMap(Map<String, dynamic> row) {
    return FameverseLiveProfileSummary(
      profile: FvProfile(
        id: row['user_id'].toString(),
        username: row['username']?.toString(),
        displayName: row['display_name']?.toString() ?? 'Fameverse User',
        bio: row['bio']?.toString() ?? '',
        avatarUrl: row['avatar_url']?.toString(),
        createdAt: null,
      ),
      followers: (row['followers_count'] as num?)?.toInt() ?? 0,
      following: (row['following_count'] as num?)?.toInt() ?? 0,
      friends: (row['friends_count'] as num?)?.toInt() ?? 0,
      fameTaps: (row['fame_taps'] as num?)?.toInt() ?? 0,
      totalCoinsSent: (row['total_coins_sent'] as num?)?.toInt() ?? 0,
      giftCount: (row['gift_count'] as num?)?.toInt() ?? 0,
      gifterLevel: (row['gifter_level'] as num?)?.toInt() ?? 1,
      viewerFollows: row['viewer_follows'] as bool? ?? false,
      targetFollowsViewer: row['target_follows_viewer'] as bool? ?? false,
    );
  }
}

Future<void> showFameverseLiveProfileSheet(
  BuildContext context, {
  required String viewerUserId,
  required String targetUserId,
  FvProfile? fallbackProfile,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (context) => FameverseLiveProfileSheet(
      viewerUserId: viewerUserId,
      targetUserId: targetUserId,
      fallbackProfile: fallbackProfile,
    ),
  );
}

class FameverseLiveProfileSheet extends StatefulWidget {
  const FameverseLiveProfileSheet({
    required this.viewerUserId,
    required this.targetUserId,
    this.fallbackProfile,
    super.key,
  });

  final String viewerUserId;
  final String targetUserId;
  final FvProfile? fallbackProfile;

  @override
  State<FameverseLiveProfileSheet> createState() =>
      _FameverseLiveProfileSheetState();
}

class _FameverseLiveProfileSheetState extends State<FameverseLiveProfileSheet> {
  late final FameverseBackend _backend = SupabaseFameverseBackend(
    Supabase.instance.client,
  );

  FameverseLiveProfileSummary? _summary;
  bool _loading = true;
  bool _followBusy = false;
  String? _error;

  bool get _isSelf => widget.viewerUserId == widget.targetUserId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final raw = await Supabase.instance.client.rpc(
        'get_live_profile_sheet_summary',
        params: <String, dynamic>{'p_target_user_id': widget.targetUserId},
      );
      final rows = (raw as List? ?? const []);
      if (!mounted) return;
      if (rows.isEmpty) {
        setState(() {
          _loading = false;
          _error = 'This Fameverse profile is unavailable.';
        });
        return;
      }
      setState(() {
        _summary = FameverseLiveProfileSummary.fromMap(
          Map<String, dynamic>.from(rows.first as Map),
        );
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Profile stats could not load right now.';
      });
    }
  }

  Future<void> _toggleFollow() async {
    final summary = _summary;
    if (_isSelf || summary == null || _followBusy) return;
    final next = !summary.viewerFollows;
    setState(() => _followBusy = true);
    try {
      await _backend.setFollowing(
        userId: widget.viewerUserId,
        targetId: widget.targetUserId,
        following: next,
      );
      await _load();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Could not update that connection.')),
        );
    } finally {
      if (mounted) setState(() => _followBusy = false);
    }
  }

  Future<void> _openFullProfile() async {
    final profile = _summary?.profile ?? widget.fallbackProfile;
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (context) => FameversePublicProfileScreen(
          viewerUserId: widget.viewerUserId,
          targetUserId: widget.targetUserId,
          initialProfile: profile,
        ),
      ),
    );
    if (mounted) await _load();
  }

  String _followLabel(FameverseLiveProfileSummary summary) {
    if (_isSelf) return 'Your profile';
    if (summary.viewerFollows && summary.targetFollowsViewer) return 'Friends';
    if (summary.viewerFollows) return 'Following';
    if (summary.targetFollowsViewer) return 'Follow back';
    return 'Follow';
  }

  String _compact(int value) {
    if (value >= 1000000) {
      final text = (value / 1000000).toStringAsFixed(value >= 10000000 ? 0 : 1);
      return '${text.replaceAll('.0', '')}M';
    }
    if (value >= 1000) {
      final text = (value / 1000).toStringAsFixed(value >= 10000 ? 0 : 1);
      return '${text.replaceAll('.0', '')}K';
    }
    return '$value';
  }

  @override
  Widget build(BuildContext context) {
    final summary = _summary;
    final profile = summary?.profile ?? widget.fallbackProfile;
    final maxHeight = MediaQuery.sizeOf(context).height * .86;

    return Container(
      key: const Key('live-profile-sheet'),
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: const BoxDecoration(
        color: Color(0xFF0C0910),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(top: BorderSide(color: Color(0xFF4A3156))),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
        child: Column(
          children: [
            Container(
              width: 46,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 18),
            if (profile != null) ...[
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFA95AFF),
                        width: 2.5,
                      ),
                      boxShadow: const [
                        BoxShadow(color: Color(0x665A1B86), blurRadius: 22),
                      ],
                    ),
                    child: _ProfileAvatar(profile: profile, radius: 48),
                  ),
                  if (summary != null)
                    Positioned(
                      right: -8,
                      bottom: 1,
                      child: Container(
                        key: const Key('live-profile-gifter-level'),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6E34B7),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: const Color(0xFFC17BFF)),
                        ),
                        child: Text(
                          'Lv. ${summary.gifterLevel}',
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 13),
              Text(
                profile.displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                profile.handle,
                style: const TextStyle(
                  color: Color(0xFFA99EAD),
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (profile.bio.trim().isNotEmpty) ...[
                const SizedBox(height: 11),
                Text(
                  profile.bio.trim(),
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFE0D7E4),
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ],
            if (_loading) ...[
              const SizedBox(height: 20),
              const CircularProgressIndicator(),
            ],
            if (_error != null) ...[
              const SizedBox(height: 18),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFFB6A8BC)),
              ),
            ],
            if (summary != null) ...[
              const SizedBox(height: 22),
              Container(
                key: const Key('live-profile-social-stats'),
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFF151018),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFF34253D)),
                ),
                child: Row(
                  children: [
                    _SheetStat(
                      label: 'Followers',
                      value: _compact(summary.followers),
                    ),
                    const _SheetDivider(),
                    _SheetStat(
                      label: 'Following',
                      value: _compact(summary.following),
                    ),
                    const _SheetDivider(),
                    _SheetStat(
                      label: 'Friends',
                      value: _compact(summary.friends),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _MetricTile(
                      icon: const _SheetFameTapMark(size: 20),
                      value: _compact(summary.fameTaps),
                      label: 'FameTaps',
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: _MetricTile(
                      icon: const Icon(
                        Icons.card_giftcard_rounded,
                        size: 20,
                        color: Color(0xFFFFCB67),
                      ),
                      value: _compact(summary.giftCount),
                      label: 'Gifts sent',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 7),
              Text(
                '${_compact(summary.totalCoinsSent)} Fame Coins sent in gifts',
                key: const Key('live-profile-gift-coins-sent'),
                style: const TextStyle(
                  color: Color(0xFF9B8FA0),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 15),
              if (_isSelf)
                OutlinedButton(
                  key: const Key('live-profile-self-button'),
                  onPressed: _openFullProfile,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                  ),
                  child: const Text('View full profile'),
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: FilledButton(
                        key: const Key('live-profile-follow-button'),
                        onPressed: _followBusy ? null : _toggleFollow,
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(50),
                          backgroundColor: summary.viewerFollows
                              ? const Color(0xFF24192A)
                              : const Color(0xFF7B3CC3),
                          side: BorderSide(
                            color: summary.viewerFollows
                                ? const Color(0xFF4A3654)
                                : const Color(0xFFB96EFF),
                          ),
                        ),
                        child: Text(
                          _followBusy ? 'Updating…' : _followLabel(summary),
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                    ),
                    const SizedBox(width: 9),
                    IconButton.outlined(
                      key: const Key('live-profile-open-full'),
                      onPressed: _openFullProfile,
                      tooltip: 'Full profile',
                      style: IconButton.styleFrom(
                        minimumSize: const Size(50, 50),
                      ),
                      icon: const Icon(Icons.open_in_new_rounded),
                    ),
                  ],
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({required this.profile, required this.radius});

  final FvProfile profile;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final avatar = profile.avatarUrl?.trim();
    return CircleAvatar(
      radius: radius,
      backgroundColor: const Color(0xFF2B1838),
      foregroundImage: avatar == null || avatar.isEmpty
          ? null
          : NetworkImage(avatar),
      child: Text(
        profile.initial,
        style: const TextStyle(fontWeight: FontWeight.w900),
      ),
    );
  }
}

class _SheetFameTapMark extends StatelessWidget {
  const _SheetFameTapMark({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            Icons.local_fire_department_rounded,
            size: size,
            color: const Color(0xFF9B55FF),
          ),
          Positioned(
            bottom: size * .15,
            child: Text(
              'F',
              style: TextStyle(
                color: const Color(0xFFE1B5FF),
                fontSize: size * .42,
                height: 1,
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SheetStat extends StatelessWidget {
  const _SheetStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: const TextStyle(color: Color(0xFF998E9D), fontSize: 10),
          ),
        ],
      ),
    );
  }
}

class _SheetDivider extends StatelessWidget {
  const _SheetDivider();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 1,
      height: 34,
      child: ColoredBox(color: Color(0xFF33283A)),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.icon,
    required this.value,
    required this.label,
  });

  final Widget icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFF151018),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: const Color(0xFF34253D)),
      ),
      child: Row(
        children: [
          icon,
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF998E9D),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

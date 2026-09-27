import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/fameverse_backend.dart';

class FameversePublicProfileScreen extends StatefulWidget {
  const FameversePublicProfileScreen({
    required this.viewerUserId,
    required this.targetUserId,
    this.initialProfile,
    super.key,
  });

  final String viewerUserId;
  final String targetUserId;
  final FvProfile? initialProfile;

  @override
  State<FameversePublicProfileScreen> createState() =>
      _FameversePublicProfileScreenState();
}

class _FameversePublicProfileScreenState
    extends State<FameversePublicProfileScreen> {
  late final FameverseBackend _backend =
      SupabaseFameverseBackend(Supabase.instance.client);

  FvProfile? _profile;
  FvFollowNetwork? _network;
  bool _following = false;
  bool _loading = true;
  bool _followBusy = false;
  String? _error;

  bool get _isSelf => widget.viewerUserId == widget.targetUserId;

  int get _friendCount {
    final network = _network;
    if (network == null) return 0;
    return network.followingIds.intersection(network.followerIds).length;
  }

  String get _publicBio {
    final value = _profile?.bio.trim() ?? '';
    final normalized = value.toLowerCase();
    if (normalized == 'admin - owner' || normalized == 'admin-owner') return '';
    return value;
  }

  @override
  void initState() {
    super.initState();
    _profile = widget.initialProfile;
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
      final results = await Future.wait<dynamic>([
        _backend.loadProfile(widget.targetUserId),
        _backend.loadFollowNetwork(widget.targetUserId),
        if (!_isSelf) _backend.loadFollowNetwork(widget.viewerUserId),
      ]);
      if (!mounted) return;
      final targetProfile = results[0] as FvProfile?;
      final targetNetwork = results[1] as FvFollowNetwork;
      final viewerNetwork = _isSelf
          ? targetNetwork
          : results[2] as FvFollowNetwork;
      setState(() {
        _profile = targetProfile ?? _profile;
        _network = targetNetwork;
        _following = viewerNetwork.followingIds.contains(widget.targetUserId);
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Fameverse could not load this profile right now.';
      });
    }
  }

  Future<void> _toggleFollow() async {
    if (_isSelf || _followBusy) return;
    setState(() => _followBusy = true);
    final next = !_following;
    try {
      await _backend.setFollowing(
        userId: widget.viewerUserId,
        targetId: widget.targetUserId,
        following: next,
      );
      final targetNetwork = await _backend.loadFollowNetwork(widget.targetUserId);
      if (!mounted) return;
      setState(() {
        _following = next;
        _network = targetNetwork;
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Could not update that connection.')));
    } finally {
      if (mounted) setState(() => _followBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = _profile;
    return Scaffold(
      key: const Key('fameverse-public-profile-screen'),
      backgroundColor: const Color(0xFF09070B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF09070B),
        title: const Text(
          'Profile',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 36),
          children: [
            if (profile == null && _loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 100),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (profile == null)
              _PublicProfileMessage(
                icon: Icons.person_off_outlined,
                title: 'Profile unavailable',
                body: _error ?? 'This profile could not be loaded.',
              )
            else ...[
              const Center(
                child: Text(
                  'FAMEVERSE',
                  style: TextStyle(
                    color: Color(0xFFC781FF),
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.1,
                  ),
                ),
              ),
              const SizedBox(height: 22),
              Center(child: _PublicAvatar(profile: profile)),
              const SizedBox(height: 16),
              Text(
                profile.displayName,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -.4,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                profile.handle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFFA99DAC),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (_publicBio.isNotEmpty) ...[
                const SizedBox(height: 13),
                Text(
                  _publicBio,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFFE0D6E3),
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              _PublicConnectionStats(
                followers: _network?.followers.length,
                following: _network?.following.length,
                friends: _network == null ? null : _friendCount,
              ),
              const SizedBox(height: 20),
              if (_isSelf)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF171019),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF3D2A48)),
                  ),
                  child: const Text(
                    'This is your profile',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                )
              else
                FilledButton(
                  key: const Key('public-profile-follow-button'),
                  onPressed: _followBusy ? null : _toggleFollow,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                    backgroundColor: _following
                        ? const Color(0xFF211827)
                        : const Color(0xFF7B3BC3),
                    foregroundColor: Colors.white,
                    side: BorderSide(
                      color: _following
                          ? const Color(0xFF4A3655)
                          : const Color(0xFFB56CFF),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    _followBusy
                        ? 'Updating…'
                        : _following
                        ? 'Following'
                        : 'Follow',
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              if (_loading && profile != null) ...[
                const SizedBox(height: 18),
                const Center(
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ],
              if (_error != null && profile != null) ...[
                const SizedBox(height: 18),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFFB7AABB), fontSize: 12),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _PublicAvatar extends StatelessWidget {
  const _PublicAvatar({required this.profile});

  final FvProfile profile;

  @override
  Widget build(BuildContext context) {
    final avatar = profile.avatarUrl?.trim();
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFA84EFF), width: 2),
        boxShadow: const [
          BoxShadow(color: Color(0x665D1D8E), blurRadius: 24),
        ],
      ),
      child: CircleAvatar(
        radius: 54,
        backgroundColor: const Color(0xFF291934),
        foregroundImage: avatar == null || avatar.isEmpty
            ? null
            : NetworkImage(avatar),
        child: Text(
          profile.initial,
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
        ),
      ),
    );
  }
}

class _PublicConnectionStats extends StatelessWidget {
  const _PublicConnectionStats({
    required this.followers,
    required this.following,
    required this.friends,
  });

  final int? followers;
  final int? following;
  final int? friends;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF141016),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF33243C)),
      ),
      child: Row(
        children: [
          _PublicStat(label: 'Followers', value: followers),
          const _PublicDivider(),
          _PublicStat(label: 'Following', value: following),
          const _PublicDivider(),
          _PublicStat(label: 'Friends', value: friends),
        ],
      ),
    );
  }
}

class _PublicStat extends StatelessWidget {
  const _PublicStat({required this.label, required this.value});

  final String label;
  final int? value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value == null ? '—' : '$value',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: const TextStyle(color: Color(0xFF9E92A2), fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _PublicDivider extends StatelessWidget {
  const _PublicDivider();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 1,
      height: 32,
      child: ColoredBox(color: Color(0xFF32263A)),
    );
  }
}

class _PublicProfileMessage extends StatelessWidget {
  const _PublicProfileMessage({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 80),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF151018),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Icon(icon, size: 34, color: const Color(0xFFC27EFF)),
          const SizedBox(height: 10),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 5),
          Text(
            body,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFFA99DAD), height: 1.35),
          ),
        ],
      ),
    );
  }
}

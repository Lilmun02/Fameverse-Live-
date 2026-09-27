import 'dart:async';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/fameverse_backend.dart';
import '../../data/fameverse_beta_backend.dart';
import '../../data/fameverse_creator_backend.dart';
import '../../data/fameverse_economy_backend.dart';
import '../../data/fameverse_live_backend.dart';
import '../../data/fameverse_story_backend.dart';
import '../live/livekit_live_screen.dart';
import '../live/native_camera_screen.dart';
import '../profile/coin_exchange_screen.dart';
import '../profile/creator_studio_screen.dart';
import '../profile/fameverse_edit_profile_screen.dart';
import '../profile/fameverse_policy_screen.dart';
import '../profile/fameverse_public_profile_screen.dart';
import '../profile/first_verse_beta_screen.dart';
import '../profile/native_profile_screen.dart';
import '../profile/owner_control_panel.dart';
import '../stories/creator_stories_screen.dart';
import 'fameverse_discover_screen.dart';
import 'fameverse_home_screen.dart';

class FameverseBuild16Shell extends StatefulWidget {
  const FameverseBuild16Shell({
    required this.backend,
    required this.liveBackend,
    required this.identity,
    super.key,
  });

  final FameverseBackend backend;
  final FameverseLiveBackend liveBackend;
  final FvIdentity identity;

  @override
  State<FameverseBuild16Shell> createState() => _FameverseBuild16ShellState();
}

class _FameverseBuild16ShellState extends State<FameverseBuild16Shell> {
  static const _emptyNetwork = FvFollowNetwork(
    followers: [],
    following: [],
    followerIds: {},
    followingIds: {},
  );

  SupabaseFameverseBetaBackend? _betaBackend;
  SupabaseFameverseCreatorBackend? _creatorBackend;
  SupabaseFameverseEconomyBackend? _economyBackend;

  int _tab = 0;
  bool _loading = true;
  bool _followBusy = false;
  bool _avatarBusy = false;
  String? _error;
  String? _accountRole;
  FvProfile? _profile;
  FvFollowNetwork _network = _emptyNetwork;
  List<FvCreator> _creators = const [];
  List<FvLiveRoom> _rooms = const [];
  FvBetaProgramStatus _betaStatus = FvBetaProgramStatus.notEnrolled;

  bool get _isPrivileged => _accountRole == 'owner' || _accountRole == 'admin';

  bool get _testerLimited =>
      _betaStatus.enrolled && !_betaStatus.badgeUnlocked && !_isPrivileged;

  bool get _hasFullAppAccess => !_testerLimited;

  @override
  void initState() {
    super.initState();
    unawaited(_refreshAll());
    unawaited(_refreshBeta());
  }

  SupabaseFameverseBetaBackend _getBetaBackend() =>
      _betaBackend ??= SupabaseFameverseBetaBackend(Supabase.instance.client);

  SupabaseFameverseCreatorBackend _getCreatorBackend() => _creatorBackend ??=
      SupabaseFameverseCreatorBackend(Supabase.instance.client);

  SupabaseFameverseEconomyBackend _getEconomyBackend() => _economyBackend ??=
      SupabaseFameverseEconomyBackend(Supabase.instance.client);

  Future<void> _refreshBeta() async {
    try {
      final backend = _getBetaBackend();
      final status = await backend.loadProgramStatus();
      if (!mounted) return;
      setState(() => _betaStatus = status);
      if (status.enrolled && _tab == 0) {
        await _recordBetaMission('browse_home');
      }
    } catch (_) {
      // Beta infrastructure never blocks ordinary Fameverse use.
    }
  }

  Future<void> _recordBetaMission(String missionKey) async {
    if (!_betaStatus.enrolled) return;
    try {
      final backend = _getBetaBackend();
      await backend.recordMission(missionKey);
      final status = await backend.loadProgramStatus();
      if (mounted) setState(() => _betaStatus = status);
    } catch (_) {
      // Mission telemetry is best effort and cannot break the tested feature.
    }
  }

  Future<void> _refreshAll() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final results = await Future.wait<dynamic>([
        widget.backend.loadProfile(widget.identity.id),
        widget.backend.loadFollowNetwork(widget.identity.id),
        widget.backend.listRecommendedCreators(
          excludeUserId: widget.identity.id,
        ),
        widget.backend.listActiveLiveRooms(excludeUserId: widget.identity.id),
        widget.backend.loadAccountRole(widget.identity.id),
      ]);
      if (!mounted) return;
      setState(() {
        _profile = results[0] as FvProfile?;
        _network = results[1] as FvFollowNetwork;
        _creators = results[2] as List<FvCreator>;
        _rooms = results[3] as List<FvLiveRoom>;
        _accountRole = results[4] as String?;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Fameverse could not refresh right now.';
      });
    }
  }

  Future<void> _toggleFollow(String targetId) async {
    if (_followBusy) return;
    setState(() => _followBusy = true);
    try {
      final following = _network.followingIds.contains(targetId);
      await widget.backend.setFollowing(
        userId: widget.identity.id,
        targetId: targetId,
        following: !following,
      );
      final network = await widget.backend.loadFollowNetwork(
        widget.identity.id,
      );
      if (mounted) setState(() => _network = network);
      await _recordBetaMission('follow_creator');
    } catch (_) {
      _message('Could not update that connection.');
    } finally {
      if (mounted) setState(() => _followBusy = false);
    }
  }

  Future<void> _saveProfile({
    required String displayName,
    required String username,
    required String bio,
  }) async {
    try {
      final profile = await widget.backend.saveProfile(
        userId: widget.identity.id,
        displayName: displayName,
        username: username,
        bio: bio,
      );
      if (!mounted) return;
      setState(() => _profile = profile);
      Navigator.of(context).pop();
      _message('Profile saved');
      await _recordBetaMission('complete_profile');
    } catch (error) {
      final text = error.toString();
      _message(
        text.contains('23505')
            ? 'That username is already taken'
            : text.contains('at least 3')
            ? 'Username must be at least 3 characters'
            : 'Could not save profile',
      );
    }
  }

  String _avatarExtension(String name) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.png')) return 'png';
    if (lower.endsWith('.webp')) return 'webp';
    return 'jpg';
  }

  String _avatarContentType(String extension) => switch (extension) {
    'png' => 'image/png',
    'webp' => 'image/webp',
    _ => 'image/jpeg',
  };

  Future<void> _pickProfilePhoto() async {
    if (_avatarBusy) return;
    setState(() => _avatarBusy = true);
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
        maxWidth: 1600,
      );
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      final extension = _avatarExtension(picked.name);
      final profile = await widget.backend.uploadProfileAvatar(
        userId: widget.identity.id,
        bytes: bytes,
        extension: extension,
        contentType: _avatarContentType(extension),
      );
      if (!mounted) return;
      setState(() => _profile = profile);
      _message('Profile photo updated');
      await _recordBetaMission('complete_profile');
    } catch (_) {
      _message('Could not update profile photo.');
    } finally {
      if (mounted) setState(() => _avatarBusy = false);
    }
  }

  void _message(String value) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(value)));
  }

  void _openPolicies() {
    Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (context) => const FameversePolicyScreen()),
    );
  }

  void _openEdit(FvProfile profile) {
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (context) => FameverseEditProfileScreen(
          profile: profile,
          avatarBusy: _avatarBusy,
          onChangePhoto: _pickProfilePhoto,
          onSave: _saveProfile,
        ),
      ),
    );
  }

  void _openCreatorStudio(FvProfile profile) {
    if (!_hasFullAppAccess) {
      _message('Earn First Verse to unlock Creator Studio.');
      return;
    }
    try {
      Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (context) => CreatorStudioScreen(
            backend: _getCreatorBackend(),
            identity: widget.identity,
            profile: profile,
          ),
        ),
      );
    } catch (_) {
      _message('Creator Studio is reconnecting.');
    }
  }

  void _openStories(FvProfile profile) {
    try {
      Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (context) => CreatorStoriesScreen(
            backend: SupabaseFameverseStoryBackend(Supabase.instance.client),
            identity: widget.identity,
            profile: profile,
          ),
        ),
      );
    } catch (_) {
      _message('Stories are reconnecting.');
    }
  }

  Future<void> _openFirstVerse() async {
    if (!_betaStatus.enrolled) return;
    try {
      await Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (context) => FirstVerseBetaScreen(
            backend: _getBetaBackend(),
            economyBackend: _getEconomyBackend(),
          ),
        ),
      );
      await _refreshBeta();
    } catch (_) {
      _message('First Verse is reconnecting.');
    }
  }

  void _openCoinExchange() {
    if (!_hasFullAppAccess) {
      _message('Earn First Verse to unlock Coin Exchange.');
      return;
    }
    try {
      Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (context) => CoinExchangeScreen(
            creatorBackend: _getCreatorBackend(),
            economyBackend: _getEconomyBackend(),
          ),
        ),
      );
    } catch (_) {
      _message('Coin Exchange is reconnecting.');
    }
  }

  void _openOwnerPanel() {
    if (!_isPrivileged) return;
    Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (context) => const OwnerControlPanel()),
    );
  }

  Future<void> _openPublicProfile(FvProfile target) async {
    if (target.id == widget.identity.id) {
      _setTab(3);
      return;
    }
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (context) => FameversePublicProfileScreen(
          viewerUserId: widget.identity.id,
          targetUserId: target.id,
          initialProfile: target,
        ),
      ),
    );
    await _recordBetaMission('open_public_profile');
    try {
      final network = await widget.backend.loadFollowNetwork(
        widget.identity.id,
      );
      if (mounted) setState(() => _network = network);
    } catch (_) {}
  }

  Future<void> _openRoom(FvLiveRoom room, FvProfile profile) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (context) => NativeViewerLiveScreen(
          backend: widget.backend,
          liveBackend: widget.liveBackend,
          identity: widget.identity,
          viewerProfile: profile,
          room: room,
          giftAccess: _hasFullAppAccess,
        ),
      ),
    );
    await _recordBetaMission('join_live');
  }

  void _setTab(int value) {
    if (value == 2 && !_hasFullAppAccess) {
      _message('Complete First Verse to unlock Go Live.');
      return;
    }
    setState(() => _tab = value);
    if (value == 0) {
      unawaited(_recordBetaMission('browse_home'));
    } else if (value == 1) {
      unawaited(_recordBetaMission('browse_discover'));
    } else if (value == 3) {
      unawaited(_refreshBeta());
    }
    if (value == 0 || value == 1) {
      widget.backend
          .listActiveLiveRooms(excludeUserId: widget.identity.id)
          .then((rooms) {
            if (mounted) setState(() => _rooms = rooms);
          })
          .catchError((_) {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile =
        _profile ??
        FvProfile(
          id: widget.identity.id,
          displayName: 'Fameverse User',
          username: null,
          bio: '',
          avatarUrl: null,
          createdAt: null,
        );

    final home = Stack(
      children: [
        FameverseHomeScreen(
          profile: profile,
          network: _network,
          creators: _creators,
          rooms: _rooms,
          loading: _loading,
          error: _error,
          onRefresh: _refreshAll,
          onOpenProfile: () => _setTab(3),
          onOpenDiscover: () => _setTab(1),
          onRoomSelected: (room) => unawaited(_openRoom(room, profile)),
          onToggleFollow: _toggleFollow,
          onCreatorSelected: _openPublicProfile,
          followBusy: _followBusy,
        ),
        Positioned(
          top: 10,
          right: 70,
          child: SafeArea(
            child: _StoryHeaderButton(
              profile: profile,
              onTap: () => _openStories(profile),
            ),
          ),
        ),
      ],
    );

    final profileSurface = Column(
      children: [
        SafeArea(
          bottom: false,
          child: _ProfileReleaseRail(
            profile: profile,
            betaStatus: _betaStatus,
            privileged: _isPrivileged,
            testerLimited: _testerLimited,
            onStories: () => _openStories(profile),
            onFirstVerse: _betaStatus.enrolled ? _openFirstVerse : null,
            onCoinExchange: _hasFullAppAccess ? _openCoinExchange : null,
            onControlPanel: _isPrivileged ? _openOwnerPanel : null,
          ),
        ),
        Expanded(
          child: NativeProfileScreen(
            profile: profile,
            identity: widget.identity,
            network: _network,
            avatarBusy: _avatarBusy,
            onChangePhoto: _pickProfilePhoto,
            onSettings: _openPolicies,
            onEdit: () => _openEdit(profile),
            onCreatorStudio: () => _openCreatorStudio(profile),
            onSignOut: widget.backend.signOut,
          ),
        ),
      ],
    );

    return Scaffold(
      body: IndexedStack(
        index: _tab,
        children: [
          home,
          FameverseDiscoverScreen(
            profile: profile,
            network: _network,
            creators: _creators,
            rooms: _rooms,
            loading: _loading,
            onRefresh: _refreshAll,
            onToggleFollow: _toggleFollow,
            onCreatorSelected: _openPublicProfile,
            followBusy: _followBusy,
            onOpenProfile: () => _setTab(3),
            onRoomSelected: (room) => unawaited(_openRoom(room, profile)),
          ),
          _hasFullAppAccess
              ? NativeCameraScreen(
                  liveBackend: widget.liveBackend,
                  identity: widget.identity,
                  profile: profile,
                  onLiveEnded: _refreshAll,
                )
              : _BetaLockedSurface(
                  status: _betaStatus,
                  onOpenFirstVerse: _openFirstVerse,
                ),
          profileSurface,
        ],
      ),
      bottomNavigationBar: NavigationBar(
        key: const Key('fameverse-bottom-nav'),
        selectedIndex: _tab,
        onDestinationSelected: _setTab,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore_rounded),
            label: 'Discover',
          ),
          NavigationDestination(
            icon: Icon(Icons.videocam_outlined),
            selectedIcon: Icon(Icons.videocam_rounded),
            label: 'Live',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class _ProfileReleaseRail extends StatelessWidget {
  const _ProfileReleaseRail({
    required this.profile,
    required this.betaStatus,
    required this.privileged,
    required this.testerLimited,
    required this.onStories,
    required this.onFirstVerse,
    required this.onCoinExchange,
    required this.onControlPanel,
  });

  final FvProfile profile;
  final FvBetaProgramStatus betaStatus;
  final bool privileged;
  final bool testerLimited;
  final VoidCallback onStories;
  final VoidCallback? onFirstVerse;
  final VoidCallback? onCoinExchange;
  final VoidCallback? onControlPanel;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('profile-release-rail'),
      margin: const EdgeInsets.fromLTRB(14, 8, 14, 2),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 11),
      decoration: BoxDecoration(
        color: const Color(0xFF120C16),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF3B2944)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _StoryHeaderButton(
                profile: profile,
                onTap: onStories,
                compact: false,
              ),
              const SizedBox(width: 10),
              if (betaStatus.enrolled)
                Expanded(
                  child: InkWell(
                    key: const Key('profile-first-verse-entry'),
                    onTap: onFirstVerse,
                    borderRadius: BorderRadius.circular(14),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                betaStatus.badgeUnlocked
                                    ? Icons.auto_awesome_rounded
                                    : Icons.lock_outline_rounded,
                                color: const Color(0xFFC783FF),
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              const Expanded(
                                child: Text(
                                  'First Verse',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                              Text(
                                '${betaStatus.completedRequired}/${betaStatus.requiredTotal}',
                                style: const TextStyle(
                                  color: Color(0xFFCDB7D5),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 7),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: LinearProgressIndicator(
                              key: const Key('profile-first-verse-progress'),
                              minHeight: 7,
                              value: betaStatus.progress,
                              backgroundColor: const Color(0xFF2A202E),
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                Color(0xFF9F51E4),
                              ),
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            privileged
                                ? 'Privileged access · badge progress still testable'
                                : testerLimited
                                ? 'Limited beta access until the badge is earned'
                                : 'Badge earned · full creator access unlocked',
                            style: const TextStyle(
                              color: Color(0xFF978A9C),
                              fontSize: 9.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
          if (onCoinExchange != null || onControlPanel != null) ...[
            const SizedBox(height: 9),
            Row(
              children: [
                if (onCoinExchange != null)
                  Expanded(
                    child: _ProfileUtilityButton(
                      key: const Key('profile-coin-exchange-entry'),
                      icon: Icons.swap_horiz_rounded,
                      label: 'Coin Exchange',
                      onTap: onCoinExchange!,
                    ),
                  ),
                if (onCoinExchange != null && onControlPanel != null)
                  const SizedBox(width: 8),
                if (onControlPanel != null)
                  Expanded(
                    child: _ProfileUtilityButton(
                      key: const Key('profile-owner-control-entry'),
                      icon: Icons.admin_panel_settings_rounded,
                      label: privileged ? 'Control' : 'Admin',
                      onTap: onControlPanel!,
                      privateControl: true,
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ProfileUtilityButton extends StatelessWidget {
  const _ProfileUtilityButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.privateControl = false,
    super.key,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool privateControl;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: privateControl
                ? const Color(0xFF0C0910)
                : const Color(0xFF21152A),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF4A3553)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 17, color: const Color(0xFFD19BFF)),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StoryHeaderButton extends StatelessWidget {
  const _StoryHeaderButton({
    required this.profile,
    required this.onTap,
    this.compact = true,
  });

  final FvProfile profile;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final size = compact ? 46.0 : 54.0;
    return Semantics(
      button: true,
      label: 'Open Creator Stories',
      child: GestureDetector(
        key: Key(compact ? 'home-stories-header' : 'profile-stories-header'),
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: size,
                  height: size,
                  padding: const EdgeInsets.all(2.5),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFFF05A86),
                        Color(0xFFB95EFF),
                        Color(0xFF604BFF),
                      ],
                    ),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black,
                    ),
                    child: ClipOval(
                      child:
                          profile.avatarUrl != null &&
                              profile.avatarUrl!.isNotEmpty
                          ? Image.network(
                              profile.avatarUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  _StoryFallback(initial: profile.initial),
                            )
                          : _StoryFallback(initial: profile.initial),
                    ),
                  ),
                ),
                Positioned(
                  right: -2,
                  bottom: -1,
                  child: Container(
                    width: 17,
                    height: 17,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF8E3EDD),
                    ),
                    child: const Icon(
                      Icons.add_rounded,
                      size: 13,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            if (!compact) ...[
              const SizedBox(height: 4),
              const Text(
                'Story',
                style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StoryFallback extends StatelessWidget {
  const _StoryFallback({required this.initial});

  final String initial;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFF352044),
      child: Center(
        child: Text(
          initial,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
        ),
      ),
    );
  }
}

class _BetaLockedSurface extends StatelessWidget {
  const _BetaLockedSurface({
    required this.status,
    required this.onOpenFirstVerse,
  });

  final FvBetaProgramStatus status;
  final VoidCallback onOpenFirstVerse;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Container(
            key: const Key('beta-full-access-lock'),
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: const Color(0xFF151018),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFF4B3159)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.lock_outline_rounded,
                  color: Color(0xFFC783FF),
                  size: 34,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Earn First Verse to Go Live',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 7),
                Text(
                  '${status.completedRequired}/${status.requiredTotal} required beta checks complete.',
                  style: const TextStyle(color: Color(0xFFAEA2B2)),
                ),
                const SizedBox(height: 14),
                FilledButton.icon(
                  onPressed: onOpenFirstVerse,
                  icon: const Icon(Icons.auto_awesome_rounded),
                  label: const Text('View First Verse progress'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

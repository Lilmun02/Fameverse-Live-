import 'package:flutter/material.dart';

import '../../data/fameverse_backend.dart';
import '../live/native_camera_screen.dart';

class FameverseShell extends StatefulWidget {
  const FameverseShell({
    required this.backend,
    required this.identity,
    super.key,
  });

  final FameverseBackend backend;
  final FvIdentity identity;

  @override
  State<FameverseShell> createState() => _FameverseShellState();
}

class _FameverseShellState extends State<FameverseShell> {
  static const _emptyNetwork = FvFollowNetwork(
    followers: [],
    following: [],
    followerIds: {},
    followingIds: {},
  );

  int _tab = 0;
  bool _loading = true;
  bool _followBusy = false;
  String? _error;
  FvProfile? _profile;
  FvFollowNetwork _network = _emptyNetwork;
  List<FvCreator> _creators = const [];
  List<FvLiveRoom> _rooms = const [];

  @override
  void initState() {
    super.initState();
    _refreshAll();
  }

  Future<void> _refreshAll() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final profile = await widget.backend.loadProfile(widget.identity.id);
      final network = await widget.backend.loadFollowNetwork(
        widget.identity.id,
      );
      final creators = await widget.backend.listRecommendedCreators(
        excludeUserId: widget.identity.id,
      );
      final rooms = await widget.backend.listActiveLiveRooms(
        excludeUserId: widget.identity.id,
      );
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _network = network;
        _creators = creators;
        _rooms = rooms;
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
      final currentlyFollowing = _network.followingIds.contains(targetId);
      await widget.backend.setFollowing(
        userId: widget.identity.id,
        targetId: targetId,
        following: !currentlyFollowing,
      );
      final network = await widget.backend.loadFollowNetwork(
        widget.identity.id,
      );
      if (mounted) setState(() => _network = network);
    } catch (_) {
      if (mounted) _showMessage('Could not update that connection.');
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
      _showMessage('Profile saved');
    } catch (error) {
      if (!mounted) return;
      final text = error.toString();
      _showMessage(
        text.contains('23505')
            ? 'That username is already taken'
            : text.contains('at least 3')
            ? 'Username must be at least 3 characters'
            : 'Could not save profile',
      );
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _setTab(int value) {
    setState(() => _tab = value);
    if (value == 1) {
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

    final pages = [
      _HomeScreen(
        profile: profile,
        network: _network,
        loading: _loading,
        error: _error,
        onRefresh: _refreshAll,
        onOpenProfile: () => _setTab(3),
        onToggleFollow: _toggleFollow,
        followBusy: _followBusy,
      ),
      _DiscoverScreen(
        profile: profile,
        network: _network,
        creators: _creators,
        rooms: _rooms,
        loading: _loading,
        onRefresh: _refreshAll,
        onToggleFollow: _toggleFollow,
        followBusy: _followBusy,
        onOpenProfile: () => _setTab(3),
        onRoomSelected: (room) {
          showModalBottomSheet<void>(
            context: context,
            showDragHandle: true,
            builder: (context) => _ViewerMigrationSheet(room: room),
          );
        },
      ),
      const NativeCameraScreen(),
      _ProfileScreen(
        profile: profile,
        identity: widget.identity,
        network: _network,
        onEdit: () => showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          showDragHandle: true,
          builder: (context) =>
              _EditProfileSheet(profile: profile, onSave: _saveProfile),
        ),
        onSignOut: widget.backend.signOut,
      ),
    ];

    return Scaffold(
      body: IndexedStack(index: _tab, children: pages),
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
            icon: Icon(Icons.auto_awesome_outlined),
            selectedIcon: Icon(Icons.auto_awesome),
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

class _HomeScreen extends StatefulWidget {
  const _HomeScreen({
    required this.profile,
    required this.network,
    required this.loading,
    required this.error,
    required this.onRefresh,
    required this.onOpenProfile,
    required this.onToggleFollow,
    required this.followBusy,
  });

  final FvProfile profile;
  final FvFollowNetwork network;
  final bool loading;
  final String? error;
  final Future<void> Function() onRefresh;
  final VoidCallback onOpenProfile;
  final ValueChanged<String> onToggleFollow;
  final bool followBusy;

  @override
  State<_HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<_HomeScreen> {
  String _group = 'friends';
  String _query = '';

  List<FvProfile> get _groupProfiles => switch (_group) {
    'following' => widget.network.following,
    'followers' => widget.network.followers,
    _ => widget.network.friends,
  };

  List<FvProfile> get _visibleProfiles {
    final needle = _query.trim().toLowerCase();
    if (needle.isEmpty) return _groupProfiles;
    return _groupProfiles.where((profile) {
      return '${profile.displayName} ${profile.username ?? ''}'
          .toLowerCase()
          .contains(needle);
    }).toList();
  }

  String _relationLabel(FvProfile profile) {
    final follows = widget.network.followingIds.contains(profile.id);
    final followsYou = widget.network.followerIds.contains(profile.id);
    if (follows && followsYou) return 'Friends';
    if (follows) return 'Following';
    if (followsYou) return 'Follow back';
    return 'Follow';
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: widget.onRefresh,
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 110),
              sliver: SliverList.list(
                children: [
                  Row(
                    children: [
                      const Text(
                        'FAMEVERSE',
                        key: Key('native-product-wordmark'),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const Spacer(),
                      _AvatarButton(
                        profile: widget.profile,
                        onTap: widget.onOpenProfile,
                      ),
                    ],
                  ),
                  const SizedBox(height: 34),
                  const _Eyebrow('COMMUNITY'),
                  const SizedBox(height: 8),
                  Text(
                    'Hey, ${widget.profile.displayName}',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      height: 1.05,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${widget.profile.handle} · Your connections live here.',
                    style: const TextStyle(color: Color(0xFFAEA4B7)),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    onChanged: (value) => setState(() => _query = value),
                    decoration: _searchDecoration('Search creators'),
                  ),
                  const SizedBox(height: 16),
                  _SegmentedCommunityTabs(
                    group: _group,
                    onChanged: (value) => setState(() => _group = value),
                    friends: widget.network.friends.length,
                    following: widget.network.following.length,
                    followers: widget.network.followers.length,
                  ),
                  const SizedBox(height: 28),
                  Text(
                    switch (_group) {
                      'following' => 'Following',
                      'followers' => 'Followers',
                      _ => 'Friends',
                    },
                    style: const TextStyle(
                      color: Color(0xFF9B8DA8),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Your circle',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 16),
                  if (widget.loading && _groupProfiles.isEmpty)
                    const _LoadingCard()
                  else if (widget.error != null && _groupProfiles.isEmpty)
                    _EmptyCard(
                      title: 'Community is reconnecting',
                      body: widget.error!,
                    )
                  else if (_visibleProfiles.isEmpty)
                    _EmptyCard(
                      title: _query.isNotEmpty
                          ? 'No matches'
                          : _group == 'friends'
                          ? 'Your circle is empty for now'
                          : 'No $_group yet',
                      body: _query.isNotEmpty
                          ? 'Try another name or username.'
                          : 'When you connect with real people, they will show up here.',
                    )
                  else
                    ..._visibleProfiles.map(
                      (person) => _PersonTile(
                        profile: person,
                        actionLabel: _relationLabel(person),
                        busy: widget.followBusy,
                        onPressed: () => widget.onToggleFollow(person.id),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DiscoverScreen extends StatefulWidget {
  const _DiscoverScreen({
    required this.profile,
    required this.network,
    required this.creators,
    required this.rooms,
    required this.loading,
    required this.onRefresh,
    required this.onToggleFollow,
    required this.followBusy,
    required this.onOpenProfile,
    required this.onRoomSelected,
  });

  final FvProfile profile;
  final FvFollowNetwork network;
  final List<FvCreator> creators;
  final List<FvLiveRoom> rooms;
  final bool loading;
  final Future<void> Function() onRefresh;
  final ValueChanged<String> onToggleFollow;
  final bool followBusy;
  final VoidCallback onOpenProfile;
  final ValueChanged<FvLiveRoom> onRoomSelected;

  @override
  State<_DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<_DiscoverScreen> {
  String _filter = 'For You';
  String _query = '';

  bool _filterAllows(String id) {
    if (_filter == 'Following') return widget.network.followingIds.contains(id);
    if (_filter == 'Friends') {
      return widget.network.followingIds.contains(id) &&
          widget.network.followerIds.contains(id);
    }
    return true;
  }

  bool _matches(Iterable<String?> values) {
    final needle = _query.trim().toLowerCase();
    if (needle.isEmpty) return true;
    return values.whereType<String>().join(' ').toLowerCase().contains(needle);
  }

  List<FvLiveRoom> get _visibleRooms => widget.rooms.where((room) {
    return _filterAllows(room.hostUserId) &&
        _matches([room.title, room.host.displayName, room.host.username]);
  }).toList();

  List<FvCreator> get _visibleCreators => widget.creators.where((creator) {
    return _filterAllows(creator.profile.id) &&
        _matches([
          creator.profile.displayName,
          creator.profile.username,
          creator.profile.bio,
        ]);
  }).toList();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: widget.onRefresh,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 110),
          children: [
            Row(
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'FAMEVERSE',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.3,
                      ),
                    ),
                    Text(
                      'Discover',
                      key: Key('discover-title'),
                      style: TextStyle(
                        fontSize: 31,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                _AvatarButton(
                  profile: widget.profile,
                  onTap: widget.onOpenProfile,
                ),
              ],
            ),
            const SizedBox(height: 22),
            TextField(
              onChanged: (value) => setState(() => _query = value),
              decoration: _searchDecoration('Search creators or live titles'),
            ),
            const SizedBox(height: 14),
            Row(
              children: ['For You', 'Following', 'Friends'].map((label) {
                final selected = _filter == label;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 7),
                    child: ChoiceChip(
                      label: Center(child: Text(label)),
                      selected: selected,
                      onSelected: (_) => setState(() => _filter = label),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 30),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Eyebrow('LIVE NOW'),
                      SizedBox(height: 4),
                      Text(
                        'Streaming now',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${_visibleRooms.length} live',
                  style: const TextStyle(color: Color(0xFF9F94A8)),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (widget.loading && widget.rooms.isEmpty)
              const _LoadingCard()
            else if (_visibleRooms.isEmpty)
              const _EmptyCard(
                title: 'No creators are live right now',
                body: 'Only real active Fameverse rooms appear here.',
              )
            else
              SizedBox(
                height: 210,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _visibleRooms.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final room = _visibleRooms[index];
                    return _LiveRoomCard(
                      room: room,
                      onTap: () => widget.onRoomSelected(room),
                    );
                  },
                ),
              ),
            const SizedBox(height: 34),
            const _Eyebrow('COMMUNITY'),
            const SizedBox(height: 4),
            const Text(
              'Recommended creators',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 14),
            if (_visibleCreators.isEmpty)
              const _EmptyCard(
                title: 'No matching creators yet',
                body: 'Try another search or switch back to For You.',
              )
            else
              ..._visibleCreators.map((creator) {
                final following = widget.network.followingIds.contains(
                  creator.profile.id,
                );
                return _PersonTile(
                  profile: creator.profile,
                  subtitle:
                      '${creator.profile.handle} · ${_compact(creator.followerCount)} followers',
                  actionLabel: following ? 'Following' : 'Follow',
                  busy: widget.followBusy,
                  onPressed: () => widget.onToggleFollow(creator.profile.id),
                );
              }),
          ],
        ),
      ),
    );
  }
}

class _ProfileScreen extends StatelessWidget {
  const _ProfileScreen({
    required this.profile,
    required this.identity,
    required this.network,
    required this.onEdit,
    required this.onSignOut,
  });

  final FvProfile profile;
  final FvIdentity identity;
  final FvFollowNetwork network;
  final VoidCallback onEdit;
  final Future<void> Function() onSignOut;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 120),
        children: [
          Row(
            children: [
              const Text(
                'PROFILE',
                key: Key('profile-title'),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.3,
                ),
              ),
              const Spacer(),
              IconButton.filledTonal(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_rounded),
                tooltip: 'Edit profile',
              ),
            ],
          ),
          const SizedBox(height: 26),
          Center(child: _LargeAvatar(profile: profile)),
          const SizedBox(height: 16),
          Center(
            child: Text(
              profile.displayName,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
            ),
          ),
          const SizedBox(height: 4),
          Center(
            child: Text(
              profile.handle,
              style: const TextStyle(color: Color(0xFFAFA5B7)),
            ),
          ),
          if (profile.bio.trim().isNotEmpty) ...[
            const SizedBox(height: 14),
            Center(
              child: Text(
                profile.bio,
                textAlign: TextAlign.center,
                style: const TextStyle(height: 1.4),
              ),
            ),
          ],
          const SizedBox(height: 28),
          Row(
            children: [
              _StatCard(label: 'Followers', value: network.followers.length),
              const SizedBox(width: 10),
              _StatCard(label: 'Following', value: network.following.length),
              const SizedBox(width: 10),
              _StatCard(label: 'Friends', value: network.friends.length),
            ],
          ),
          const SizedBox(height: 28),
          const _Eyebrow('ACCOUNT'),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: _panelDecoration(),
            child: Row(
              children: [
                const Icon(Icons.mail_outline_rounded),
                const SizedBox(width: 12),
                Expanded(child: Text(identity.email)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onSignOut,
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Sign out'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
            ),
          ),
        ],
      ),
    );
  }
}

class _EditProfileSheet extends StatefulWidget {
  const _EditProfileSheet({required this.profile, required this.onSave});

  final FvProfile profile;
  final Future<void> Function({
    required String displayName,
    required String username,
    required String bio,
  })
  onSave;

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  late final TextEditingController _displayName;
  late final TextEditingController _username;
  late final TextEditingController _bio;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _displayName = TextEditingController(text: widget.profile.displayName);
    _username = TextEditingController(text: widget.profile.username ?? '');
    _bio = TextEditingController(text: widget.profile.bio);
  }

  @override
  void dispose() {
    _displayName.dispose();
    _username.dispose();
    _bio.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_busy) return;
    setState(() => _busy = true);
    await widget.onSave(
      displayName: _displayName.text,
      username: _username.text,
      bio: _bio.text,
    );
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        8,
        20,
        MediaQuery.viewInsetsOf(context).bottom + 28,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Edit profile',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: _displayName,
              maxLength: 40,
              decoration: const InputDecoration(labelText: 'Display name'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _username,
              maxLength: 24,
              decoration: const InputDecoration(labelText: 'Username'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _bio,
              maxLength: 160,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'Bio'),
            ),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: _busy ? null : _save,
              child: _busy
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save profile'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ViewerMigrationSheet extends StatelessWidget {
  const _ViewerMigrationSheet({required this.room});

  final FvLiveRoom room;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 34),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Eyebrow('LIVE NOW'),
          const SizedBox(height: 8),
          Text(
            room.title,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Text('${room.host.displayName} · ${room.host.handle}'),
          const SizedBox(height: 18),
          const Text(
            'This room is real and active. Native viewer video transport is still gated until it matches the existing Fameverse Live contract, so this build will not fake playback.',
            style: TextStyle(color: Color(0xFFB6AABE), height: 1.4),
          ),
          const SizedBox(height: 18),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}

class _LiveRoomCard extends StatelessWidget {
  const _LiveRoomCard({required this.room, required this.onTap});

  final FvLiveRoom room;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 170,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF421B69), Color(0xFF17101E)],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF315F),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text(
                        'LIVE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'F ${_compact(room.fameTaps)}',
                      style: const TextStyle(fontSize: 11),
                    ),
                  ],
                ),
                const Spacer(),
                _SmallAvatar(profile: room.host),
                const SizedBox(height: 10),
                Text(
                  room.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  room.host.handle,
                  style: const TextStyle(
                    color: Color(0xFFB6AABE),
                    fontSize: 12,
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

class _PersonTile extends StatelessWidget {
  const _PersonTile({
    required this.profile,
    required this.actionLabel,
    required this.busy,
    required this.onPressed,
    this.subtitle,
  });

  final FvProfile profile;
  final String actionLabel;
  final bool busy;
  final VoidCallback onPressed;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: _panelDecoration(),
      child: Row(
        children: [
          _SmallAvatar(profile: profile),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle ?? profile.handle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFAFA4B8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: busy ? null : onPressed,
            child: Text(busy ? '…' : actionLabel),
          ),
        ],
      ),
    );
  }
}

class _SegmentedCommunityTabs extends StatelessWidget {
  const _SegmentedCommunityTabs({
    required this.group,
    required this.onChanged,
    required this.friends,
    required this.following,
    required this.followers,
  });

  final String group;
  final ValueChanged<String> onChanged;
  final int friends;
  final int following;
  final int followers;

  @override
  Widget build(BuildContext context) {
    final items = [
      ('friends', 'Friends', friends),
      ('following', 'Following', following),
      ('followers', 'Followers', followers),
    ];
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF17121E),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: items.map((item) {
          final selected = item.$1 == group;
          return Expanded(
            child: InkWell(
              onTap: () => onChanged(item.$1),
              borderRadius: BorderRadius.circular(14),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                padding: const EdgeInsets.symmetric(vertical: 11),
                decoration: BoxDecoration(
                  color: selected
                      ? const Color(0xFF39234F)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  children: [
                    Text(
                      item.$2,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: selected
                            ? FontWeight.w800
                            : FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${item.$3}',
                      style: const TextStyle(
                        color: Color(0xFFAFA4B8),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _Eyebrow extends StatelessWidget {
  const _Eyebrow(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: Theme.of(context).colorScheme.primary,
        fontSize: 11,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.15,
      ),
    );
  }
}

class _AvatarButton extends StatelessWidget {
  const _AvatarButton({required this.profile, required this.onTap});

  final FvProfile profile;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: _SmallAvatar(profile: profile),
    );
  }
}

class _SmallAvatar extends StatelessWidget {
  const _SmallAvatar({required this.profile});

  final FvProfile profile;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 22,
      backgroundColor: const Color(0xFF42265F),
      foregroundImage: profile.avatarUrl == null
          ? null
          : NetworkImage(profile.avatarUrl!),
      child: Text(
        profile.initial,
        style: const TextStyle(fontWeight: FontWeight.w900),
      ),
    );
  }
}

class _LargeAvatar extends StatelessWidget {
  const _LargeAvatar({required this.profile});

  final FvProfile profile;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 54,
      backgroundColor: const Color(0xFF42265F),
      foregroundImage: profile.avatarUrl == null
          ? null
          : NetworkImage(profile.avatarUrl!),
      child: Text(
        profile.initial,
        style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: _panelDecoration(),
        child: Column(
          children: [
            Text(
              _compact(value),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: const TextStyle(color: Color(0xFFAFA4B8), fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(26),
      decoration: _panelDecoration(),
      child: const Center(child: CircularProgressIndicator()),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text(
            body,
            style: const TextStyle(color: Color(0xFFAFA4B8), height: 1.35),
          ),
        ],
      ),
    );
  }
}

InputDecoration _searchDecoration(String hint) {
  return InputDecoration(
    hintText: hint,
    prefixIcon: const Icon(Icons.search_rounded),
    filled: true,
    fillColor: const Color(0xFF17121E),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: BorderSide.none,
    ),
  );
}

BoxDecoration _panelDecoration() {
  return BoxDecoration(
    color: const Color(0xFF17121E),
    borderRadius: BorderRadius.circular(18),
    border: Border.all(color: const Color(0xFF2A2132)),
  );
}

String _compact(int value) {
  if (value >= 1000000) {
    return '${(value / 1000000).toStringAsFixed(value >= 10000000 ? 0 : 1)}M';
  }
  if (value >= 1000) {
    return '${(value / 1000).toStringAsFixed(value >= 10000 ? 0 : 1)}K';
  }
  return '$value';
}

part of 'fameverse_shell.dart';

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

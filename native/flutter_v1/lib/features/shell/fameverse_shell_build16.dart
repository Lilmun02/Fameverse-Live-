import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/fameverse_backend.dart';
import '../../data/fameverse_creator_backend.dart';
import '../../data/fameverse_live_backend.dart';
import '../live/livekit_live_screen.dart';
import '../live/native_camera_screen.dart';
import '../profile/creator_studio_screen.dart';
import '../profile/native_profile_screen.dart';

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

  int _tab = 0;
  bool _loading = true;
  bool _followBusy = false;
  bool _avatarBusy = false;
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
      final results = await Future.wait<dynamic>([
        widget.backend.loadProfile(widget.identity.id),
        widget.backend.loadFollowNetwork(widget.identity.id),
        widget.backend.listRecommendedCreators(excludeUserId: widget.identity.id),
        widget.backend.listActiveLiveRooms(excludeUserId: widget.identity.id),
      ]);
      if (!mounted) return;
      setState(() {
        _profile = results[0] as FvProfile?;
        _network = results[1] as FvFollowNetwork;
        _creators = results[2] as List<FvCreator>;
        _rooms = results[3] as List<FvLiveRoom>;
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
      final network = await widget.backend.loadFollowNetwork(widget.identity.id);
      if (mounted) setState(() => _network = network);
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

  void _openSettings() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => const _Build16SettingsSheet(),
    );
  }

  void _openEdit(FvProfile profile) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => _Build16EditProfileSheet(
        profile: profile,
        onSave: _saveProfile,
      ),
    );
  }

  void _openCreatorStudio(FvProfile profile) {
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (context) => CreatorStudioScreen(
          backend: SupabaseFameverseCreatorBackend(Supabase.instance.client),
          identity: widget.identity,
          profile: profile,
        ),
      ),
    );
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
    final profile = _profile ?? FvProfile(
      id: widget.identity.id,
      displayName: 'Fameverse User',
      username: null,
      bio: '',
      avatarUrl: null,
      createdAt: null,
    );

    return Scaffold(
      body: IndexedStack(
        index: _tab,
        children: [
          _Build16HomeScreen(
            profile: profile,
            network: _network,
            loading: _loading,
            error: _error,
            onRefresh: _refreshAll,
            onOpenProfile: () => _setTab(3),
            onToggleFollow: _toggleFollow,
            followBusy: _followBusy,
          ),
          _Build16DiscoverScreen(
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
              Navigator.of(context).push<void>(
                MaterialPageRoute(
                  builder: (context) => NativeViewerLiveScreen(
                    backend: widget.backend,
                    liveBackend: widget.liveBackend,
                    identity: widget.identity,
                    viewerProfile: profile,
                    room: room,
                  ),
                ),
              );
            },
          ),
          NativeCameraScreen(
            liveBackend: widget.liveBackend,
            identity: widget.identity,
            profile: profile,
            onLiveEnded: _refreshAll,
          ),
          NativeProfileScreen(
            profile: profile,
            identity: widget.identity,
            network: _network,
            avatarBusy: _avatarBusy,
            onChangePhoto: _pickProfilePhoto,
            onSettings: _openSettings,
            onEdit: () => _openEdit(profile),
            onCreatorStudio: () => _openCreatorStudio(profile),
            onSignOut: widget.backend.signOut,
          ),
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

class _Build16HomeScreen extends StatefulWidget {
  const _Build16HomeScreen({
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
  State<_Build16HomeScreen> createState() => _Build16HomeScreenState();
}

class _Build16HomeScreenState extends State<_Build16HomeScreen> {
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
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 110),
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
                _Build16AvatarButton(
                  profile: widget.profile,
                  onTap: widget.onOpenProfile,
                ),
              ],
            ),
            const SizedBox(height: 34),
            const _Build16Eyebrow('COMMUNITY'),
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
              decoration: _build16SearchDecoration('Search creators'),
            ),
            const SizedBox(height: 16),
            _Build16CommunityTabs(
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
              const _Build16LoadingCard()
            else if (widget.error != null && _groupProfiles.isEmpty)
              _Build16EmptyCard(
                title: 'Community is reconnecting',
                body: widget.error!,
              )
            else if (_visibleProfiles.isEmpty)
              _Build16EmptyCard(
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
                (person) => _Build16PersonTile(
                  profile: person,
                  actionLabel: _relationLabel(person),
                  busy: widget.followBusy,
                  onPressed: () => widget.onToggleFollow(person.id),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Build16DiscoverScreen extends StatefulWidget {
  const _Build16DiscoverScreen({
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
  State<_Build16DiscoverScreen> createState() => _Build16DiscoverScreenState();
}

class _Build16DiscoverScreenState extends State<_Build16DiscoverScreen> {
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
                _Build16AvatarButton(
                  profile: widget.profile,
                  onTap: widget.onOpenProfile,
                ),
              ],
            ),
            const SizedBox(height: 22),
            TextField(
              onChanged: (value) => setState(() => _query = value),
              decoration: _build16SearchDecoration(
                'Search creators or live titles',
              ),
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
                      _Build16Eyebrow('LIVE NOW'),
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
              const _Build16LoadingCard()
            else if (_visibleRooms.isEmpty)
              const _Build16EmptyCard(
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
                    return _Build16LiveRoomCard(
                      room: room,
                      onTap: () => widget.onRoomSelected(room),
                    );
                  },
                ),
              ),
            const SizedBox(height: 34),
            const _Build16Eyebrow('COMMUNITY'),
            const SizedBox(height: 4),
            const Text(
              'Recommended creators',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 14),
            if (_visibleCreators.isEmpty)
              const _Build16EmptyCard(
                title: 'No matching creators yet',
                body: 'Try another search or switch back to For You.',
              )
            else
              ..._visibleCreators.map((creator) {
                final following = widget.network.followingIds.contains(
                  creator.profile.id,
                );
                return _Build16PersonTile(
                  profile: creator.profile,
                  subtitle:
                      '${creator.profile.handle} · ${_build16Compact(creator.followerCount)} followers',
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

class _Build16EditProfileSheet extends StatefulWidget {
  const _Build16EditProfileSheet({required this.profile, required this.onSave});

  final FvProfile profile;
  final Future<void> Function({
    required String displayName,
    required String username,
    required String bio,
  }) onSave;

  @override
  State<_Build16EditProfileSheet> createState() =>
      _Build16EditProfileSheetState();
}

class _Build16EditProfileSheetState extends State<_Build16EditProfileSheet> {
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

class _Build16SettingsSheet extends StatelessWidget {
  const _Build16SettingsSheet();

  static const _terms =
      '''Fameverse Beta Terms of Use\n\nFameverse is currently a beta service. Features may change while we test and improve the product. You must use Fameverse lawfully and may not abuse, disrupt, exploit, automate attacks against, or attempt to bypass safety and moderation systems.\n\nBeta test coins and beta gifts remain test-only unless Fameverse clearly identifies a real-money recharge as active. Real-money purchase terms will be presented before recharge is enabled for a user.\n\nYou remain responsible for content you create, stream, upload, or send. Fameverse may remove content or restrict accounts when needed to enforce these terms, protect users, or comply with law.''';

  static const _privacy =
      '''Fameverse Beta Privacy Notice\n\nFameverse uses account information, profile information, social connections, live-room activity, comments, gifts, FameTaps, moderation signals, verification status, payout status, and technical information needed to operate and secure the beta.\n\nProfile information you choose to publish can be visible to other Fameverse users. Live activity is shared with participants as required for the experience. Authentication and authoritative app data are handled through Fameverse backend services.\n\nIdentity and payment providers may require additional information when real-money verification, recharge, or payouts are enabled.''';

  static const _community =
      '''Fameverse Community Standards\n\nFameverse is for real people to create, watch, gift, and belong. Do not use Fameverse for credible threats, targeted harassment, hateful abuse, sexual exploitation, scams, impersonation intended to defraud, illegal content, spam, platform manipulation, or attempts to compromise another user's account or device.\n\nCreators are responsible for moderating their live spaces with the tools provided. Fameverse may remove content, end a live, restrict features, suspend accounts, or hold monetization when necessary to protect the community and enforce these standards.''';

  static const _creator =
      '''Fameverse Creator Beta Terms\n\nCreators are responsible for their live content, titles, goals, interactions, and moderation choices. Payout eligibility is separate from Fame Coins and requires cleared creator earnings, creator verification, account good standing, and Fameverse payout review. The minimum payout request is $25.00.\n\nA balance shown as pending or under review is not yet available for payout. Fameverse may hold, reject, reverse, or investigate earnings or payouts where fraud, chargebacks, manipulation, policy violations, or verification problems are identified.\n\nThe creator revenue split and any coin-to-earnings conversion will not be activated until Fameverse publishes those economics.''';

  void _open(BuildContext context, String title, String body) {
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (context) => _Build16LegalScreen(title: title, body: body),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * .72,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: [
            const Text(
              'Settings',
              key: Key('native-settings-title'),
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            const Text(
              'Fameverse beta policies, creator monetization and account information.',
              style: TextStyle(color: Color(0xFFAFA4B8)),
            ),
            const SizedBox(height: 22),
            _Build16SettingsTile(
              icon: Icons.description_outlined,
              title: 'Terms of Use',
              onTap: () => _open(context, 'Terms of Use', _terms),
            ),
            _Build16SettingsTile(
              icon: Icons.privacy_tip_outlined,
              title: 'Privacy Notice',
              onTap: () => _open(context, 'Privacy Notice', _privacy),
            ),
            _Build16SettingsTile(
              icon: Icons.shield_outlined,
              title: 'Community Standards',
              onTap: () => _open(context, 'Community Standards', _community),
            ),
            _Build16SettingsTile(
              icon: Icons.live_tv_outlined,
              title: 'Creator Beta Terms',
              onTap: () => _open(context, 'Creator Beta Terms', _creator),
            ),
          ],
        ),
      ),
    );
  }
}

class _Build16SettingsTile extends StatelessWidget {
  const _Build16SettingsTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      ),
    );
  }
}

class _Build16LegalScreen extends StatelessWidget {
  const _Build16LegalScreen({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [Text(body, style: const TextStyle(height: 1.55))],
        ),
      ),
    );
  }
}

class _Build16LiveRoomCard extends StatelessWidget {
  const _Build16LiveRoomCard({required this.room, required this.onTap});

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
                      'F ${_build16Compact(room.fameTaps)}',
                      style: const TextStyle(fontSize: 11),
                    ),
                  ],
                ),
                const Spacer(),
                _Build16SmallAvatar(profile: room.host),
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

class _Build16PersonTile extends StatelessWidget {
  const _Build16PersonTile({
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
      decoration: _build16Panel(),
      child: Row(
        children: [
          _Build16SmallAvatar(profile: profile),
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

class _Build16CommunityTabs extends StatelessWidget {
  const _Build16CommunityTabs({
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

class _Build16Eyebrow extends StatelessWidget {
  const _Build16Eyebrow(this.text);

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

class _Build16AvatarButton extends StatelessWidget {
  const _Build16AvatarButton({required this.profile, required this.onTap});

  final FvProfile profile;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: _Build16SmallAvatar(profile: profile),
    );
  }
}

class _Build16SmallAvatar extends StatelessWidget {
  const _Build16SmallAvatar({required this.profile});

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

class _Build16LoadingCard extends StatelessWidget {
  const _Build16LoadingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(26),
      decoration: _build16Panel(),
      child: const Center(child: CircularProgressIndicator()),
    );
  }
}

class _Build16EmptyCard extends StatelessWidget {
  const _Build16EmptyCard({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _build16Panel(),
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

InputDecoration _build16SearchDecoration(String hint) {
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

BoxDecoration _build16Panel() {
  return BoxDecoration(
    color: const Color(0xFF17121E),
    borderRadius: BorderRadius.circular(18),
    border: Border.all(color: const Color(0xFF2A2132)),
  );
}

String _build16Compact(int value) {
  if (value >= 1000000) {
    return '${(value / 1000000).toStringAsFixed(value >= 10000000 ? 0 : 1)}M';
  }
  if (value >= 1000) {
    return '${(value / 1000).toStringAsFixed(value >= 10000 ? 0 : 1)}K';
  }
  return '$value';
}

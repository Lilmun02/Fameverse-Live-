part of 'fameverse_shell_build16.dart';

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
  int _tab = 0;
  bool _loading = true;
  bool _followBusy = false;
  bool _avatarBusy = false;
  String? _error;
  FvProfile? _profile;
  FvFollowNetwork _network = _emptyNetwork;
  List<FvCreator> _creators = const [];
  List<FvLiveRoom> _rooms = const [];
  FvBetaProgramStatus _betaStatus = FvBetaProgramStatus.notEnrolled;

  @override
  void initState() {
    super.initState();
    unawaited(_refreshAll());
    unawaited(_refreshBeta());
  }

  SupabaseFameverseBetaBackend _getBetaBackend() =>
      _betaBackend ??= SupabaseFameverseBetaBackend(Supabase.instance.client);

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
      // Beta mission infrastructure must never block ordinary Fameverse use.
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
      // Mission telemetry is non-critical and must fail closed without breaking
      // the tested feature itself.
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

  void _openStories(FvProfile profile) {
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (context) => CreatorStoriesScreen(
          backend: SupabaseFameverseStoryBackend(Supabase.instance.client),
          identity: widget.identity,
          profile: profile,
        ),
      ),
    );
  }

  Future<void> _openFirstVerse() async {
    final backend = _betaBackend;
    if (!_betaStatus.enrolled || backend == null) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (context) => FirstVerseBetaScreen(backend: backend),
      ),
    );
    await _refreshBeta();
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
        ),
      ),
    );
    await _recordBetaMission('join_live');
  }

  void _setTab(int value) {
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

    Widget? floatingActionButton;
    if (_tab == 0) {
      floatingActionButton = _HomeStoryLauncher(
        profile: profile,
        onTap: () => _openStories(profile),
      );
    } else if (_tab == 3 && _betaStatus.enrolled) {
      floatingActionButton = FloatingActionButton.extended(
        key: const Key('first-verse-tester-entry'),
        onPressed: _openFirstVerse,
        icon: Icon(
          _betaStatus.badgeUnlocked
              ? Icons.auto_awesome_rounded
              : Icons.lock_outline_rounded,
        ),
        label: Text(
          _betaStatus.badgeUnlocked
              ? 'First Verse'
              : 'First Verse ${_betaStatus.completedRequired}/${_betaStatus.requiredTotal}',
        ),
      );
    }

    return Scaffold(
      body: IndexedStack(
        index: _tab,
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
            onSettings: _openPolicies,
            onEdit: () => _openEdit(profile),
            onCreatorStudio: () => _openCreatorStudio(profile),
            onSignOut: widget.backend.signOut,
          ),
        ],
      ),
      floatingActionButton: floatingActionButton,
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

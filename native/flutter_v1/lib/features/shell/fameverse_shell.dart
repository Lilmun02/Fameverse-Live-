import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../data/fameverse_backend.dart';
import '../../data/fameverse_live_backend.dart';
import '../live/livekit_live_screen.dart';
import '../live/native_camera_screen.dart';
part 'fameverse_shell_home_discover.part.dart';
part 'fameverse_shell_profile.part.dart';
part 'fameverse_shell_support.part.dart';


class FameverseShell extends StatefulWidget {
  const FameverseShell({
    required this.backend,
    required this.liveBackend,
    required this.identity,
    super.key,
  });

  final FameverseBackend backend;
  final FameverseLiveBackend liveBackend;
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
      _showMessage('Profile photo updated');
    } catch (_) {
      if (mounted) _showMessage('Could not update profile photo.');
    } finally {
      if (mounted) setState(() => _avatarBusy = false);
    }
  }

  void _showSettings() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => const _SettingsSheet(),
    );
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
      _ProfileScreen(
        profile: profile,
        identity: widget.identity,
        network: _network,
        avatarBusy: _avatarBusy,
        onChangePhoto: _pickProfilePhoto,
        onSettings: _showSettings,
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

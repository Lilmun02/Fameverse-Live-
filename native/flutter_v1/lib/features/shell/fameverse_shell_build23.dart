import 'dart:async';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/fameverse_backend.dart';
import '../../data/fameverse_beta_backend.dart';
import '../../data/fameverse_creator_backend.dart';
import '../../data/fameverse_live_backend.dart';
import '../../data/fameverse_story_backend.dart';
import '../live/livekit_live_screen.dart';
import '../live/native_camera_screen.dart';
import '../profile/creator_studio_build23.dart';
import '../profile/fameverse_edit_profile_screen.dart';
import '../profile/fameverse_policy_screen.dart';
import '../profile/fameverse_public_profile_screen.dart';
import '../profile/first_verse_beta_screen.dart';
import '../profile/native_profile_build23.dart';
import '../profile/owner_control_center_build23.dart';
import '../stories/creator_stories_screen.dart';
import 'fameverse_discover_screen.dart';
import 'build23_shell_account_service.dart';
import 'fameverse_home_build23.dart';

part 'fameverse_shell_build23_view.part.dart';

class FameverseBuild23Shell extends StatefulWidget {
  const FameverseBuild23Shell({
    required this.backend,
    required this.liveBackend,
    required this.identity,
    super.key,
  });

  final FameverseBackend backend;
  final FameverseLiveBackend liveBackend;
  final FvIdentity identity;

  @override
  State<FameverseBuild23Shell> createState() => _FameverseBuild23ShellState();
}

class _FameverseBuild23ShellState extends State<FameverseBuild23Shell> {
  static const _emptyNetwork = FvFollowNetwork(
    followers: [],
    following: [],
    followerIds: {},
    followingIds: {},
  );

  SupabaseFameverseBetaBackend? _betaBackend;
  SupabaseFameverseStoryBackend? _storyBackend;
  SupabaseFameverseCreatorBackend? _creatorBackend;
  late final FvBuild23ShellAccountService _accountService;

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
  List<FvCreatorStory> _stories = const [];
  FvBetaProgramStatus _betaStatus = FvBetaProgramStatus.notEnrolled;

  bool get _isOwner => _accountRole == 'owner';

  @override
  void initState() {
    super.initState();
    _accountService = FvBuild23ShellAccountService(
      backend: widget.backend,
      identityId: widget.identity.id,
    );
    unawaited(_refreshAll());
    unawaited(_refreshBeta());
    unawaited(_refreshStories());
    unawaited(_refreshRole());
  }

  bool _ensureSupplementalBackends() {
    if (_betaBackend != null &&
        _storyBackend != null &&
        _creatorBackend != null) {
      return true;
    }
    try {
      final client = Supabase.instance.client;
      _betaBackend ??= SupabaseFameverseBetaBackend(client);
      _storyBackend ??= SupabaseFameverseStoryBackend(client);
      _creatorBackend ??= SupabaseFameverseCreatorBackend(client);
      return true;
    } catch (_) {
      // Tests and degraded startup can inject the core backend before the
      // global Supabase singleton exists. Supplemental features fail open.
      return false;
    }
  }

  Future<({FvProfile profile, String? role})?>
  _loadAuthoritativeAccount() => _accountService.load();

  Future<void> _refreshRole() async {
    try {
      final account = await _loadAuthoritativeAccount();
      if (!mounted || account == null) return;
      setState(() {
        _profile = account.profile;
        _accountRole = account.role;
      });
    } catch (_) {
      // Role decoration must never block the public product shell.
    }
  }

  Future<void> _refreshBeta() async {
    if (!_ensureSupplementalBackends()) return;
    final backend = _betaBackend!;
    try {
      final status = await backend.loadProgramStatus();
      if (!mounted) return;
      setState(() => _betaStatus = status);
      if (status.enrolled && _tab == 0) {
        await _recordBetaMission('browse_home');
      }
    } catch (_) {
      // Beta progress is best effort and cannot block ordinary Fameverse use.
    }
  }

  Future<void> _recordBetaMission(String missionKey) async {
    if (!_betaStatus.enrolled || !_ensureSupplementalBackends()) return;
    final backend = _betaBackend!;
    try {
      await backend.recordMission(missionKey);
      final status = await backend.loadProgramStatus();
      if (mounted) setState(() => _betaStatus = status);
    } catch (_) {}
  }

  Future<void> _refreshStories() async {
    if (!_ensureSupplementalBackends()) return;
    try {
      final stories = await _storyBackend!.listActiveStories();
      if (mounted) setState(() => _stories = stories);
    } catch (_) {
      // Stories are additive; a story refresh failure cannot blank Home.
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
        _loadAuthoritativeAccount(),
        widget.backend.loadFollowNetwork(widget.identity.id),
        widget.backend.listRecommendedCreators(
          excludeUserId: widget.identity.id,
        ),
        widget.backend.listActiveLiveRooms(excludeUserId: widget.identity.id),
      ]);
      if (!mounted) return;
      final account = results[0] as ({FvProfile profile, String? role})?;
      if (account == null || account.profile.id != widget.identity.id) {
        throw StateError('current-account-mismatch');
      }
      setState(() {
        _profile = account.profile;
        _accountRole = account.role;
        _network = results[1] as FvFollowNetwork;
        _creators = results[2] as List<FvCreator>;
        _rooms = results[3] as List<FvLiveRoom>;
        _loading = false;
      });
      unawaited(_refreshStories());
      unawaited(_refreshRole());
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

  void _openPersonalCreatorStudio(FvProfile profile) {
    if (!_ensureSupplementalBackends()) {
      _message('Creator Studio is reconnecting.');
      return;
    }
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (context) => Build23CreatorStudioScreen(
          backend: _creatorBackend!,
          identity: widget.identity,
          profile: profile,
          isOwner: _isOwner,
        ),
      ),
    );
  }

  Future<void> _openCreatorStudio(FvProfile profile) async {
    if (!_ensureSupplementalBackends()) {
      _message('Creator Studio is reconnecting.');
      return;
    }

    final account = await _loadAuthoritativeAccount();
    if (!mounted) return;
    if (account == null || account.profile.id != widget.identity.id) {
      _message('Your account session changed. Refreshing Fameverse.');
      await _refreshAll();
      return;
    }

    setState(() {
      _profile = account.profile;
      _accountRole = account.role;
    });
    final currentProfile = account.profile;

    if (account.role == 'owner') {
      Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (context) => Build23OwnerControlCenterScreen(
            onOpenCreatorStudio: () =>
                _openPersonalCreatorStudio(currentProfile),
          ),
        ),
      );
      return;
    }
    _openPersonalCreatorStudio(currentProfile);
  }

  Future<void> _openStories(FvProfile profile) async {
    if (!_ensureSupplementalBackends()) {
      _message('Stories are reconnecting.');
      return;
    }
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (context) => CreatorStoriesScreen(
          backend: _storyBackend!,
          identity: widget.identity,
          profile: profile,
        ),
      ),
    );
    await _refreshStories();
    await _refreshBeta();
  }

  Future<void> _openFirstVerse() async {
    if (!_betaStatus.enrolled || !_ensureSupplementalBackends()) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (context) => FirstVerseBetaScreen(backend: _betaBackend!),
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
      unawaited(_refreshStories());
    } else if (value == 1) {
      unawaited(_recordBetaMission('browse_discover'));
    } else if (value == 3) {
      unawaited(_refreshBeta());
      unawaited(_refreshRole());
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

    return _Build23ShellView(
      tab: _tab,
      profile: profile,
      identity: widget.identity,
      backend: widget.backend,
      liveBackend: widget.liveBackend,
      network: _network,
      creators: _creators,
      rooms: _rooms,
      stories: _stories,
      loading: _loading,
      error: _error,
      isOwner: _isOwner,
      betaStatus: _betaStatus,
      avatarBusy: _avatarBusy,
      followBusy: _followBusy,
      onRefresh: _refreshAll,
      onSetTab: _setTab,
      onOpenStories: () => unawaited(_openStories(profile)),
      onRoomSelected: (room) => unawaited(_openRoom(room, profile)),
      onToggleFollow: _toggleFollow,
      onCreatorSelected: _openPublicProfile,
      onChangePhoto: _pickProfilePhoto,
      onEdit: () => _openEdit(profile),
      onCreatorStudio: () => unawaited(_openCreatorStudio(profile)),
      onFirstVerse: _betaStatus.enrolled ? _openFirstVerse : null,
      onPolicies: _openPolicies,
      onSignOut: widget.backend.signOut,
    );
  }
}

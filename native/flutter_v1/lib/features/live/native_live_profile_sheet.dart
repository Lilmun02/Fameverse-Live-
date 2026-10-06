import 'dart:async';

import 'package:flutter/material.dart';

import '../../data/fameverse_backend.dart';
import '../../data/fameverse_live_backend.dart';
import '../badges/gifter_badge_system.dart';
import '../badges/gifter_badge_widgets.dart';
import 'native_live_components.dart';

Future<void> showNativeLiveProfileSheet({
  required BuildContext context,
  required FameverseLiveBackend liveBackend,
  required FvIdentity identity,
  required String roomId,
  required FvProfile profile,
  FameverseBackend? backend,
  ValueChanged<bool>? onFollowingChanged,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => NativeLiveProfileSheet(
      liveBackend: liveBackend,
      backend: backend,
      identity: identity,
      roomId: roomId,
      profile: profile,
      onFollowingChanged: onFollowingChanged,
    ),
  );
}

class NativeLiveProfileSheet extends StatefulWidget {
  const NativeLiveProfileSheet({
    required this.liveBackend,
    required this.identity,
    required this.roomId,
    required this.profile,
    this.backend,
    this.onFollowingChanged,
    super.key,
  });

  final FameverseLiveBackend liveBackend;
  final FameverseBackend? backend;
  final FvIdentity identity;
  final String roomId;
  final FvProfile profile;
  final ValueChanged<bool>? onFollowingChanged;

  @override
  State<NativeLiveProfileSheet> createState() => _NativeLiveProfileSheetState();
}

class _NativeLiveProfileSheetState extends State<NativeLiveProfileSheet> {
  bool _loading = true;
  bool _followBusy = false;
  String? _error;
  FvViewerIdentityStats? _stats;
  FvFollowNetwork? _viewerNetwork;
  FvFollowNetwork? _targetNetwork;

  bool get _isSelf => widget.identity.id == widget.profile.id;

  bool get _isFollowing =>
      _viewerNetwork?.followingIds.contains(widget.profile.id) ?? false;

  bool get _isFollower =>
      _viewerNetwork?.followerIds.contains(widget.profile.id) ?? false;

  String get _relationshipLabel {
    if (_isFollowing && _isFollower) return 'Friends';
    if (_isFollowing) return 'Following';
    if (_isFollower) return 'Follow Back';
    return 'Follow';
  }

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    try {
      final statsFuture = widget.liveBackend.loadViewerIdentityStats(
        roomId: widget.roomId,
        userIds: <String>[widget.profile.id],
      );
      final backend = widget.backend;
      final viewerNetworkFuture = backend == null
          ? Future<FvFollowNetwork?>.value(null)
          : backend.loadFollowNetwork(widget.identity.id);
      final targetNetworkFuture = backend == null
          ? Future<FvFollowNetwork?>.value(null)
          : backend.loadFollowNetwork(widget.profile.id);
      final results = await Future.wait<dynamic>(<Future<dynamic>>[
        statsFuture,
        viewerNetworkFuture,
        targetNetworkFuture,
      ]);
      if (!mounted) return;
      final stats = (results[0] as List<FvViewerIdentityStats>);
      setState(() {
        _stats = stats.isEmpty ? null : stats.first;
        _viewerNetwork = results[1] as FvFollowNetwork?;
        _targetNetwork = results[2] as FvFollowNetwork?;
        _loading = false;
        _error = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Live profile details could not refresh right now.';
      });
    }
  }

  Future<void> _toggleFollow() async {
    final backend = widget.backend;
    if (_isSelf || backend == null || _followBusy) return;
    final next = !_isFollowing;
    setState(() => _followBusy = true);
    try {
      await backend.setFollowing(
        userId: widget.identity.id,
        targetId: widget.profile.id,
        following: next,
      );
      final network = await backend.loadFollowNetwork(widget.identity.id);
      if (!mounted) return;
      setState(() => _viewerNetwork = network);
      widget.onFollowingChanged?.call(
        network.followingIds.contains(widget.profile.id),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(content: Text('Follow state could not update.')),
          );
      }
    } finally {
      if (mounted) setState(() => _followBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final stats = _stats;
    final totalCoinsSent = stats?.totalCoinsSent ?? 0;
    final privileged = fvIsPrivilegedIdentityRole(stats?.accountRole);

    return SafeArea(
      child: Container(
        key: const Key('native-live-profile-sheet'),
        margin: const EdgeInsets.fromLTRB(10, 48, 10, 8),
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
        decoration: BoxDecoration(
          color: const Color(0xFF130D18),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: const Color(0xFF4A3456)),
          boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 28)],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 18),
              NativeProfileAvatar(profile: widget.profile, radius: 46),
              const SizedBox(height: 12),
              Text(
                widget.profile.displayName,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                widget.profile.handle,
                style: const TextStyle(
                  color: Color(0xFFAFA2B5),
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (widget.profile.bio.trim().isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  widget.profile.bio.trim(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFFD7CEDA),
                    height: 1.35,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 18),
                  child: CircularProgressIndicator(),
                )
              else if (_error != null)
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFFB6A9BC)),
                )
              else ...[
                if (totalCoinsSent > 0 && !privileged) ...[
                  FvGifterBadge(
                    totalCoinsSent: totalCoinsSent,
                    size: FvGifterBadgeSize.small,
                  ),
                  const SizedBox(height: 12),
                ],
                Row(
                  children: [
                    Expanded(
                      child: _MiniStat(
                        label: 'Gift coins',
                        value: '${stats?.totalCoinsSent ?? 0}',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _MiniStat(
                        label: 'Live gifts',
                        value: '${stats?.roomGiftCount ?? 0}',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _MiniStat(
                        label: 'Fame taps',
                        value: '${stats?.roomFameTaps ?? 0}',
                      ),
                    ),
                  ],
                ),
                if (_targetNetwork != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _MiniStat(
                          label: 'Followers',
                          value: '${_targetNetwork!.followers.length}',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _MiniStat(
                          label: 'Following',
                          value: '${_targetNetwork!.following.length}',
                        ),
                      ),
                    ],
                  ),
                ],
              ],
              if (!_isSelf && widget.backend != null) ...[
                const SizedBox(height: 16),
                FilledButton(
                  key: const Key('native-live-profile-follow-button'),
                  onPressed: _followBusy ? null : _toggleFollow,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    backgroundColor: _isFollowing
                        ? const Color(0xFF33243B)
                        : const Color(0xFF7A35C6),
                  ),
                  child: Text(_followBusy ? '…' : _relationshipLabel),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1B1420),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Color(0xFF9F92A4), fontSize: 9),
          ),
        ],
      ),
    );
  }
}

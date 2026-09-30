import 'dart:async';

import 'package:flutter/material.dart';

import '../../data/fameverse_backend.dart';
import '../../data/fameverse_live_backend.dart';
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
  State<NativeLiveProfileSheet> createState() =>
      _NativeLiveProfileSheetState();
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
    final badge = fvNativeGifterBadgeFor(
      level: stats?.gifterLevel ?? 1,
      totalCoinsSent: stats?.totalCoinsSent ?? 0,
    );
    final progress = fvNativeGifterProgress(
      level: stats?.gifterLevel ?? 1,
      totalCoinsSent: stats?.totalCoinsSent ?? 0,
    );

    return SafeArea(
      child: Container(
        key: const Key('native-live-profile-sheet'),
        margin: const EdgeInsets.fromLTRB(10, 48, 10, 8),
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
        decoration: BoxDecoration(
          color: const Color(0xFF130D18),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: const Color(0xFF4A3456)),
          boxShadow: const [
            BoxShadow(color: Colors.black54, blurRadius: 28),
          ],
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
                if (badge != null)
                  _GifterBadgeCard(
                    badge: badge,
                    level: stats?.gifterLevel ?? 1,
                  ),
                const SizedBox(height: 12),
                _GifterProgressCard(
                  level: stats?.gifterLevel ?? 1,
                  totalCoinsSent: stats?.totalCoinsSent ?? 0,
                  progress: progress,
                ),
                const SizedBox(height: 12),
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

class FvNativeGifterBadgeTier {
  const FvNativeGifterBadgeTier({
    required this.id,
    required this.label,
    required this.icon,
    required this.minLevel,
    required this.maxLevel,
  });

  final String id;
  final String label;
  final String icon;
  final int minLevel;
  final int maxLevel;
}

const fvNativeGifterBadgeTiers = <FvNativeGifterBadgeTier>[
  FvNativeGifterBadgeTier(
    id: 'spark',
    label: 'Spark Gifter',
    icon: '✦',
    minLevel: 1,
    maxLevel: 4,
  ),
  FvNativeGifterBadgeTier(
    id: 'bronze',
    label: 'Bronze Gifter',
    icon: '◆',
    minLevel: 5,
    maxLevel: 9,
  ),
  FvNativeGifterBadgeTier(
    id: 'silver',
    label: 'Silver Gifter',
    icon: '✧',
    minLevel: 10,
    maxLevel: 19,
  ),
  FvNativeGifterBadgeTier(
    id: 'gold',
    label: 'Gold Gifter',
    icon: '★',
    minLevel: 20,
    maxLevel: 29,
  ),
  FvNativeGifterBadgeTier(
    id: 'platinum',
    label: 'Platinum Gifter',
    icon: '⬢',
    minLevel: 30,
    maxLevel: 49,
  ),
  FvNativeGifterBadgeTier(
    id: 'diamond',
    label: 'Diamond Gifter',
    icon: '◇',
    minLevel: 50,
    maxLevel: 69,
  ),
  FvNativeGifterBadgeTier(
    id: 'royal',
    label: 'Royal Gifter',
    icon: '♛',
    minLevel: 70,
    maxLevel: 84,
  ),
  FvNativeGifterBadgeTier(
    id: 'legendary',
    label: 'Legendary Gifter',
    icon: '✪',
    minLevel: 85,
    maxLevel: 98,
  ),
  FvNativeGifterBadgeTier(
    id: 'fame-icon',
    label: 'Fame Icon',
    icon: '♕',
    minLevel: 99,
    maxLevel: 99,
  ),
];

FvNativeGifterBadgeTier? fvNativeGifterBadgeFor({
  required int level,
  required int totalCoinsSent,
}) {
  if (totalCoinsSent <= 0) return null;
  final normalized = level.clamp(1, 99);
  for (final tier in fvNativeGifterBadgeTiers) {
    if (normalized >= tier.minLevel && normalized <= tier.maxLevel) {
      return tier;
    }
  }
  return fvNativeGifterBadgeTiers.first;
}

class FvNativeGifterProgress {
  const FvNativeGifterProgress({
    required this.progress,
    required this.coinsToNext,
    required this.nextLevel,
    required this.isMaxLevel,
  });

  final double progress;
  final int coinsToNext;
  final int? nextLevel;
  final bool isMaxLevel;
}

const _gifterLevelThresholds = <int>[
  0,
  100,
  250,
  500,
  1000,
  2000,
  3500,
  5000,
  7500,
  10000,
  15000,
  22500,
  32500,
  45000,
  60000,
  72500,
  87500,
  105000,
  125000,
  150000,
  170000,
  190000,
  215000,
  245000,
  275000,
  310000,
  350000,
  395000,
  445000,
  500000,
  540000,
  585000,
  635000,
  690000,
  750000,
  810000,
  880000,
  950000,
  1025000,
  1125000,
  1200000,
  1325000,
  1425000,
  1550000,
  1675000,
  1800000,
  1975000,
  2125000,
  2300000,
  2500000,
  2650000,
  2800000,
  2950000,
  3125000,
  3300000,
  3475000,
  3675000,
  3900000,
  4125000,
  4350000,
  4600000,
  4875000,
  5150000,
  5425000,
  5750000,
  6075000,
  6425000,
  6775000,
  7175000,
  7575000,
  8000000,
  8475000,
  8950000,
  9450000,
  10000000,
  10700000,
  11400000,
  12200000,
  13100000,
  14000000,
  15000000,
  16000000,
  17100000,
  18300000,
  19600000,
  20900000,
  22400000,
  23900000,
  25600000,
  27300000,
  29200000,
  31300000,
  33400000,
  35800000,
  38200000,
  40900000,
  43700000,
  46800000,
  50000000,
];

FvNativeGifterProgress fvNativeGifterProgress({
  required int level,
  required int totalCoinsSent,
}) {
  final normalizedLevel = level.clamp(1, 99);
  final normalizedCoins = totalCoinsSent < 0 ? 0 : totalCoinsSent;
  final currentRequirement = _gifterLevelThresholds[normalizedLevel - 1];
  if (normalizedLevel >= 99) {
    return const FvNativeGifterProgress(
      progress: 1,
      coinsToNext: 0,
      nextLevel: null,
      isMaxLevel: true,
    );
  }
  final nextRequirement = _gifterLevelThresholds[normalizedLevel];
  final range = nextRequirement - currentRequirement;
  final rawProgress = range <= 0
      ? 1.0
      : (normalizedCoins - currentRequirement) / range;
  return FvNativeGifterProgress(
    progress: rawProgress.clamp(0.0, 1.0),
    coinsToNext: (nextRequirement - normalizedCoins).clamp(0, nextRequirement),
    nextLevel: normalizedLevel + 1,
    isMaxLevel: false,
  );
}

class _GifterBadgeCard extends StatelessWidget {
  const _GifterBadgeCard({required this.badge, required this.level});

  final FvNativeGifterBadgeTier badge;
  final int level;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: Key('native-gifter-badge-${badge.id}'),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Color(0xFF4E2767), Color(0xFF24152E)],
        ),
        border: Border.all(color: const Color(0xFF9B61C4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(badge.icon, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                badge.label,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              Text(
                'Lv. $level',
                style: const TextStyle(
                  color: Color(0xFFD3C4DB),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GifterProgressCard extends StatelessWidget {
  const _GifterProgressCard({
    required this.level,
    required this.totalCoinsSent,
    required this.progress,
  });

  final int level;
  final int totalCoinsSent;
  final FvNativeGifterProgress progress;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('native-gifter-progress'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A121F),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF3D2B45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Gifter Lv. $level',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              const Spacer(),
              Text(
                '$totalCoinsSent coins',
                style: const TextStyle(
                  color: Color(0xFFB7A9BE),
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: progress.progress,
            minHeight: 7,
            borderRadius: BorderRadius.circular(999),
          ),
          const SizedBox(height: 7),
          Text(
            progress.isMaxLevel
                ? 'Max gifter level reached'
                : '${progress.coinsToNext} coins to Lv. ${progress.nextLevel}',
            style: const TextStyle(
              color: Color(0xFFA99BAC),
              fontSize: 11,
            ),
          ),
        ],
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
            style: const TextStyle(
              color: Color(0xFF9F92A4),
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }
}

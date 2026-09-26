import 'package:flutter/material.dart';

import '../../data/fameverse_backend.dart';

/// Fameverse Home is the algorithmic, streaming-first surface.
///
/// Product contract:
/// - Home is not a friends/followers directory.
/// - Active Live rooms lead the experience.
/// - Relationship signals, FameTaps, and rising-creator fairness rank V1.
/// - Discover remains the intentional search/exploration destination.
class FameverseHomeScreen extends StatefulWidget {
  const FameverseHomeScreen({
    required this.profile,
    required this.network,
    required this.creators,
    required this.rooms,
    required this.loading,
    required this.error,
    required this.onRefresh,
    required this.onOpenProfile,
    required this.onOpenDiscover,
    required this.onRoomSelected,
    required this.onToggleFollow,
    required this.followBusy,
    super.key,
  });

  final FvProfile profile;
  final FvFollowNetwork network;
  final List<FvCreator> creators;
  final List<FvLiveRoom> rooms;
  final bool loading;
  final String? error;
  final Future<void> Function() onRefresh;
  final VoidCallback onOpenProfile;
  final VoidCallback onOpenDiscover;
  final ValueChanged<FvLiveRoom> onRoomSelected;
  final ValueChanged<String> onToggleFollow;
  final bool followBusy;

  @override
  State<FameverseHomeScreen> createState() => _FameverseHomeScreenState();
}

enum _HomeLane { forYou, following, rising }

class _FameverseHomeScreenState extends State<FameverseHomeScreen> {
  _HomeLane _lane = _HomeLane.forYou;

  int _followersFor(String userId) {
    for (final creator in widget.creators) {
      if (creator.profile.id == userId) return creator.followerCount;
    }
    return 0;
  }

  int _forYouScore(FvLiveRoom room) {
    var score = room.fameTaps.clamp(0, 120);
    if (widget.network.followingIds.contains(room.hostUserId)) score += 90;
    if (widget.network.followerIds.contains(room.hostUserId)) score += 25;
    if (widget.network.followingIds.contains(room.hostUserId) &&
        widget.network.followerIds.contains(room.hostUserId)) {
      score += 35;
    }
    final followers = _followersFor(room.hostUserId);
    if (followers < 1000) score += 18;
    return score;
  }

  int _risingScore(FvLiveRoom room) {
    final followers = _followersFor(room.hostUserId);
    final discoveryBoost = followers == 0
        ? 70
        : followers < 500
        ? 55
        : followers < 2500
        ? 35
        : followers < 10000
        ? 16
        : 0;
    return discoveryBoost + room.fameTaps.clamp(0, 160);
  }

  List<FvLiveRoom> get _rankedRooms {
    final rooms = widget.rooms.toList();
    if (_lane == _HomeLane.following) {
      rooms.removeWhere(
        (room) => !widget.network.followingIds.contains(room.hostUserId),
      );
      rooms.sort((a, b) => _forYouScore(b).compareTo(_forYouScore(a)));
      return rooms;
    }
    if (_lane == _HomeLane.rising) {
      rooms.sort((a, b) => _risingScore(b).compareTo(_risingScore(a)));
      return rooms;
    }
    rooms.sort((a, b) => _forYouScore(b).compareTo(_forYouScore(a)));
    return rooms;
  }

  List<FvLiveRoom> get _liveNow {
    final rooms = widget.rooms.toList();
    rooms.sort((a, b) {
      final aFollowing = widget.network.followingIds.contains(a.hostUserId);
      final bFollowing = widget.network.followingIds.contains(b.hostUserId);
      if (aFollowing != bFollowing) return bFollowing ? 1 : -1;
      return b.fameTaps.compareTo(a.fameTaps);
    });
    return rooms;
  }

  String _reasonFor(FvLiveRoom room) {
    final friend =
        widget.network.followingIds.contains(room.hostUserId) &&
        widget.network.followerIds.contains(room.hostUserId);
    if (friend) return 'Friend is live';
    if (widget.network.followingIds.contains(room.hostUserId)) {
      return 'You follow this creator';
    }
    if (_lane == _HomeLane.rising) return 'Rising on Fameverse';
    if (room.fameTaps >= 25) return 'Getting momentum';
    return 'Recommended for you';
  }

  @override
  Widget build(BuildContext context) {
    final rankedRooms = _rankedRooms;
    final suggestedCreators = widget.creators.take(6).toList();

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: widget.onRefresh,
        child: ListView(
          key: const Key('fameverse-algorithmic-home'),
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 116),
          children: [
            _HomeTopBar(
              profile: widget.profile,
              onOpenProfile: widget.onOpenProfile,
            ),
            const SizedBox(height: 24),
            _SectionHeader(
              eyebrow: 'LIVE NOW',
              title: 'Happening right now',
              trailing: widget.rooms.isEmpty
                  ? null
                  : '${widget.rooms.length} live',
            ),
            const SizedBox(height: 12),
            if (widget.loading && widget.rooms.isEmpty)
              const _HomeLoadingCard()
            else if (widget.error != null && widget.rooms.isEmpty)
              _HomeEmptyCard(
                icon: Icons.wifi_off_rounded,
                title: 'Live is reconnecting',
                body: widget.error!,
              )
            else if (_liveNow.isEmpty)
              const _HomeEmptyCard(
                icon: Icons.live_tv_outlined,
                title: 'Nobody is live yet',
                body:
                    'When a Fameverse creator goes live, they will appear here first.',
              )
            else
              SizedBox(
                height: 104,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _liveNow.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 14),
                  itemBuilder: (context, index) {
                    final room = _liveNow[index];
                    return _LiveAvatar(
                      room: room,
                      following: widget.network.followingIds.contains(
                        room.hostUserId,
                      ),
                      onTap: () => widget.onRoomSelected(room),
                    );
                  },
                ),
              ),
            const SizedBox(height: 28),
            const Text(
              'Your Home',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 5),
            const Text(
              'Live recommendations change with your connections and what is gaining momentum.',
              style: TextStyle(
                color: Color(0xFFA89CAB),
                fontSize: 13,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 14),
            _HomeLanePicker(
              lane: _lane,
              onChanged: (lane) => setState(() => _lane = lane),
            ),
            const SizedBox(height: 18),
            if (rankedRooms.isEmpty)
              _HomeEmptyCard(
                icon: _lane == _HomeLane.following
                    ? Icons.favorite_border_rounded
                    : Icons.auto_awesome_rounded,
                title: _lane == _HomeLane.following
                    ? 'Nobody you follow is live'
                    : 'No live recommendations yet',
                body: _lane == _HomeLane.following
                    ? 'Try For You or Rising while you wait.'
                    : 'Explore creators and follow people you want to see here.',
                actionLabel: 'Explore creators',
                onAction: widget.onOpenDiscover,
              )
            else
              ...rankedRooms
                  .take(8)
                  .map(
                    (room) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: _AlgorithmLiveCard(
                        room: room,
                        reason: _reasonFor(room),
                        following: widget.network.followingIds.contains(
                          room.hostUserId,
                        ),
                        onTap: () => widget.onRoomSelected(room),
                      ),
                    ),
                  ),
            const SizedBox(height: 16),
            _SectionHeader(
              eyebrow: 'DISCOVER PEOPLE',
              title: 'Creators to know',
              actionLabel: 'See more',
              onAction: widget.onOpenDiscover,
            ),
            const SizedBox(height: 12),
            if (suggestedCreators.isEmpty)
              const _HomeEmptyCard(
                icon: Icons.people_outline_rounded,
                title: 'Creator suggestions are warming up',
                body: 'New recommendations will show here as Fameverse grows.',
              )
            else
              SizedBox(
                height: 176,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: suggestedCreators.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    final creator = suggestedCreators[index];
                    final following = widget.network.followingIds.contains(
                      creator.profile.id,
                    );
                    return _SuggestedCreatorCard(
                      creator: creator,
                      following: following,
                      busy: widget.followBusy,
                      onFollow: () => widget.onToggleFollow(creator.profile.id),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _HomeTopBar extends StatelessWidget {
  const _HomeTopBar({required this.profile, required this.onOpenProfile});

  final FvProfile profile;
  final VoidCallback onOpenProfile;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFB663FF), Color(0xFF542083)],
            ),
            boxShadow: [BoxShadow(color: Color(0x665E1B9B), blurRadius: 14)],
          ),
          child: const Center(
            child: Text(
              'F',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'FAMEVERSE',
                key: Key('native-product-wordmark'),
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.7,
                ),
              ),
              Text(
                'LIVE • FOR YOU',
                style: TextStyle(
                  color: Color(0xFFB67BDE),
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.25,
                ),
              ),
            ],
          ),
        ),
        InkWell(
          onTap: onOpenProfile,
          customBorder: const CircleBorder(),
          child: _Avatar(profile: profile, radius: 21),
        ),
      ],
    );
  }
}

class _HomeLanePicker extends StatelessWidget {
  const _HomeLanePicker({required this.lane, required this.onChanged});

  final _HomeLane lane;
  final ValueChanged<_HomeLane> onChanged;

  @override
  Widget build(BuildContext context) {
    final lanes = <(_HomeLane, String)>[
      (_HomeLane.forYou, 'For You'),
      (_HomeLane.following, 'Following'),
      (_HomeLane.rising, 'Rising'),
    ];
    return Row(
      children: lanes.map((item) {
        final selected = lane == item.$1;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: item.$1 == _HomeLane.rising ? 0 : 8,
            ),
            child: InkWell(
              key: Key(
                'home-lane-${item.$2.toLowerCase().replaceAll(' ', '-')}',
              ),
              onTap: () => onChanged(item.$1),
              borderRadius: BorderRadius.circular(999),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: selected
                      ? const Color(0xFF6E34B8)
                      : const Color(0xFF17121B),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: selected
                        ? const Color(0xFFB76CFF)
                        : const Color(0xFF32263A),
                  ),
                ),
                child: Text(
                  item.$2,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.eyebrow,
    required this.title,
    this.trailing,
    this.actionLabel,
    this.onAction,
  });

  final String eyebrow;
  final String title;
  final String? trailing;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                eyebrow,
                style: const TextStyle(
                  color: Color(0xFFBB78F2),
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.4,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
        if (trailing != null)
          Text(
            trailing!,
            style: const TextStyle(color: Color(0xFF978C9A), fontSize: 12),
          ),
        if (actionLabel != null && onAction != null)
          TextButton(onPressed: onAction, child: Text(actionLabel!)),
      ],
    );
  }
}

class _LiveAvatar extends StatelessWidget {
  const _LiveAvatar({
    required this.room,
    required this.following,
    required this.onTap,
  });

  final FvLiveRoom room;
  final bool following;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Column(
          children: [
            Container(
              width: 62,
              height: 62,
              padding: const EdgeInsets.all(2.5),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: following
                      ? const [Color(0xFFED4B7D), Color(0xFF934CFF)]
                      : const [Color(0xFFB45EFF), Color(0xFF4C1F75)],
                ),
                boxShadow: const [
                  BoxShadow(color: Color(0x665F258E), blurRadius: 12),
                ],
              ),
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: Colors.black,
                  shape: BoxShape.circle,
                ),
                child: _Avatar(profile: room.host, radius: 26),
              ),
            ),
            const SizedBox(height: 5),
            Text(
              room.host.displayName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }
}

class _AlgorithmLiveCard extends StatelessWidget {
  const _AlgorithmLiveCard({
    required this.room,
    required this.reason,
    required this.following,
    required this.onTap,
  });

  final FvLiveRoom room;
  final String reason;
  final bool following;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final avatar = room.host.avatarUrl?.trim();
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: Key('home-live-${room.id}'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          height: 226,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFF3E2850)),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF2D143C), Color(0xFF100B14)],
            ),
            image: avatar == null || avatar.isEmpty
                ? null
                : DecorationImage(
                    image: NetworkImage(avatar),
                    fit: BoxFit.cover,
                    opacity: .32,
                  ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x332B0B40),
                blurRadius: 24,
                offset: Offset(0, 12),
              ),
            ],
          ),
          child: Stack(
            children: [
              const Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(24)),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0x22000000), Color(0xE8000000)],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 14,
                top: 14,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE82D58),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'LIVE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: .8,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xB5150D1B),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: const Color(0xFF634177)),
                      ),
                      child: Text(
                        'F ${_compact(room.fameTaps)}',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                left: 14,
                right: 14,
                bottom: 14,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _Avatar(profile: room.host, radius: 24),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            room.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 18,
                              height: 1.1,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  room.host.displayName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 5),
                              if (following)
                                const Icon(
                                  Icons.favorite_rounded,
                                  size: 12,
                                  color: Color(0xFFC47BFF),
                                ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            reason,
                            style: const TextStyle(
                              color: Color(0xFFBCAFC2),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF793BC0),
                      ),
                      child: const Icon(Icons.play_arrow_rounded),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SuggestedCreatorCard extends StatelessWidget {
  const _SuggestedCreatorCard({
    required this.creator,
    required this.following,
    required this.busy,
    required this.onFollow,
  });

  final FvCreator creator;
  final bool following;
  final bool busy;
  final VoidCallback onFollow;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 142,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFF151018),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF33243D)),
      ),
      child: Column(
        children: [
          _Avatar(profile: creator.profile, radius: 29),
          const SizedBox(height: 9),
          Text(
            creator.profile.displayName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 2),
          Text(
            creator.profile.handle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Color(0xFF9E92A3), fontSize: 11),
          ),
          const SizedBox(height: 5),
          Text(
            '${_compact(creator.followerCount)} followers',
            style: const TextStyle(color: Color(0xFFBFAFC7), fontSize: 10),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: FilledButton.tonal(
              onPressed: busy ? null : onFollow,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
              child: Text(following ? 'Following' : 'Follow'),
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeLoadingCard extends StatelessWidget {
  const _HomeLoadingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 96,
      decoration: BoxDecoration(
        color: const Color(0xFF151018),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF33243D)),
      ),
      child: const Center(child: CircularProgressIndicator()),
    );
  }
}

class _HomeEmptyCard extends StatelessWidget {
  const _HomeEmptyCard({
    required this.icon,
    required this.title,
    required this.body,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String body;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF151018),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF33243D)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFF2A1834),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: const Color(0xFFC686FF)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: const TextStyle(
                    color: Color(0xFFA89CAB),
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
                if (actionLabel != null && onAction != null) ...[
                  const SizedBox(height: 8),
                  TextButton(onPressed: onAction, child: Text(actionLabel!)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.profile, required this.radius});

  final FvProfile profile;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final url = profile.avatarUrl?.trim();
    return CircleAvatar(
      radius: radius,
      backgroundColor: const Color(0xFF3A2148),
      foregroundImage: url == null || url.isEmpty ? null : NetworkImage(url),
      child: Text(
        profile.initial,
        style: const TextStyle(fontWeight: FontWeight.w900),
      ),
    );
  }
}

String _compact(int value) {
  if (value >= 1000000) {
    final text = (value / 1000000).toStringAsFixed(value >= 10000000 ? 0 : 1);
    return '${text.replaceAll('.0', '')}M';
  }
  if (value >= 1000) {
    final text = (value / 1000).toStringAsFixed(value >= 10000 ? 0 : 1);
    return '${text.replaceAll('.0', '')}K';
  }
  return '$value';
}

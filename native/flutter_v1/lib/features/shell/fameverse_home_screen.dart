import 'package:flutter/material.dart';

import '../../data/fameverse_backend.dart';
part 'fameverse_home_controls.part.dart';
part 'fameverse_home_results.part.dart';


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
    required this.onCreatorSelected,
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
  final ValueChanged<FvProfile> onCreatorSelected;
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
                      onOpen: () => widget.onCreatorSelected(creator.profile),
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

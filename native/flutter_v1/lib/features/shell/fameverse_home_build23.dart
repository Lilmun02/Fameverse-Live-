import 'package:flutter/material.dart';

import '../../data/fameverse_backend.dart';
import '../../data/fameverse_story_backend.dart';
part 'fameverse_home_build23_feed.part.dart';
part 'fameverse_home_build23_cards.part.dart';


class FameverseHomeBuild23Screen extends StatefulWidget {
  const FameverseHomeBuild23Screen({
    required this.profile,
    required this.network,
    required this.creators,
    required this.rooms,
    required this.stories,
    required this.loading,
    required this.error,
    required this.onRefresh,
    required this.onOpenProfile,
    required this.onOpenDiscover,
    required this.onOpenStories,
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
  final List<FvCreatorStory> stories;
  final bool loading;
  final String? error;
  final Future<void> Function() onRefresh;
  final VoidCallback onOpenProfile;
  final VoidCallback onOpenDiscover;
  final VoidCallback onOpenStories;
  final ValueChanged<FvLiveRoom> onRoomSelected;
  final ValueChanged<String> onToggleFollow;
  final ValueChanged<FvProfile> onCreatorSelected;
  final bool followBusy;

  @override
  State<FameverseHomeBuild23Screen> createState() =>
      _FameverseHomeBuild23ScreenState();
}

enum _FeedTab { live, stories }

enum _LiveLane { forYou, following, rising }

class _FameverseHomeBuild23ScreenState
    extends State<FameverseHomeBuild23Screen> {
  _FeedTab _feed = _FeedTab.live;
  _LiveLane _lane = _LiveLane.forYou;

  List<FvCreatorStory> get _storyGroups {
    final newestByCreator = <String, FvCreatorStory>{};
    for (final story in widget.stories) {
      final current = newestByCreator[story.creatorUserId];
      if (current == null) {
        newestByCreator[story.creatorUserId] = story;
        continue;
      }
      final currentTime =
          current.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final nextTime =
          story.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      if (nextTime.isAfter(currentTime)) {
        newestByCreator[story.creatorUserId] = story;
      }
    }
    final result = newestByCreator.values.toList();
    result.sort((a, b) {
      if (a.isMine != b.isMine) return a.isMine ? -1 : 1;
      if (a.viewedByMe != b.viewedByMe) return a.viewedByMe ? 1 : -1;
      final aTime = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bTime = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bTime.compareTo(aTime);
    });
    return result;
  }

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
    if (_followersFor(room.hostUserId) < 1000) score += 18;
    return score;
  }

  List<FvLiveRoom> get _rankedRooms {
    final rooms = widget.rooms.toList();
    if (_lane == _LiveLane.following) {
      rooms.removeWhere(
        (room) => !widget.network.followingIds.contains(room.hostUserId),
      );
    }
    if (_lane == _LiveLane.rising) {
      rooms.sort((a, b) {
        final aBoost = _followersFor(a.hostUserId) < 1000 ? 60 : 0;
        final bBoost = _followersFor(b.hostUserId) < 1000 ? 60 : 0;
        return (b.fameTaps + bBoost).compareTo(a.fameTaps + aBoost);
      });
    } else {
      rooms.sort((a, b) => _forYouScore(b).compareTo(_forYouScore(a)));
    }
    return rooms;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: widget.onRefresh,
        child: ListView(
          key: const Key('build23-home'),
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 116),
          children: [
            _TopBar(
              profile: widget.profile,
              onOpenProfile: widget.onOpenProfile,
            ),
            const SizedBox(height: 18),
            _FeedSwitch(
              selected: _feed,
              onChanged: (value) => setState(() => _feed = value),
            ),
            const SizedBox(height: 18),
            if (_feed == _FeedTab.live) ..._buildLiveFeed(),
            if (_feed == _FeedTab.stories) ..._buildStoryFeed(),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildLiveFeed() {
    final ranked = _rankedRooms;
    return [
      _StoryRail(
        profile: widget.profile,
        stories: _storyGroups,
        onOpenStories: widget.onOpenStories,
      ),
      const SizedBox(height: 26),
      _SectionHeader(
        eyebrow: 'LIVE NOW',
        title: 'Happening right now',
        trailing: widget.rooms.isEmpty ? null : '${widget.rooms.length} live',
      ),
      const SizedBox(height: 12),
      if (widget.loading && widget.rooms.isEmpty)
        const _InfoCard(
          icon: Icons.hourglass_top_rounded,
          title: 'Loading Live Feed',
          body: 'Checking who is live right now.',
        )
      else if (widget.error != null && widget.rooms.isEmpty)
        _InfoCard(
          icon: Icons.wifi_off_rounded,
          title: 'Live is reconnecting',
          body: widget.error!,
        )
      else if (widget.rooms.isEmpty)
        const _InfoCard(
          icon: Icons.live_tv_outlined,
          title: 'Nobody is live yet',
          body: 'Creators will appear here as soon as they go live.',
        )
      else
        SizedBox(
          height: 96,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: widget.rooms.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final room = widget.rooms[index];
              return _LiveBubble(
                room: room,
                onTap: () => widget.onRoomSelected(room),
              );
            },
          ),
        ),
      const SizedBox(height: 24),
      _LiveLanePicker(
        lane: _lane,
        onChanged: (lane) => setState(() => _lane = lane),
      ),
      const SizedBox(height: 14),
      if (ranked.isEmpty)
        _InfoCard(
          icon: Icons.auto_awesome_rounded,
          title: _lane == _LiveLane.following
              ? 'Nobody you follow is live'
              : 'No recommendations yet',
          body: 'Try another feed or discover more creators.',
        )
      else
        ...ranked
            .take(8)
            .map(
              (room) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _LiveCard(
                  room: room,
                  following: widget.network.followingIds.contains(
                    room.hostUserId,
                  ),
                  onTap: () => widget.onRoomSelected(room),
                ),
              ),
            ),
      const SizedBox(height: 14),
      _SectionHeader(
        eyebrow: 'DISCOVER PEOPLE',
        title: 'Creators to know',
        actionLabel: 'See more',
        onAction: widget.onOpenDiscover,
      ),
      const SizedBox(height: 12),
      if (widget.creators.isEmpty)
        const _InfoCard(
          icon: Icons.people_outline_rounded,
          title: 'Suggestions are warming up',
          body: 'Creator recommendations will show here as Fameverse grows.',
        )
      else
        SizedBox(
          height: 158,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: widget.creators.take(6).length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final creator = widget.creators[index];
              final following = widget.network.followingIds.contains(
                creator.profile.id,
              );
              return _CreatorCard(
                creator: creator,
                following: following,
                busy: widget.followBusy,
                onOpen: () => widget.onCreatorSelected(creator.profile),
                onFollow: () => widget.onToggleFollow(creator.profile.id),
              );
            },
          ),
        ),
    ];
  }

  List<Widget> _buildStoryFeed() {
    final stories = _storyGroups;
    return [
      Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'STORY FEED',
                  style: TextStyle(
                    color: Color(0xFFD08BFF),
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Stories from Fameverse',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
                ),
              ],
            ),
          ),
          FilledButton.icon(
            key: const Key('open-story-composer'),
            onPressed: widget.onOpenStories,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Story'),
          ),
        ],
      ),
      const SizedBox(height: 16),
      if (stories.isEmpty)
        _InfoCard(
          icon: Icons.auto_stories_outlined,
          title: 'No active Stories yet',
          body: 'Post your Story or check back when creators add one.',
          actionLabel: 'Open Stories',
          onAction: widget.onOpenStories,
        )
      else
        ...stories.map(
          (story) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _StoryFeedCard(story: story, onTap: widget.onOpenStories),
          ),
        ),
    ];
  }
}

import 'package:flutter/material.dart';

import '../../data/fameverse_backend.dart';
import '../../data/fameverse_story_backend.dart';

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

class _FeedSwitch extends StatelessWidget {
  const _FeedSwitch({required this.selected, required this.onChanged});

  final _FeedTab selected;
  final ValueChanged<_FeedTab> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('home-feed-switch'),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF151018),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF35263E)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _FeedButton(
              keyName: 'home-live-feed-tab',
              label: 'Live Feed',
              icon: Icons.live_tv_rounded,
              selected: selected == _FeedTab.live,
              onTap: () => onChanged(_FeedTab.live),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _FeedButton(
              keyName: 'home-story-feed-tab',
              label: 'Story Feed',
              icon: Icons.auto_stories_rounded,
              selected: selected == _FeedTab.stories,
              onTap: () => onChanged(_FeedTab.stories),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeedButton extends StatelessWidget {
  const _FeedButton({
    required this.keyName,
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String keyName;
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: Key(keyName),
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF6E34B8) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 17),
            const SizedBox(width: 7),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StoryRail extends StatelessWidget {
  const _StoryRail({
    required this.profile,
    required this.stories,
    required this.onOpenStories,
  });

  final FvProfile profile;
  final List<FvCreatorStory> stories;
  final VoidCallback onOpenStories;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'STORIES',
          style: TextStyle(
            color: Color(0xFFC47AFF),
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.4,
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 86,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _StoryBubble(
                label: 'Your Story',
                avatarUrl: profile.avatarUrl,
                initial: profile.initial,
                active: stories.any((story) => story.isMine),
                onTap: onOpenStories,
                addBadge: !stories.any((story) => story.isMine),
              ),
              ...stories
                  .where((story) => !story.isMine)
                  .take(10)
                  .map(
                    (story) => Padding(
                      padding: const EdgeInsets.only(left: 12),
                      child: _StoryBubble(
                        label: story.displayName,
                        avatarUrl: story.avatarUrl,
                        initial: story.displayName.isEmpty
                            ? 'F'
                            : story.displayName.substring(0, 1).toUpperCase(),
                        active: !story.viewedByMe,
                        onTap: onOpenStories,
                      ),
                    ),
                  ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StoryBubble extends StatelessWidget {
  const _StoryBubble({
    required this.label,
    required this.avatarUrl,
    required this.initial,
    required this.active,
    required this.onTap,
    this.addBadge = false,
  });

  final String label;
  final String? avatarUrl;
  final String initial;
  final bool active;
  final VoidCallback onTap;
  final bool addBadge;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: active
                          ? const [
                              Color(0xFFF05A86),
                              Color(0xFFB95EFF),
                              Color(0xFF604BFF),
                            ]
                          : const [Color(0xFF514755), Color(0xFF302A33)],
                    ),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black,
                    ),
                    child: ClipOval(
                      child: avatarUrl != null && avatarUrl!.trim().isNotEmpty
                          ? Image.network(
                              avatarUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _Initial(initial),
                            )
                          : _Initial(initial),
                    ),
                  ),
                ),
                if (addBadge)
                  const Positioned(
                    right: -1,
                    bottom: -1,
                    child: CircleAvatar(
                      radius: 9,
                      backgroundColor: Color(0xFF8A3DDD),
                      child: Icon(
                        Icons.add_rounded,
                        size: 13,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 5),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

class _StoryFeedCard extends StatelessWidget {
  const _StoryFeedCard({required this.story, required this.onTap});

  final FvCreatorStory story;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Ink(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: story.viewedByMe
                ? const Color(0xFF3B3340)
                : const Color(0xFF8B48C4),
          ),
          gradient: const LinearGradient(
            colors: [Color(0xFF241330), Color(0xFF110C15)],
          ),
        ),
        child: Row(
          children: [
            _StoryBubble(
              label: '',
              avatarUrl: story.avatarUrl,
              initial: story.displayName.isEmpty
                  ? 'F'
                  : story.displayName.substring(0, 1).toUpperCase(),
              active: !story.viewedByMe,
              onTap: onTap,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    story.isMine ? 'Your Story' : story.displayName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    story.caption.trim().isEmpty
                        ? (story.isVideo ? 'Short video Story' : 'Photo Story')
                        : story.caption,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFFB3A7B8),
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.profile, required this.onOpenProfile});

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
              colors: [Color(0xFFB663FF), Color(0xFF542083)],
            ),
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
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.7,
                ),
              ),
              Text(
                'LIVE + STORIES',
                style: TextStyle(
                  color: Color(0xFFB67BDE),
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
        InkWell(
          onTap: onOpenProfile,
          customBorder: const CircleBorder(),
          child: Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF342044),
            ),
            child: ClipOval(
              child:
                  profile.avatarUrl != null &&
                      profile.avatarUrl!.trim().isNotEmpty
                  ? Image.network(
                      profile.avatarUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _Initial(profile.initial),
                    )
                  : _Initial(profile.initial),
            ),
          ),
        ),
      ],
    );
  }
}

class _Initial extends StatelessWidget {
  const _Initial(this.value);
  final String value;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFF352044),
      child: Center(
        child: Text(value, style: const TextStyle(fontWeight: FontWeight.w900)),
      ),
    );
  }
}

class _LiveLanePicker extends StatelessWidget {
  const _LiveLanePicker({required this.lane, required this.onChanged});

  final _LiveLane lane;
  final ValueChanged<_LiveLane> onChanged;

  @override
  Widget build(BuildContext context) {
    final items = <(_LiveLane, String)>[
      (_LiveLane.forYou, 'For You'),
      (_LiveLane.following, 'Following'),
      (_LiveLane.rising, 'Rising'),
    ];
    return Row(
      children: items.map((item) {
        final selected = lane == item.$1;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: item.$1 == _LiveLane.rising ? 0 : 8,
            ),
            child: InkWell(
              onTap: () => onChanged(item.$1),
              borderRadius: BorderRadius.circular(999),
              child: Container(
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

class _LiveBubble extends StatelessWidget {
  const _LiveBubble({required this.room, required this.onTap});
  final FvLiveRoom room;
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
              width: 60,
              height: 60,
              padding: const EdgeInsets.all(3),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Color(0xFFF04D7B), Color(0xFF934CFF)],
                ),
              ),
              child: Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF221329),
                ),
                child: Center(
                  child: Text(
                    room.hostDisplayName.isEmpty
                        ? 'F'
                        : room.hostDisplayName.substring(0, 1).toUpperCase(),
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 5),
            Text(
              room.hostDisplayName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

class _LiveCard extends StatelessWidget {
  const _LiveCard({
    required this.room,
    required this.following,
    required this.onTap,
  });

  final FvLiveRoom room;
  final bool following;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Ink(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFF3F2D48)),
          color: const Color(0xFF151018),
        ),
        child: Row(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Color(0xFFE94F79), Color(0xFF8F49F5)],
                ),
              ),
              child: Center(
                child: Text(
                  room.hostDisplayName.isEmpty
                      ? 'F'
                      : room.hostDisplayName.substring(0, 1).toUpperCase(),
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    room.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${room.hostDisplayName} · ${room.fameTaps} FameTaps',
                    style: const TextStyle(
                      color: Color(0xFFA79BAA),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            if (following)
              const Icon(
                Icons.favorite_rounded,
                color: Color(0xFFC879FF),
                size: 18,
              ),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    );
  }
}

class _CreatorCard extends StatelessWidget {
  const _CreatorCard({
    required this.creator,
    required this.following,
    required this.busy,
    required this.onOpen,
    required this.onFollow,
  });

  final FvCreator creator;
  final bool following;
  final bool busy;
  final VoidCallback onOpen;
  final VoidCallback onFollow;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 142,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: const Color(0xFF151018),
          border: Border.all(color: const Color(0xFF362940)),
        ),
        child: Column(
          children: [
            GestureDetector(
              onTap: onOpen,
              child: CircleAvatar(
                radius: 28,
                backgroundColor: const Color(0xFF352044),
                child: Text(
                  creator.profile.initial,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              creator.profile.displayName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: busy ? null : onFollow,
                child: Text(following ? 'Following' : 'Follow'),
              ),
            ),
          ],
        ),
      ),
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

class _InfoCard extends StatelessWidget {
  const _InfoCard({
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
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF34283A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFFC47DFF)),
          const SizedBox(height: 10),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text(
            body,
            style: const TextStyle(color: Color(0xFFA99EAD), height: 1.35),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 10),
            TextButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}

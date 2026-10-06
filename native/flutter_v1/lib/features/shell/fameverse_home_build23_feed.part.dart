part of 'fameverse_home_build23.dart';

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

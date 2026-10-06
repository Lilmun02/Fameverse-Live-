part of 'creator_stories_screen.dart';

class _StoryIntro extends StatelessWidget {
  const _StoryIntro({
    required this.profile,
    required this.summary,
    required this.hasStory,
    required this.posting,
    required this.onCreate,
    required this.onOpen,
  });

  final FvProfile profile;
  final FvStorySummary summary;
  final bool hasStory;
  final bool posting;
  final VoidCallback onCreate;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF37174C), Color(0xFF1A0E22), Color(0xFF0B080E)],
        ),
        border: Border.all(color: const Color(0xFF704493)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: onOpen ?? onCreate,
            child: _AvatarRing(
              avatarUrl: profile.avatarUrl,
              initial: profile.initial,
              active: hasStory,
              seen: false,
              size: 72,
              addBadge: !hasStory,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'YOUR STORY',
                  style: TextStyle(
                    color: Color(0xFFD49CFF),
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  hasStory
                      ? '${summary.activeStoryCount} active · ${summary.totalViews} views'
                      : 'Share a photo or short video',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Active for 24 hours',
                  style: TextStyle(color: Color(0xFFAFA3B5), fontSize: 11),
                ),
              ],
            ),
          ),
          IconButton.filledTonal(
            onPressed: posting ? null : onCreate,
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Add Story',
          ),
        ],
      ),
    );
  }
}

class _CreatorStoryRing extends StatelessWidget {
  const _CreatorStoryRing({required this.stories, required this.onTap});

  final List<FvCreatorStory> stories;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final story = stories.last;
    final unseen = stories.any((item) => !item.viewedByMe);
    return SizedBox(
      width: 82,
      child: InkWell(
        key: Key('story-ring-${story.creatorUserId}'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Column(
          children: [
            _AvatarRing(
              avatarUrl: story.avatarUrl,
              initial: story.displayName.isEmpty
                  ? 'F'
                  : story.displayName.substring(0, 1).toUpperCase(),
              active: true,
              seen: !unseen,
              size: 68,
            ),
            const SizedBox(height: 5),
            Text(
              story.displayName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
            ),
            if (stories.length > 1)
              Text(
                '${stories.length} stories',
                style: const TextStyle(color: Color(0xFF8F8394), fontSize: 9),
              ),
          ],
        ),
      ),
    );
  }
}

class _AvatarRing extends StatelessWidget {
  const _AvatarRing({
    required this.avatarUrl,
    required this.initial,
    required this.active,
    required this.seen,
    required this.size,
    this.addBadge = false,
  });

  final String? avatarUrl;
  final String initial;
  final bool active;
  final bool seen;
  final double size;
  final bool addBadge;

  @override
  Widget build(BuildContext context) {
    final ringColors = !active
        ? const [Color(0xFF4A3D50), Color(0xFF2A242D)]
        : seen
        ? const [Color(0xFF5D5262), Color(0xFF39313E)]
        : const [Color(0xFFF05A86), Color(0xFFB95EFF), Color(0xFF604BFF)];
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: size,
          height: size,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(colors: ringColors),
          ),
          child: Container(
            padding: const EdgeInsets.all(2),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black,
            ),
            child: ClipOval(
              child: avatarUrl != null && avatarUrl!.isNotEmpty
                  ? Image.network(
                      avatarUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          _AvatarFallback(initial: initial),
                    )
                  : _AvatarFallback(initial: initial),
            ),
          ),
        ),
        if (addBadge)
          Positioned(
            right: -1,
            bottom: 1,
            child: Container(
              width: 23,
              height: 23,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF984BE8),
                border: Border.all(color: Colors.black, width: 2),
              ),
              child: const Icon(Icons.add_rounded, size: 15),
            ),
          ),
      ],
    );
  }
}

class _AvatarFallback extends StatelessWidget {
  const _AvatarFallback({required this.initial});

  final String initial;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFF382146),
      child: Center(
        child: Text(
          initial,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
        ),
      ),
    );
  }
}

class _StoryInfoCard extends StatelessWidget {
  const _StoryInfoCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF151017),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF392B40)),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Color(0xFFAFA3B5), height: 1.4),
      ),
    );
  }
}

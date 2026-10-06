part of 'fameverse_discover_screen.dart';

class _CreatorResultCard extends StatelessWidget {
  const _CreatorResultCard({
    required this.creator,
    required this.following,
    required this.busy,
    required this.onFollow,
    required this.onOpen,
  });

  final FvCreator creator;
  final bool following;
  final bool busy;
  final VoidCallback onFollow;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final bio = creator.profile.bio.trim();
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFF151018),
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: const Color(0xFF33243C)),
      ),
      child: Row(
        children: [
          GestureDetector(
            key: Key('discover-creator-profile-${creator.profile.id}'),
            onTap: onOpen,
            child: _DiscoverAvatar(profile: creator.profile, radius: 27),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        creator.profile.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 5),
                    const Icon(
                      Icons.auto_awesome_rounded,
                      size: 13,
                      color: Color(0xFFA95BFF),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${creator.profile.handle} · ${_discoverCompact(creator.followerCount)} followers',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFA79BAA),
                    fontSize: 11,
                  ),
                ),
                if (bio.isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Text(
                    bio,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFFD8CDD9),
                      fontSize: 11,
                      height: 1.3,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          FilledButton.tonal(
            onPressed: busy ? null : onFollow,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            ),
            child: Text(following ? 'Following' : 'Follow'),
          ),
        ],
      ),
    );
  }
}

class _DiscoverLoadingCard extends StatelessWidget {
  const _DiscoverLoadingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: const Color(0xFF151018),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF33243C)),
      ),
      child: const Center(child: CircularProgressIndicator()),
    );
  }
}

class _DiscoverEmptyCard extends StatelessWidget {
  const _DiscoverEmptyCard({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF151018),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF33243C)),
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
                    color: Color(0xFFA79BAA),
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DiscoverAvatar extends StatelessWidget {
  const _DiscoverAvatar({required this.profile, required this.radius});

  final FvProfile profile;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final avatar = profile.avatarUrl?.trim();
    return CircleAvatar(
      radius: radius,
      backgroundColor: const Color(0xFF3A2148),
      foregroundImage: avatar == null || avatar.isEmpty
          ? null
          : NetworkImage(avatar),
      child: Text(
        profile.initial,
        style: const TextStyle(fontWeight: FontWeight.w900),
      ),
    );
  }
}

String _discoverCompact(int value) {
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

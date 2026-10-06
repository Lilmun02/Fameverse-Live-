part of 'fameverse_home_screen.dart';

class _SuggestedCreatorCard extends StatelessWidget {
  const _SuggestedCreatorCard({
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
          GestureDetector(
            key: Key('home-creator-profile-${creator.profile.id}'),
            onTap: onOpen,
            child: _Avatar(profile: creator.profile, radius: 29),
          ),
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

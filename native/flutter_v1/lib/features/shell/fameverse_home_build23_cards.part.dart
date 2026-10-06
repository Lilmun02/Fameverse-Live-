part of 'fameverse_home_build23.dart';

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

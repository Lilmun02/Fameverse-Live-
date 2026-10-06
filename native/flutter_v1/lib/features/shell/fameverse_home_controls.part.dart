part of 'fameverse_home_screen.dart';

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

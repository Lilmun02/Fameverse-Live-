part of 'fameverse_discover_screen.dart';

class _DiscoverFameboardCard extends StatelessWidget {
  const _DiscoverFameboardCard();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: const Key('discover-fameboard-card'),
        onTap: () => showNativeLiveRankings(context),
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFF5B3970)),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF321846), Color(0xFF191020), Color(0xFF100B14)],
            ),
          ),
          child: const Row(
            children: [
              _DiscoverFameboardMark(),
              SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'FAMEBOARD',
                      style: TextStyle(
                        color: Color(0xFFC88BFF),
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Who is moving Fameverse?',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Explore Supporters, Pulse and Creators across 24H and 7D windows.',
                      style: TextStyle(
                        color: Color(0xFFA99DAE),
                        fontSize: 10,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: Color(0xFFC697EB),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DiscoverFameboardMark extends StatelessWidget {
  const _DiscoverFameboardMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        gradient: const LinearGradient(
          colors: [Color(0xFFA853FF), Color(0xFF5A2BCD)],
        ),
      ),
      child: const Icon(Icons.leaderboard_rounded),
    );
  }
}

class _DiscoverTopBar extends StatelessWidget {
  const _DiscoverTopBar({required this.profile, required this.onOpenProfile});

  final FvProfile profile;
  final VoidCallback onOpenProfile;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'FAMEVERSE',
                style: TextStyle(
                  color: Color(0xFFC985FF),
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Discover',
                key: Key('discover-title'),
                style: TextStyle(
                  fontSize: 29,
                  height: 1,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -.5,
                ),
              ),
              SizedBox(height: 5),
              Text(
                'Search on purpose. Find somebody new.',
                style: TextStyle(color: Color(0xFF9F93A4), fontSize: 12),
              ),
            ],
          ),
        ),
        InkWell(
          onTap: onOpenProfile,
          customBorder: const CircleBorder(),
          child: _DiscoverAvatar(profile: profile, radius: 22),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF6B31B5) : const Color(0xFF17121B),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected
                  ? const Color(0xFFB56CFF)
                  : const Color(0xFF33263B),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _DiscoverSectionHeader extends StatelessWidget {
  const _DiscoverSectionHeader({
    required this.eyebrow,
    required this.title,
    required this.count,
  });

  final String eyebrow;
  final String title;
  final int count;

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
                  letterSpacing: 1.35,
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
        Text(
          '$count',
          style: const TextStyle(
            color: Color(0xFF8F8493),
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _DiscoverLiveCard extends StatelessWidget {
  const _DiscoverLiveCard({required this.room, required this.onTap});

  final FvLiveRoom room;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final avatar = room.host.avatarUrl?.trim();
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF3B2845)),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF311541), Color(0xFF110C15)],
            ),
            image: avatar == null || avatar.isEmpty
                ? null
                : DecorationImage(
                    image: NetworkImage(avatar),
                    fit: BoxFit.cover,
                    opacity: .24,
                  ),
          ),
          child: Stack(
            children: [
              const Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(20)),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0x22000000), Color(0xEA000000)],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 10,
                top: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE72C57),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: const Text(
                    'LIVE',
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900),
                  ),
                ),
              ),
              Positioned(
                right: 10,
                top: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xB70B0710),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'F ${_discoverCompact(room.fameTaps)}',
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 11,
                right: 11,
                bottom: 11,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _DiscoverAvatar(profile: room.host, radius: 20),
                    const SizedBox(height: 8),
                    Text(
                      room.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      room.host.handle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFFB2A4B8),
                        fontSize: 10,
                      ),
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

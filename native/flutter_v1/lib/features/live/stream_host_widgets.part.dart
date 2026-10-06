part of 'stream_host_live_screen.dart';

class _FameverseLiveWordmark extends StatelessWidget {
  const _FameverseLiveWordmark();

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.workspace_premium_rounded,
          size: 18,
          color: Color(0xFFB75CFF),
          shadows: [Shadow(color: Color(0xFF8B35FF), blurRadius: 12)],
        ),
        Text(
          'FAMEVERSE',
          key: Key('host-v2-fameverse-wordmark'),
          style: TextStyle(
            color: Color(0xFFD6A4FF),
            fontSize: 13,
            fontWeight: FontWeight.w900,
            letterSpacing: 4,
            shadows: [Shadow(color: Color(0xFF8B35FF), blurRadius: 10)],
          ),
        ),
        Text(
          'PEOPLE MAKE LEGENDS',
          style: TextStyle(
            color: Color(0xFFECE4F2),
            fontSize: 6,
            fontWeight: FontWeight.w800,
            letterSpacing: 2.2,
          ),
        ),
      ],
    );
  }
}

class _NeonHostAvatar extends StatelessWidget {
  const _NeonHostAvatar({required this.profile});

  final FvProfile profile;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFA94DFF), width: 2),
            boxShadow: const [
              BoxShadow(color: Color(0x778A2BE2), blurRadius: 12),
            ],
          ),
          child: NativeProfileAvatar(profile: profile, radius: 20),
        ),
        Positioned(
          right: -1,
          bottom: 1,
          child: Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF35E36A),
              border: Border.all(color: Colors.black, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

class _LiveStatsPill extends StatelessWidget {
  const _LiveStatsPill({required this.viewerCount, required this.fameTaps});

  final int viewerCount;
  final int fameTaps;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('host-v2-combined-stats'),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xB30D0911),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFF4E3561)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.local_fire_department_rounded,
            size: 13,
            color: Color(0xFFFF9D2E),
          ),
          const SizedBox(width: 3),
          Text(
            '$fameTaps',
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 6),
            child: SizedBox(
              width: 1,
              height: 14,
              child: ColoredBox(color: Color(0xFF4E3561)),
            ),
          ),
          const Icon(Icons.visibility_rounded, size: 12),
          const SizedBox(width: 3),
          Text(
            '$viewerCount',
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

part of 'stream_viewer_live_screen.dart';

class _TapBurstParticle extends StatelessWidget {
  const _TapBurstParticle({required this.serial});

  final int serial;

  @override
  Widget build(BuildContext context) {
    final symbol = serial.isEven ? '🔥' : 'F';
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 850),
      curve: Curves.easeOut,
      builder: (context, progress, child) {
        return Opacity(
          opacity: (1 - progress).clamp(0, 1),
          child: Transform.translate(
            offset: Offset(0, -118 * progress),
            child: Transform.scale(
              scale: .82 + (.28 * (1 - progress)),
              child: child,
            ),
          ),
        );
      },
      child: Text(
        symbol,
        style: TextStyle(
          color: symbol == 'F' ? const Color(0xFFB96BFF) : null,
          fontSize: 28,
          fontWeight: FontWeight.w900,
          shadows: const [Shadow(blurRadius: 8, color: Colors.black)],
        ),
      ),
    );
  }
}

class _ViewerStatChip extends StatelessWidget {
  const _ViewerStatChip({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: .45),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12),
          const SizedBox(width: 3),
          Text(
            text,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

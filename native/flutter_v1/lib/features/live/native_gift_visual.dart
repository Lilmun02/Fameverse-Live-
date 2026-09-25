import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../data/fameverse_live_backend.dart';

/// Stable gift artwork used inside the gift tray.
///
/// Build 18 rule: the tray must never use paused cinematic video frames as
/// thumbnails. Those frames can initialize on black and made the catalog look
/// broken on a real iPhone. Cinematic video is reserved for the live playback
/// overlay after a gift is sent; the tray itself always has deterministic,
/// transparent artwork.
class NativeGiftTrayVisual extends StatelessWidget {
  const NativeGiftTrayVisual({required this.gift, this.size = 54, super.key});

  final FvGiftDefinition gift;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (gift.id == 'pocket-comet') {
      return SizedBox.square(
        dimension: size,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: const CustomPaint(painter: _PocketCometPosterPainter()),
        ),
      );
    }

    return SizedBox.square(
      dimension: size,
      child: DecoratedBox(
        key: ValueKey<String>('gift-tray-art-${gift.id}'),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: RadialGradient(
            center: const Alignment(.2, -.25),
            radius: 1.0,
            colors: [
              const Color(0xFF8E5BD1).withValues(alpha: .34),
              const Color(0xFF3A2350).withValues(alpha: .22),
              Colors.transparent,
            ],
          ),
        ),
        child: Center(
          child: Text(
            gift.symbol,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: size * .58,
              height: 1,
              shadows: const [
                Shadow(
                  blurRadius: 12,
                  color: Color(0x669D55FF),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PocketCometPosterPainter extends CustomPainter {
  const _PocketCometPosterPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF071126), Color(0xFF10254B), Color(0xFF09162A)],
        ).createShader(rect),
    );

    final center = Offset(size.width * .52, size.height * .50);
    final orbit = Paint()
      ..color = const Color(0xB05AA8FF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(2, size.width * .045);
    canvas.drawOval(
      Rect.fromCenter(
        center: center,
        width: size.width * .70,
        height: size.height * .34,
      ),
      orbit,
    );

    final comet = Offset(size.width * .66, size.height * .42);
    final tailEnd = Offset(size.width * .24, size.height * .68);
    canvas.drawLine(
      tailEnd,
      comet,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFF3DE0FF), Color(0xFF8B6CFF)],
        ).createShader(Rect.fromPoints(tailEnd, comet))
        ..strokeCap = StrokeCap.round
        ..strokeWidth = math.max(5, size.width * .12),
    );
    canvas.drawCircle(
      comet,
      size.width * .17,
      Paint()
        ..shader =
            const RadialGradient(
              colors: [Color(0xFFFFF6C8), Color(0xFFFFD15A), Color(0x005AA8FF)],
            ).createShader(
              Rect.fromCircle(center: comet, radius: size.width * .20),
            ),
    );

    final starPaint = Paint()..color = Colors.white.withValues(alpha: .75);
    for (var i = 0; i < 12; i += 1) {
      final seed = i * 13.0;
      final x = (math.sin(seed) * .5 + .5) * size.width;
      final y = (math.cos(seed * 1.9) * .5 + .5) * size.height;
      canvas.drawCircle(Offset(x, y), 1.2, starPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _PocketCometPosterPainter oldDelegate) => false;
}

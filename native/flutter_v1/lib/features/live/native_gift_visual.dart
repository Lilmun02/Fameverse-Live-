import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../data/fameverse_live_backend.dart';

/// Stable gift-store poster art.
///
/// Build 16 tried to use paused frames from the remote cinematic videos as
/// thumbnails. Several of those frames are black, which produced the empty
/// black boxes seen during physical QA. The tray now uses deterministic poster
/// art; the real cinematic still plays after a successful send.
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

    if (gift.cinematic) {
      return SizedBox.square(
        dimension: size,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF4A2564), Color(0xFF24142F), Color(0xFF17101F)],
            ),
            border: Border.all(color: const Color(0x335F37A1)),
          ),
          child: Center(
            child: Text(
              gift.symbol,
              style: TextStyle(fontSize: size * .46),
            ),
          ),
        ),
      );
    }

    return SizedBox.square(
      dimension: size,
      child: Center(
        child: Text(
          gift.symbol,
          style: TextStyle(fontSize: size * .52),
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
          colors: [Color(0xFF020617), Color(0xFF0B1B3A), Color(0xFF06101F)],
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
        ..shader = const RadialGradient(
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

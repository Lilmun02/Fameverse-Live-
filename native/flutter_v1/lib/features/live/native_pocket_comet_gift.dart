import 'dart:math' as math;

import 'package:flutter/material.dart';

class NativePocketCometGift extends StatefulWidget {
  const NativePocketCometGift({required this.sender, super.key});

  final String sender;

  @override
  State<NativePocketCometGift> createState() => _NativePocketCometGiftState();
}

class _NativePocketCometGiftState extends State<NativePocketCometGift>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4500),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Stack(
            fit: StackFit.expand,
            children: [
              Container(color: Colors.black.withValues(alpha: .20)),
              CustomPaint(
                painter: _PocketCometPainter(progress: _controller.value),
              ),
              Positioned(
                left: 20,
                right: 20,
                bottom: 128,
                child: Column(
                  children: [
                    Text(
                      '${widget.sender} sent Pocket Comet',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        shadows: [Shadow(blurRadius: 12, color: Colors.black)],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0x8C080A12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text(
                        'FAMEVERSE LIVE',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 11,
                          letterSpacing: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PocketCometPainter extends CustomPainter {
  const _PocketCometPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final background = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF020617), Color(0xFF0B1B3A), Color(0xFF06101F)],
      ).createShader(rect);
    canvas.drawRect(rect, background);

    final stars = <Offset>[
      Offset(size.width * .42, size.height * .38),
      Offset(size.width * .58, size.height * .34),
      Offset(size.width * .52, size.height * .48),
    ];

    final constellation = Paint()
      ..color = const Color(0x8CB48CFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.2, size.width * .003);
    final path = Path()
      ..moveTo(stars[0].dx, stars[0].dy)
      ..lineTo(stars[1].dx, stars[1].dy)
      ..lineTo(stars[2].dx, stars[2].dy)
      ..close();
    canvas.drawPath(path, constellation);

    final starPaint = Paint()..color = const Color(0xFFFFD478);
    for (final star in stars) {
      canvas.drawCircle(star, math.max(2.4, size.width * .008), starPaint);
    }

    final center = Offset(
      (stars[0].dx + stars[1].dx + stars[2].dx) / 3,
      (stars[0].dy + stars[1].dy + stars[2].dy) / 3,
    );

    final local = ((progress - .56) / .19).clamp(0.0, 1.0);
    final angle = -.6 + local * math.pi * 2;
    final comet = Offset(
      center.dx + math.cos(angle) * size.width * .16,
      center.dy + math.sin(angle) * size.height * .07,
    );

    final orbit = Paint()
      ..color = const Color(0xA65AA8FF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * .012;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(center.dx, center.dy + size.height * .02),
        width: size.width * .44,
        height: size.height * .18,
      ),
      orbit,
    );

    final tailEnd = Offset(
      comet.dx - math.cos(angle) * size.width * .18,
      comet.dy - math.sin(angle) * size.height * .08,
    );
    final tail = Paint()
      ..shader = LinearGradient(
        colors: const [Color(0xFF3DE0FF), Color(0xFF8B6CFF)],
      ).createShader(Rect.fromPoints(tailEnd, comet))
      ..strokeCap = StrokeCap.round
      ..strokeWidth = size.width * .035;
    canvas.drawLine(tailEnd, comet, tail);

    final cometGlow = Paint()
      ..shader = RadialGradient(
        colors: const [Color(0xFFFFF6C8), Color(0xFFFFD15A), Color(0x005AA8FF)],
      ).createShader(Rect.fromCircle(center: comet, radius: size.width * .08));
    canvas.drawCircle(comet, size.width * .08, cometGlow);

    final burstStart = 2.85 / 4.5;
    if (progress >= burstStart) {
      final burstProgress = ((progress - burstStart) / .24).clamp(0.0, 1.0);
      final burstCenter = Offset(center.dx, center.dy + size.height * .06);
      final radius = size.width * (.08 + .22 * burstProgress);
      final burst = Paint()
        ..shader = const RadialGradient(
          colors: [
            Color(0xFFFFF6C8),
            Color(0xFFFFD15A),
            Color(0xFFB48CFF),
            Color(0x005AA8FF),
          ],
          stops: [0, .2, .48, 1],
        ).createShader(Rect.fromCircle(center: burstCenter, radius: radius));
      canvas.drawCircle(burstCenter, radius, burst);
    }

    final sparklePaint = Paint()..color = Colors.white.withValues(alpha: .65);
    for (var i = 0; i < 22; i += 1) {
      final seed = i * 17.0;
      final x = (math.sin(seed) * .5 + .5) * size.width;
      final y = (math.cos(seed * 1.7) * .5 + .5) * size.height * .72;
      final pulse = .5 + .5 * math.sin(progress * math.pi * 8 + i);
      canvas.drawCircle(Offset(x, y), 1 + 2 * pulse, sparklePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _PocketCometPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

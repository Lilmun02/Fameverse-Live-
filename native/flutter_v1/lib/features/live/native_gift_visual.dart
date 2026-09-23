import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../data/fameverse_live_backend.dart';

class NativeGiftTrayVisual extends StatefulWidget {
  const NativeGiftTrayVisual({required this.gift, this.size = 54, super.key});

  final FvGiftDefinition gift;
  final double size;

  @override
  State<NativeGiftTrayVisual> createState() => _NativeGiftTrayVisualState();
}

class _NativeGiftTrayVisualState extends State<NativeGiftTrayVisual> {
  VideoPlayerController? _controller;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void didUpdateWidget(covariant NativeGiftTrayVisual oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.gift.id != widget.gift.id ||
        oldWidget.gift.videoUrl != widget.gift.videoUrl) {
      unawaited(_load());
    }
  }

  Duration _thumbnailTime(String giftId) => switch (giftId) {
    'ember-dragon' => const Duration(milliseconds: 4200),
    'celestial-phoenix' => const Duration(milliseconds: 7000),
    'welcome-to-fameverse' => const Duration(milliseconds: 2600),
    _ => Duration.zero,
  };

  Future<void> _load() async {
    final previous = _controller;
    _controller = null;
    if (previous != null) await previous.dispose();

    final url = widget.gift.videoUrl;
    if (url == null || url.isEmpty) {
      if (mounted) setState(() {});
      return;
    }

    final next = VideoPlayerController.networkUrl(Uri.parse(url));
    try {
      await next.initialize();
      await next.setLooping(false);
      await next.setVolume(0);
      final target = _thumbnailTime(widget.gift.id);
      final duration = next.value.duration;
      final safeTarget = duration > Duration.zero && target >= duration
          ? duration - const Duration(milliseconds: 120)
          : target;
      if (safeTarget > Duration.zero) await next.seekTo(safeTarget);
      await next.pause();
      _controller = next;
      if (mounted) setState(() {});
    } catch (_) {
      await next.dispose();
      if (mounted) setState(() {});
    }
  }

  @override
  void dispose() {
    final controller = _controller;
    _controller = null;
    if (controller != null) unawaited(controller.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.gift.id == 'pocket-comet') {
      return SizedBox.square(
        dimension: widget.size,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: const CustomPaint(painter: _PocketCometPosterPainter()),
        ),
      );
    }

    final controller = _controller;
    if (controller != null && controller.value.isInitialized) {
      return SizedBox.square(
        dimension: widget.size,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: ColoredBox(
            color: Colors.black,
            child: FittedBox(
              fit: BoxFit.cover,
              clipBehavior: Clip.hardEdge,
              child: SizedBox(
                width: controller.value.size.width,
                height: controller.value.size.height,
                child: VideoPlayer(controller),
              ),
            ),
          ),
        ),
      );
    }

    return SizedBox.square(
      dimension: widget.size,
      child: Center(
        child: Text(
          widget.gift.symbol,
          style: TextStyle(fontSize: widget.size * .52),
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

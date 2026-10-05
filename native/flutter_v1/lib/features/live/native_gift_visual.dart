import 'dart:async';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../data/fameverse_live_backend.dart';

/// Gift-store artwork.
///
/// Cinematic gifts must preview their real video asset in the tray. They never
/// masquerade as an emoji when the media exists. Lightweight gifts keep their
/// intentionally simple symbol treatment.
class NativeGiftTrayVisual extends StatefulWidget {
  const NativeGiftTrayVisual({required this.gift, this.size = 54, super.key});

  final FvGiftDefinition gift;
  final double size;

  @override
  State<NativeGiftTrayVisual> createState() => _NativeGiftTrayVisualState();
}

class _NativeGiftTrayVisualState extends State<NativeGiftTrayVisual> {
  VideoPlayerController? _controller;
  bool _failed = false;
  int _loadEpoch = 0;

  @override
  void initState() {
    super.initState();
    unawaited(_syncPreview());
  }

  @override
  void didUpdateWidget(covariant NativeGiftTrayVisual oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.gift.id != widget.gift.id ||
        oldWidget.gift.videoUrl != widget.gift.videoUrl ||
        oldWidget.gift.cinematic != widget.gift.cinematic) {
      unawaited(_syncPreview());
    }
  }

  Future<void> _syncPreview() async {
    final epoch = ++_loadEpoch;
    final previous = _controller;
    _controller = null;
    if (previous != null) {
      await previous.dispose();
    }

    if (!mounted) return;

    final url = widget.gift.videoUrl?.trim() ?? '';
    if (!widget.gift.cinematic) {
      setState(() => _failed = false);
      return;
    }

    if (url.isEmpty) {
      setState(() => _failed = true);
      return;
    }

    setState(() => _failed = false);
    final next = VideoPlayerController.networkUrl(
      Uri.parse(url),
      videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
    );

    try {
      await next.initialize();
      await next.setLooping(false);
      await next.setVolume(0);

      final durationMs = next.value.duration.inMilliseconds;
      if (durationMs > 0) {
        final previewMs = (durationMs * .22).round().clamp(250, 2200).toInt();
        await next.seekTo(Duration(milliseconds: previewMs));
      }
      await next.pause();

      if (!mounted || epoch != _loadEpoch) {
        await next.dispose();
        return;
      }

      setState(() {
        _controller = next;
        _failed = false;
      });
    } catch (_) {
      await next.dispose();
      if (!mounted || epoch != _loadEpoch) return;
      setState(() => _failed = true);
    }
  }

  @override
  void dispose() {
    _loadEpoch++;
    final controller = _controller;
    _controller = null;
    if (controller != null) {
      unawaited(controller.dispose());
    }
    super.dispose();
  }

  Widget _cinematicPreview() {
    final controller = _controller;
    if (controller != null && controller.value.isInitialized) {
      final videoSize = controller.value.size;
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SizedBox.square(
          dimension: widget.size,
          child: FittedBox(
            fit: BoxFit.cover,
            clipBehavior: Clip.hardEdge,
            child: SizedBox(
              width: videoSize.width <= 0 ? widget.size : videoSize.width,
              height: videoSize.height <= 0 ? widget.size : videoSize.height,
              child: VideoPlayer(controller),
            ),
          ),
        ),
      );
    }

    return SizedBox.square(
      dimension: widget.size,
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
          child: _failed
              ? Icon(
                  Icons.movie_filter_outlined,
                  key: Key('gift-preview-unavailable-${widget.gift.id}'),
                  size: widget.size * .42,
                  color: const Color(0xFFB98CFF),
                )
              : SizedBox.square(
                  dimension: widget.size * .26,
                  child: const CircularProgressIndicator(strokeWidth: 2),
                ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.gift.cinematic) {
      return _cinematicPreview();
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

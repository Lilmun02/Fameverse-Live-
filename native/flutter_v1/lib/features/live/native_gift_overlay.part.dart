part of 'native_live_components.dart';

class NativeGiftOverlay extends StatefulWidget {
  const NativeGiftOverlay({required this.playback, this.onFinished, super.key});

  final FvGiftPlayback playback;
  final VoidCallback? onFinished;

  @override
  State<NativeGiftOverlay> createState() => _NativeGiftOverlayState();
}

class _NativeGiftOverlayState extends State<NativeGiftOverlay> {
  VideoPlayerController? _controller;
  String? _loadedUrl;
  Timer? _finishTimer;
  bool _reportedFinished = false;
  bool _videoLoading = false;
  bool _videoFailed = false;
  int _videoLoadEpoch = 0;

  @override
  void initState() {
    super.initState();
    unawaited(_syncVideo());
  }

  @override
  void didUpdateWidget(covariant NativeGiftOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.playback.gift.id != widget.playback.gift.id ||
        oldWidget.playback.gift.videoUrl != widget.playback.gift.videoUrl ||
        oldWidget.playback.quantity != widget.playback.quantity) {
      _reportedFinished = false;
      _finishTimer?.cancel();
      unawaited(_syncVideo());
    }
  }

  void _scheduleFinish(Duration duration) {
    _finishTimer?.cancel();
    _finishTimer = Timer(duration, _reportFinished);
  }

  void _reportFinished() {
    if (_reportedFinished) return;
    _reportedFinished = true;
    widget.onFinished?.call();
  }

  Duration _staticDuration(FvGiftDefinition gift) {
    if (gift.cinematic) return const Duration(milliseconds: 3200);
    if (gift.cost >= 100) return const Duration(milliseconds: 3000);
    return const Duration(milliseconds: 1900);
  }

  Future<void> _syncVideo() async {
    final epoch = ++_videoLoadEpoch;
    final gift = widget.playback.gift;
    final url = gift.videoUrl?.trim() ?? '';

    if (!gift.cinematic || url.isEmpty) {
      final previous = _controller;
      _controller = null;
      _loadedUrl = null;
      _videoLoading = false;
      _videoFailed = gift.cinematic;
      if (previous != null) await previous.dispose();
      _scheduleFinish(_staticDuration(gift));
      if (mounted) setState(() {});
      return;
    }

    if (_loadedUrl == url &&
        _controller != null &&
        _controller!.value.isInitialized) {
      _videoLoading = false;
      _videoFailed = false;
      await _controller!.seekTo(Duration.zero);
      await _controller!.setVolume(1);
      await _controller!.play();
      final rawMs = _controller!.value.duration.inMilliseconds + 350;
      final safeMs = rawMs.clamp(1500, 60000).toInt();
      _scheduleFinish(Duration(milliseconds: safeMs));
      if (mounted) setState(() {});
      return;
    }

    _videoLoading = true;
    _videoFailed = false;
    if (mounted) setState(() {});

    final previous = _controller;
    _controller = null;
    _loadedUrl = null;
    if (previous != null) await previous.dispose();

    Object? lastError;
    for (var attempt = 0; attempt < 2; attempt++) {
      final next = VideoPlayerController.networkUrl(
        Uri.parse(url),
        videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
      );
      try {
        await next.initialize().timeout(const Duration(seconds: 10));
        if (!mounted || epoch != _videoLoadEpoch) {
          await next.dispose();
          return;
        }
        await next.setLooping(false);
        await next.setVolume(1);
        await next.seekTo(Duration.zero);
        await next.play();
        _controller = next;
        _loadedUrl = url;
        _videoLoading = false;
        _videoFailed = false;
        final rawMs = next.value.duration.inMilliseconds + 350;
        final safeMs = rawMs.clamp(1500, 60000).toInt();
        _scheduleFinish(Duration(milliseconds: safeMs));
        setState(() {});
        return;
      } catch (error) {
        lastError = error;
        await next.dispose();
        if (!mounted || epoch != _videoLoadEpoch) return;
        if (attempt == 0) {
          await Future<void>.delayed(const Duration(milliseconds: 350));
        }
      }
    }

    if (!mounted || epoch != _videoLoadEpoch) return;
    _videoLoading = false;
    _videoFailed = true;
    _controller = null;
    _loadedUrl = null;
    _scheduleFinish(const Duration(milliseconds: 4500));
    setState(() {});
    assert(() {
      debugPrint('Premium gift video failed for ${gift.id}: $lastError');
      return true;
    }());
  }

  @override
  void dispose() {
    _videoLoadEpoch++;
    _finishTimer?.cancel();
    final controller = _controller;
    _controller = null;
    if (controller != null) unawaited(controller.dispose());
    super.dispose();
  }

  Widget _largeNativeGift(BuildContext context, FvGiftPlayback playback) {
    final size = MediaQuery.sizeOf(context);
    final premium = playback.gift.cost >= 100;
    return IgnorePointer(
      child: Align(
        alignment: const Alignment(0, .02),
        child: SizedBox(
          key: Key('native-gift-presentation-${playback.gift.id}'),
          width: size.width * .90,
          height: size.height * (premium ? .52 : .44),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: size.width * (premium ? .74 : .60),
                height: size.width * (premium ? .74 : .60),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(
                        0xFF9D55FF,
                      ).withValues(alpha: premium ? .44 : .30),
                      const Color(0xFF5C22A7).withValues(alpha: .16),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: .72, end: 1),
                duration: const Duration(milliseconds: 560),
                curve: Curves.easeOutBack,
                builder: (context, value, child) =>
                    Transform.scale(scale: value, child: child),
                child: Text(
                  playback.gift.symbol,
                  style: TextStyle(
                    fontSize: premium ? 132 : 104,
                    shadows: const [
                      Shadow(color: Color(0xAA8F46E8), blurRadius: 28),
                      Shadow(color: Colors.black87, blurRadius: 8),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final playback = widget.playback;

    if (!playback.gift.cinematic) {
      return _largeNativeGift(context, playback);
    }

    final controller = _controller;
    if (controller != null && controller.value.isInitialized) {
      final size = MediaQuery.sizeOf(context);
      return IgnorePointer(
        child: Center(
          child: SizedBox(
            key: Key('cinematic-gift-presentation-${playback.gift.id}'),
            width: size.width,
            height: size.height * .76,
            child: FittedBox(
              fit: BoxFit.contain,
              clipBehavior: Clip.none,
              child: SizedBox(
                width: controller.value.size.width <= 0
                    ? size.width
                    : controller.value.size.width,
                height: controller.value.size.height <= 0
                    ? size.height * .76
                    : controller.value.size.height,
                child: VideoPlayer(controller),
              ),
            ),
          ),
        ),
      );
    }

    final size = MediaQuery.sizeOf(context);
    return IgnorePointer(
      child: Center(
        child: Container(
          key: Key(
            _videoFailed
                ? 'cinematic-gift-media-failed-${playback.gift.id}'
                : 'cinematic-gift-media-loading-${playback.gift.id}',
          ),
          width: size.width * .90,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          decoration: BoxDecoration(
            color: const Color(0xE617101F),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: const Color(0x665F37A1)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_videoLoading)
                const SizedBox.square(
                  dimension: 30,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                )
              else
                const Icon(
                  Icons.movie_filter_outlined,
                  color: Color(0xFFB98CFF),
                  size: 34,
                ),
              const SizedBox(height: 12),
              Text(
                _videoFailed
                    ? 'Premium gift media could not load'
                    : 'Loading premium gift…',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _videoFailed
                    ? 'The premium gift was recorded, but Fameverse will not replace its animation with an emoji.'
                    : 'Preparing the original premium gift animation.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFFB9ACBE),
                  fontSize: 11,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

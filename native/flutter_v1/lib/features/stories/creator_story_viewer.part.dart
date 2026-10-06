part of 'creator_stories_screen.dart';

class _StoryViewer extends StatefulWidget {
  const _StoryViewer({
    required this.backend,
    required this.stories,
    required this.viewerUserId,
  });

  final SupabaseFameverseStoryBackend backend;
  final List<FvCreatorStory> stories;
  final String viewerUserId;

  @override
  State<_StoryViewer> createState() => _StoryViewerState();
}

class _StoryViewerState extends State<_StoryViewer> {
  int _index = 0;
  Timer? _photoTimer;
  VideoPlayerController? _videoController;
  bool _mediaReady = false;
  bool _deleting = false;

  FvCreatorStory get _story => widget.stories[_index];

  @override
  void initState() {
    super.initState();
    _loadCurrent();
  }

  @override
  void dispose() {
    _photoTimer?.cancel();
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _loadCurrent() async {
    _photoTimer?.cancel();
    final previous = _videoController;
    _videoController = null;
    if (previous != null) await previous.dispose();
    if (mounted) setState(() => _mediaReady = false);

    final story = _story;
    try {
      await widget.backend.recordView(story.id);
    } catch (_) {}

    if (story.isVideo) {
      final controller = VideoPlayerController.networkUrl(
        Uri.parse(story.mediaUrl),
      );
      try {
        await controller.initialize();
        await controller.setLooping(false);
        await controller.setVolume(1);
        await controller.play();
        controller.addListener(() {
          if (!mounted || _videoController != controller) return;
          final value = controller.value;
          if (value.isInitialized &&
              !value.isPlaying &&
              value.position >= value.duration) {
            _next();
          }
        });
        if (!mounted) {
          await controller.dispose();
          return;
        }
        setState(() {
          _videoController = controller;
          _mediaReady = true;
        });
      } catch (_) {
        await controller.dispose();
        if (mounted) setState(() => _mediaReady = true);
      }
      return;
    }

    if (mounted) setState(() => _mediaReady = true);
    _photoTimer = Timer(const Duration(seconds: 6), _next);
  }

  void _previous() {
    if (_index <= 0) return;
    setState(() => _index -= 1);
    unawaited(_loadCurrent());
  }

  void _next() {
    if (!mounted) return;
    if (_index >= widget.stories.length - 1) {
      Navigator.of(context).pop();
      return;
    }
    setState(() => _index += 1);
    unawaited(_loadCurrent());
  }

  Future<void> _delete() async {
    if (!_story.isMine || _deleting) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Story?'),
        content: const Text('This Story will disappear immediately.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _deleting = true);
    try {
      await widget.backend.deleteStory(_story);
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final story = _story;
    final controller = _videoController;
    return Scaffold(
      key: const Key('fameverse-story-viewer'),
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(child: _media(story, controller)),
            Positioned(
              left: 12,
              right: 12,
              top: 8,
              child: Row(
                children: List.generate(widget.stories.length, (index) {
                  final complete = index < _index;
                  final active = index == _index;
                  return Expanded(
                    child: Container(
                      height: 3,
                      margin: EdgeInsets.only(
                        right: index == widget.stories.length - 1 ? 0 : 4,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        color: complete || active
                            ? Colors.white
                            : Colors.white30,
                      ),
                    ),
                  );
                }),
              ),
            ),
            Positioned(
              left: 14,
              right: 8,
              top: 22,
              child: Row(
                children: [
                  _AvatarRing(
                    avatarUrl: story.avatarUrl,
                    initial: story.displayName.isEmpty
                        ? 'F'
                        : story.displayName.substring(0, 1),
                    active: true,
                    seen: false,
                    size: 40,
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      story.displayName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        shadows: [Shadow(blurRadius: 7)],
                      ),
                    ),
                  ),
                  if (story.isMine)
                    IconButton(
                      onPressed: _deleting ? null : _delete,
                      tooltip: 'Delete Story',
                      icon: const Icon(Icons.delete_outline_rounded),
                    ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            Positioned.fill(
              top: 82,
              bottom: 90,
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: _previous,
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: _next,
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 18,
              right: 18,
              bottom: 24,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (story.caption.isNotEmpty)
                    Text(
                      story.caption,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        shadows: [Shadow(color: Colors.black, blurRadius: 8)],
                      ),
                    ),
                  if (story.isMine) ...[
                    const SizedBox(height: 8),
                    Text(
                      '${story.viewCount} ${story.viewCount == 1 ? 'view' : 'views'}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _media(FvCreatorStory story, VideoPlayerController? controller) {
    if (!_mediaReady) {
      return const Center(child: CircularProgressIndicator());
    }
    if (story.isVideo) {
      if (controller == null || !controller.value.isInitialized) {
        return const Center(
          child: Text(
            'Video unavailable',
            style: TextStyle(color: Colors.white70),
          ),
        );
      }
      return Center(
        child: AspectRatio(
          aspectRatio: controller.value.aspectRatio == 0
              ? 9 / 16
              : controller.value.aspectRatio,
          child: VideoPlayer(controller),
        ),
      );
    }
    return Image.network(
      story.mediaUrl,
      fit: BoxFit.contain,
      loadingBuilder: (context, child, progress) => progress == null
          ? child
          : const Center(child: CircularProgressIndicator()),
      errorBuilder: (_, __, ___) => const Center(
        child: Text(
          'Story unavailable',
          style: TextStyle(color: Colors.white70),
        ),
      ),
    );
  }
}

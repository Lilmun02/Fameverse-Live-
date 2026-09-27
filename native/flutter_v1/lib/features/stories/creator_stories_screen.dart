import 'dart:async';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';

import '../../data/fameverse_backend.dart';
import '../../data/fameverse_story_backend.dart';

class CreatorStoriesScreen extends StatefulWidget {
  const CreatorStoriesScreen({
    required this.backend,
    required this.identity,
    required this.profile,
    super.key,
  });

  final SupabaseFameverseStoryBackend backend;
  final FvIdentity identity;
  final FvProfile profile;

  @override
  State<CreatorStoriesScreen> createState() => _CreatorStoriesScreenState();
}

class _CreatorStoriesScreenState extends State<CreatorStoriesScreen> {
  bool _loading = true;
  bool _posting = false;
  String? _error;
  List<FvCreatorStory> _stories = const [];
  FvStorySummary _summary = FvStorySummary.empty;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final results = await Future.wait<dynamic>([
        widget.backend.listActiveStories(),
        widget.backend.loadMySummary(),
      ]);
      if (!mounted) return;
      setState(() {
        _stories = results[0] as List<FvCreatorStory>;
        _summary = results[1] as FvStorySummary;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Stories could not refresh right now.';
      });
    }
  }

  Map<String, List<FvCreatorStory>> get _grouped {
    final groups = <String, List<FvCreatorStory>>{};
    for (final story in _stories) {
      groups.putIfAbsent(story.creatorUserId, () => []).add(story);
    }
    for (final group in groups.values) {
      group.sort((a, b) {
        final aTime = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bTime = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return aTime.compareTo(bTime);
      });
    }
    return groups;
  }

  void _message(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _chooseMedia() async {
    if (_posting) return;
    final type = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: const Color(0xFF17101F),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Add to your Story',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 14),
              ListTile(
                leading: const Icon(Icons.photo_outlined),
                title: const Text('Photo'),
                subtitle: const Text('JPG, PNG or WEBP · up to 50 MB'),
                onTap: () => Navigator.of(context).pop('photo'),
              ),
              ListTile(
                leading: const Icon(Icons.videocam_outlined),
                title: const Text('Short video'),
                subtitle: const Text('MP4 or MOV · up to 50 MB'),
                onTap: () => Navigator.of(context).pop('video'),
              ),
            ],
          ),
        ),
      ),
    );
    if (type == null) return;

    final picker = ImagePicker();
    final file = type == 'photo'
        ? await picker.pickImage(source: ImageSource.gallery, imageQuality: 92)
        : await picker.pickVideo(
            source: ImageSource.gallery,
            maxDuration: const Duration(seconds: 30),
          );
    if (file == null) return;
    if (!mounted) return;

    final captionController = TextEditingController();
    final caption = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Story caption'),
        content: TextField(
          key: const Key('story-caption'),
          controller: captionController,
          maxLength: 160,
          maxLines: 3,
          decoration: const InputDecoration(hintText: 'Optional caption'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(captionController.text),
            child: const Text('Post Story'),
          ),
        ],
      ),
    );
    captionController.dispose();
    if (caption == null) return;

    setState(() => _posting = true);
    try {
      final bytes = await file.readAsBytes();
      final extension = _extension(file.name, type);
      final contentType = _contentType(file.mimeType, extension, type);
      await widget.backend.createStory(
        userId: widget.identity.id,
        bytes: bytes,
        mediaType: type,
        extension: extension,
        contentType: contentType,
        caption: caption,
      );
      _message('Story posted for 24 hours.');
      await _refresh();
    } catch (error) {
      final text = error.toString().toLowerCase();
      _message(
        text.contains('50 mb')
            ? 'Story media must be 50 MB or smaller.'
            : 'Story could not be posted.',
      );
    } finally {
      if (mounted) setState(() => _posting = false);
    }
  }

  Future<void> _openGroup(List<FvCreatorStory> stories) async {
    if (stories.isEmpty) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => _StoryViewer(
          backend: widget.backend,
          stories: stories,
          viewerUserId: widget.identity.id,
        ),
      ),
    );
    await _refresh();
  }

  String _extension(String name, String type) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.png')) return 'png';
    if (lower.endsWith('.webp')) return 'webp';
    if (lower.endsWith('.mov')) return 'mov';
    if (lower.endsWith('.mp4')) return 'mp4';
    return type == 'photo' ? 'jpg' : 'mp4';
  }

  String _contentType(String? mimeType, String extension, String type) {
    final supplied = mimeType?.trim().toLowerCase();
    if (supplied != null && supplied.isNotEmpty) return supplied;
    return switch (extension) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      'mov' => 'video/quicktime',
      'mp4' => 'video/mp4',
      _ => type == 'photo' ? 'image/jpeg' : 'video/mp4',
    };
  }

  @override
  Widget build(BuildContext context) {
    final groups = _grouped;
    final myStories = groups[widget.identity.id] ?? const <FvCreatorStory>[];
    final others =
        groups.entries
            .where((entry) => entry.key != widget.identity.id)
            .toList()
          ..sort((a, b) {
            final aUnseen = a.value.any((story) => !story.viewedByMe);
            final bUnseen = b.value.any((story) => !story.viewedByMe);
            if (aUnseen != bUnseen) return bUnseen ? 1 : -1;
            final aTime =
                a.value.last.createdAt ??
                DateTime.fromMillisecondsSinceEpoch(0);
            final bTime =
                b.value.last.createdAt ??
                DateTime.fromMillisecondsSinceEpoch(0);
            return bTime.compareTo(aTime);
          });

    return Scaffold(
      key: const Key('creator-stories-screen'),
      backgroundColor: const Color(0xFF08060A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF08060A),
        title: const Text('Stories'),
        actions: [
          IconButton(
            key: const Key('post-story-action'),
            onPressed: _posting ? null : _chooseMedia,
            tooltip: 'Add Story',
            icon: _posting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.add_circle_outline_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 38),
            children: [
              _StoryIntro(
                profile: widget.profile,
                summary: _summary,
                hasStory: myStories.isNotEmpty,
                posting: _posting,
                onCreate: _chooseMedia,
                onOpen: myStories.isEmpty ? null : () => _openGroup(myStories),
              ),
              const SizedBox(height: 24),
              const Text(
                'Creator Stories',
                style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 5),
              const Text(
                'Photo and short-video Stories disappear from Fameverse after 24 hours.',
                style: TextStyle(color: Color(0xFFAFA3B4), height: 1.4),
              ),
              const SizedBox(height: 16),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 56),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_error != null)
                _StoryInfoCard(text: _error!)
              else if (others.isEmpty)
                const _StoryInfoCard(
                  text:
                      'No other active Stories yet. When creators post, their rings will appear here.',
                )
              else
                Wrap(
                  spacing: 14,
                  runSpacing: 18,
                  children: others
                      .map(
                        (entry) => _CreatorStoryRing(
                          stories: entry.value,
                          onTap: () => _openGroup(entry.value),
                        ),
                      )
                      .toList(),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StoryIntro extends StatelessWidget {
  const _StoryIntro({
    required this.profile,
    required this.summary,
    required this.hasStory,
    required this.posting,
    required this.onCreate,
    required this.onOpen,
  });

  final FvProfile profile;
  final FvStorySummary summary;
  final bool hasStory;
  final bool posting;
  final VoidCallback onCreate;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF37174C), Color(0xFF1A0E22), Color(0xFF0B080E)],
        ),
        border: Border.all(color: const Color(0xFF704493)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: onOpen ?? onCreate,
            child: _AvatarRing(
              avatarUrl: profile.avatarUrl,
              initial: profile.initial,
              active: hasStory,
              seen: false,
              size: 72,
              addBadge: !hasStory,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'YOUR STORY',
                  style: TextStyle(
                    color: Color(0xFFD49CFF),
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  hasStory
                      ? '${summary.activeStoryCount} active · ${summary.totalViews} views'
                      : 'Share a photo or short video',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Active for 24 hours',
                  style: TextStyle(color: Color(0xFFAFA3B5), fontSize: 11),
                ),
              ],
            ),
          ),
          IconButton.filledTonal(
            onPressed: posting ? null : onCreate,
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Add Story',
          ),
        ],
      ),
    );
  }
}

class _CreatorStoryRing extends StatelessWidget {
  const _CreatorStoryRing({required this.stories, required this.onTap});

  final List<FvCreatorStory> stories;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final story = stories.last;
    final unseen = stories.any((item) => !item.viewedByMe);
    return SizedBox(
      width: 82,
      child: InkWell(
        key: Key('story-ring-${story.creatorUserId}'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Column(
          children: [
            _AvatarRing(
              avatarUrl: story.avatarUrl,
              initial: story.displayName.isEmpty
                  ? 'F'
                  : story.displayName.substring(0, 1).toUpperCase(),
              active: true,
              seen: !unseen,
              size: 68,
            ),
            const SizedBox(height: 5),
            Text(
              story.displayName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
            ),
            if (stories.length > 1)
              Text(
                '${stories.length} stories',
                style: const TextStyle(color: Color(0xFF8F8394), fontSize: 9),
              ),
          ],
        ),
      ),
    );
  }
}

class _AvatarRing extends StatelessWidget {
  const _AvatarRing({
    required this.avatarUrl,
    required this.initial,
    required this.active,
    required this.seen,
    required this.size,
    this.addBadge = false,
  });

  final String? avatarUrl;
  final String initial;
  final bool active;
  final bool seen;
  final double size;
  final bool addBadge;

  @override
  Widget build(BuildContext context) {
    final ringColors = !active
        ? const [Color(0xFF4A3D50), Color(0xFF2A242D)]
        : seen
        ? const [Color(0xFF5D5262), Color(0xFF39313E)]
        : const [Color(0xFFF05A86), Color(0xFFB95EFF), Color(0xFF604BFF)];
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: size,
          height: size,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(colors: ringColors),
          ),
          child: Container(
            padding: const EdgeInsets.all(2),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black,
            ),
            child: ClipOval(
              child: avatarUrl != null && avatarUrl!.isNotEmpty
                  ? Image.network(
                      avatarUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          _AvatarFallback(initial: initial),
                    )
                  : _AvatarFallback(initial: initial),
            ),
          ),
        ),
        if (addBadge)
          Positioned(
            right: -1,
            bottom: 1,
            child: Container(
              width: 23,
              height: 23,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF984BE8),
                border: Border.all(color: Colors.black, width: 2),
              ),
              child: const Icon(Icons.add_rounded, size: 15),
            ),
          ),
      ],
    );
  }
}

class _AvatarFallback extends StatelessWidget {
  const _AvatarFallback({required this.initial});

  final String initial;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFF382146),
      child: Center(
        child: Text(
          initial,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
        ),
      ),
    );
  }
}

class _StoryInfoCard extends StatelessWidget {
  const _StoryInfoCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF151017),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF392B40)),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Color(0xFFAFA3B5), height: 1.4),
      ),
    );
  }
}

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
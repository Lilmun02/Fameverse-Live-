import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';

import '../../data/fameverse_backend.dart';
import '../../data/fameverse_story_backend.dart';

/// Clean native Stories surface.
///
/// Story creation has exactly one create area. Photo/video choices are inline,
/// so the screen is never dimmed by an unnecessary media-choice modal.
class CreatorStoriesScreenV2 extends StatefulWidget {
  const CreatorStoriesScreenV2({
    required this.backend,
    required this.identity,
    required this.profile,
    super.key,
  });

  final SupabaseFameverseStoryBackend backend;
  final FvIdentity identity;
  final FvProfile profile;

  @override
  State<CreatorStoriesScreenV2> createState() => _CreatorStoriesScreenV2State();
}

class _CreatorStoriesScreenV2State extends State<CreatorStoriesScreenV2> {
  bool _loading = true;
  bool _posting = false;
  String? _error;
  List<FvCreatorStory> _stories = const [];
  FvStorySummary _summary = FvStorySummary.empty;

  @override
  void initState() {
    super.initState();
    unawaited(_refresh());
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

  Future<void> _pickMedia(String mediaType) async {
    if (_posting) return;
    try {
      final picker = ImagePicker();
      final XFile? file = mediaType == 'photo'
          ? await picker.pickImage(
              source: ImageSource.gallery,
              imageQuality: 92,
              maxWidth: 2160,
            )
          : await picker.pickVideo(
              source: ImageSource.gallery,
              maxDuration: const Duration(seconds: 30),
            );
      if (file == null || !mounted) return;

      if (mediaType == 'video') {
        final controller = VideoPlayerController.file(File(file.path));
        try {
          await controller.initialize();
          if (controller.value.duration > const Duration(seconds: 30)) {
            _message('Story videos can be up to 30 seconds.');
            return;
          }
        } finally {
          await controller.dispose();
        }
      }

      final caption = await Navigator.of(context).push<String>(
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (context) =>
              _StoryComposerPage(file: file, mediaType: mediaType),
        ),
      );
      if (caption == null || !mounted) return;

      setState(() => _posting = true);
      final bytes = await file.readAsBytes();
      final extension = _extension(file.name, mediaType);
      final contentType = _contentType(file.mimeType, extension, mediaType);
      await widget.backend.createStory(
        userId: widget.identity.id,
        bytes: bytes,
        mediaType: mediaType,
        extension: extension,
        contentType: contentType,
        caption: caption,
      );
      _message('Story posted for 24 hours.');
      await _refresh();
    } catch (error) {
      final text = error.toString().toLowerCase();
      if (text.contains('permission') || text.contains('photo')) {
        _message('Allow Fameverse access to Photos, then try again.');
      } else if (text.contains('50 mb')) {
        _message('Story media must be 50 MB or smaller.');
      } else {
        _message('Story could not be posted. Try again.');
      }
    } finally {
      if (mounted) setState(() => _posting = false);
    }
  }

  Future<void> _openGroup(List<FvCreatorStory> stories) async {
    if (stories.isEmpty) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => _StoryViewerV2(
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
      key: const Key('creator-stories-v2-screen'),
      backgroundColor: const Color(0xFF09070B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF09070B),
        centerTitle: true,
        title: const Text(
          'Stories',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 38),
            children: [
              _YourStoryCard(
                profile: widget.profile,
                summary: _summary,
                activeStories: myStories,
                posting: _posting,
                onPhoto: () => _pickMedia('photo'),
                onVideo: () => _pickMedia('video'),
                onView: myStories.isEmpty ? null : () => _openGroup(myStories),
              ),
              const SizedBox(height: 28),
              const Text(
                'Creator Stories',
                style: TextStyle(fontSize: 23, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 5),
              const Text(
                'See what creators are sharing right now. Stories expire after 24 hours.',
                style: TextStyle(
                  color: Color(0xFFAAA0AF),
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 18),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 60),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_error != null)
                _StoryInfoCard(text: _error!)
              else if (others.isEmpty)
                const _StoryInfoCard(
                  text:
                      'No other active Stories yet. New Story rings will appear here.',
                )
              else
                Wrap(
                  spacing: 14,
                  runSpacing: 18,
                  children: others
                      .map(
                        (entry) => _StoryRing(
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

class _YourStoryCard extends StatelessWidget {
  const _YourStoryCard({
    required this.profile,
    required this.summary,
    required this.activeStories,
    required this.posting,
    required this.onPhoto,
    required this.onVideo,
    required this.onView,
  });

  final FvProfile profile;
  final FvStorySummary summary;
  final List<FvCreatorStory> activeStories;
  final bool posting;
  final VoidCallback onPhoto;
  final VoidCallback onVideo;
  final VoidCallback? onView;

  @override
  Widget build(BuildContext context) {
    final hasStories = activeStories.isNotEmpty;
    return Container(
      key: const Key('single-story-create-area'),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2C153B), Color(0xFF17101E), Color(0xFF0D0A10)],
        ),
        border: Border.all(color: const Color(0xFF634078)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: onView,
                child: _AvatarRing(
                  avatarUrl: profile.avatarUrl,
                  initial: profile.initial,
                  active: hasStories,
                  seen: false,
                  size: 70,
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
                        color: Color(0xFFD399FF),
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      hasStories
                          ? '${summary.activeStoryCount} active · ${summary.totalViews} views'
                          : 'Share something from your day',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Visible for 24 hours',
                      style: TextStyle(color: Color(0xFF9F94A5), fontSize: 11),
                    ),
                  ],
                ),
              ),
              if (hasStories)
                TextButton(
                  key: const Key('view-my-story'),
                  onPressed: onView,
                  child: const Text('View'),
                ),
            ],
          ),
          const SizedBox(height: 18),
          const Text(
            'Add to your Story',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  key: const Key('add-story-photo'),
                  onPressed: posting ? null : onPhoto,
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('Photo'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    backgroundColor: const Color(0xFF7B3CC5),
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.tonalIcon(
                  key: const Key('add-story-video'),
                  onPressed: posting ? null : onVideo,
                  icon: const Icon(Icons.videocam_outlined),
                  label: const Text('Video'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                ),
              ),
            ],
          ),
          if (posting) ...[
            const SizedBox(height: 14),
            const LinearProgressIndicator(minHeight: 3),
            const SizedBox(height: 6),
            const Text(
              'Posting Story…',
              style: TextStyle(color: Color(0xFFBDAFC4), fontSize: 11),
            ),
          ],
        ],
      ),
    );
  }
}

class _StoryComposerPage extends StatefulWidget {
  const _StoryComposerPage({required this.file, required this.mediaType});

  final XFile file;
  final String mediaType;

  @override
  State<_StoryComposerPage> createState() => _StoryComposerPageState();
}

class _StoryComposerPageState extends State<_StoryComposerPage> {
  final TextEditingController _caption = TextEditingController();
  VideoPlayerController? _video;
  bool _videoReady = false;

  @override
  void initState() {
    super.initState();
    if (widget.mediaType == 'video') unawaited(_prepareVideo());
  }

  Future<void> _prepareVideo() async {
    final controller = VideoPlayerController.file(File(widget.file.path));
    await controller.initialize();
    await controller.setLooping(true);
    await controller.play();
    if (!mounted) {
      await controller.dispose();
      return;
    }
    setState(() {
      _video = controller;
      _videoReady = true;
    });
  }

  @override
  void dispose() {
    _caption.dispose();
    _video?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('story-composer-page'),
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('New Story'),
        actions: [
          TextButton(
            key: const Key('post-story-button'),
            onPressed: () => Navigator.of(context).pop(_caption.text.trim()),
            child: const Text(
              'Post',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: AspectRatio(
                aspectRatio: 9 / 13,
                child: ColoredBox(
                  color: const Color(0xFF171019),
                  child: widget.mediaType == 'photo'
                      ? Image.file(File(widget.file.path), fit: BoxFit.cover)
                      : _videoReady && _video != null
                      ? FittedBox(
                          fit: BoxFit.cover,
                          child: SizedBox(
                            width: _video!.value.size.width,
                            height: _video!.value.size.height,
                            child: VideoPlayer(_video!),
                          ),
                        )
                      : const Center(child: CircularProgressIndicator()),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              key: const Key('story-caption'),
              controller: _caption,
              maxLength: 160,
              minLines: 1,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Add a caption…',
                prefixIcon: Icon(Icons.edit_outlined),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Your Story disappears automatically after 24 hours.',
              style: TextStyle(color: Color(0xFF988E9D), fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

class _StoryRing extends StatelessWidget {
  const _StoryRing({required this.stories, required this.onTap});

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
            const SizedBox(height: 6),
            Text(
              story.displayName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
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
  });

  final String? avatarUrl;
  final String initial;
  final bool active;
  final bool seen;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = !active
        ? const [Color(0xFF4A3D50), Color(0xFF2A242D)]
        : seen
        ? const [Color(0xFF5D5262), Color(0xFF39313E)]
        : const [Color(0xFFF05A86), Color(0xFFB95EFF), Color(0xFF604BFF)];
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(colors: colors),
      ),
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black,
        ),
        child: CircleAvatar(
          backgroundColor: const Color(0xFF28162F),
          foregroundImage: avatarUrl?.trim().isNotEmpty == true
              ? NetworkImage(avatarUrl!)
              : null,
          child: Text(
            initial,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
      ),
    );
  }
}

class _StoryViewerV2 extends StatefulWidget {
  const _StoryViewerV2({
    required this.backend,
    required this.stories,
    required this.viewerUserId,
  });

  final SupabaseFameverseStoryBackend backend;
  final List<FvCreatorStory> stories;
  final String viewerUserId;

  @override
  State<_StoryViewerV2> createState() => _StoryViewerV2State();
}

class _StoryViewerV2State extends State<_StoryViewerV2> {
  int _index = 0;
  Timer? _photoTimer;
  VideoPlayerController? _video;
  bool _videoReady = false;

  FvCreatorStory get _story => widget.stories[_index];

  @override
  void initState() {
    super.initState();
    unawaited(_loadCurrent());
  }

  Future<void> _loadCurrent() async {
    _photoTimer?.cancel();
    final previous = _video;
    _video = null;
    _videoReady = false;
    if (previous != null) await previous.dispose();

    final story = _story;
    unawaited(widget.backend.recordView(story.id));
    if (story.isVideo) {
      final controller = VideoPlayerController.networkUrl(
        Uri.parse(story.mediaUrl),
      );
      try {
        await controller.initialize();
        await controller.play();
        controller.addListener(_videoListener);
        if (!mounted) {
          await controller.dispose();
          return;
        }
        setState(() {
          _video = controller;
          _videoReady = true;
        });
      } catch (_) {
        await controller.dispose();
        if (mounted) setState(() => _videoReady = false);
      }
    } else {
      _photoTimer = Timer(const Duration(seconds: 6), _next);
      if (mounted) setState(() {});
    }
  }

  void _videoListener() {
    final video = _video;
    if (video == null || !video.value.isInitialized) return;
    final duration = video.value.duration;
    if (duration > Duration.zero && video.value.position >= duration) _next();
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

  void _previous() {
    if (_index == 0) return;
    setState(() => _index -= 1);
    unawaited(_loadCurrent());
  }

  Future<void> _deleteCurrent() async {
    final story = _story;
    if (!story.isMine) return;
    await widget.backend.deleteStory(story);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _photoTimer?.cancel();
    _video?.removeListener(_videoListener);
    _video?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final story = _story;
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapUp: (details) {
          final width = MediaQuery.sizeOf(context).width;
          if (details.localPosition.dx < width * .35) {
            _previous();
          } else {
            _next();
          }
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (story.isVideo)
              _videoReady && _video != null
                  ? FittedBox(
                      fit: BoxFit.contain,
                      child: SizedBox(
                        width: _video!.value.size.width,
                        height: _video!.value.size.height,
                        child: VideoPlayer(_video!),
                      ),
                    )
                  : const Center(child: CircularProgressIndicator())
            else
              Image.network(
                story.mediaUrl,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Center(
                  child: Icon(Icons.broken_image_outlined, size: 52),
                ),
              ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xB8000000),
                    Colors.transparent,
                    Color(0xB8000000),
                  ],
                  stops: [0, .36, 1],
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: List.generate(widget.stories.length, (index) {
                        return Expanded(
                          child: Container(
                            height: 3,
                            margin: EdgeInsets.only(
                              right: index == widget.stories.length - 1 ? 0 : 4,
                            ),
                            decoration: BoxDecoration(
                              color: index <= _index
                                  ? Colors.white
                                  : Colors.white30,
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          foregroundImage:
                              story.avatarUrl?.trim().isNotEmpty == true
                              ? NetworkImage(story.avatarUrl!)
                              : null,
                          child: Text(
                            story.displayName.isEmpty
                                ? 'F'
                                : story.displayName
                                      .substring(0, 1)
                                      .toUpperCase(),
                          ),
                        ),
                        const SizedBox(width: 9),
                        Expanded(
                          child: Text(
                            story.displayName,
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                        ),
                        if (story.isMine)
                          IconButton(
                            onPressed: _deleteCurrent,
                            icon: const Icon(Icons.delete_outline_rounded),
                            tooltip: 'Delete Story',
                          ),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                    const Spacer(),
                    if (story.caption.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          story.caption,
                          style: const TextStyle(fontSize: 15, height: 1.3),
                        ),
                      ),
                    if (story.isMine) ...[
                      const SizedBox(height: 9),
                      Text(
                        '${story.viewCount} views',
                        style: const TextStyle(
                          color: Color(0xFFD2C7D7),
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
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
        color: const Color(0xFF151117),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF33273A)),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Color(0xFFAFA3B4), height: 1.4),
      ),
    );
  }
}

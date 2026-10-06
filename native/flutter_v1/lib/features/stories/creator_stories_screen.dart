import 'dart:async';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';

import '../../data/fameverse_backend.dart';
import '../../data/fameverse_story_backend.dart';
part 'creator_stories_widgets.part.dart';
part 'creator_story_viewer.part.dart';


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

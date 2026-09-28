import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

String read(String path) => File(path).readAsStringSync();

void main() {
  test('Stories uses one clean create area without duplicate add controls', () {
    final wrapper = read('lib/features/stories/creator_stories_screen.dart');
    final screen = read('lib/features/stories/creator_stories_screen_v2.dart');

    expect(wrapper, contains('CreatorStoriesScreenV2('));
    expect(screen, contains("Key('single-story-create-area')"));
    expect(screen, contains("Key('add-story-photo')"));
    expect(screen, contains("Key('add-story-video')"));
    expect(screen, isNot(contains('showModalBottomSheet<String>')));
    expect(screen, isNot(contains("Key('post-story-action')")));
  });

  test('native Story picker is backed by an iOS Photos usage description', () {
    final iosBranding = read('tool/apply_ios_branding.sh');

    expect(iosBranding, contains('NSPhotoLibraryUsageDescription'));
    expect(iosBranding, contains('photos and short videos for Stories'));
  });

  test('Story upload remains wired to the authoritative backend', () {
    final screen = read('lib/features/stories/creator_stories_screen_v2.dart');
    final backend = read('lib/data/fameverse_story_backend.dart');

    expect(screen, contains('widget.backend.createStory('));
    expect(backend, contains("bucketName = 'fameverse-stories'"));
    expect(backend, contains("'create_creator_story'"));
    expect(backend, contains('50 * 1024 * 1024'));
  });
}

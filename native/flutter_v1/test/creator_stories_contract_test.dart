import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Stories expire after 24 hours and expose unique view counts', () {
    final sql = File(
      '../../supabase/migrations/20260927_creator_stories_v1.sql',
    ).readAsStringSync();

    expect(sql, contains("now() + interval '24 hours'"));
    expect(sql, contains('story.expires_at > now()'));
    expect(sql, contains('primary key (story_id, viewer_user_id)'));
    expect(sql, contains('record_creator_story_view'));
    expect(sql, contains('delete_creator_story'));
  });

  test('Story storage is scoped to the authenticated creator folder', () {
    final sql = File(
      '../../supabase/migrations/20260927_creator_stories_v1.sql',
    ).readAsStringSync();
    expect(sql, contains("bucket_id = 'fameverse-stories'"));
    expect(sql, contains('(storage.foldername(name))[1]'));
    expect(sql, contains('auth.uid()::text'));
  });

  test('Stories V1 stays intentionally small', () {
    final screen = File(
      'lib/features/stories/creator_stories_screen.dart',
    ).readAsStringSync();
    expect(screen, contains('Photo'));
    expect(screen, contains('Short video'));
    expect(screen, contains('Active for 24 hours'));
    expect(screen, contains('Story caption'));
    expect(screen, isNot(contains('Poll')));
    expect(screen, isNot(contains('Music library')));
    expect(screen, isNot(contains('Repost')));
  });

  test(
    'Viewing a Story can progress First Verse without coupling Stories to beta',
    () {
      final backend = File(
        'lib/data/fameverse_story_backend.dart',
      ).readAsStringSync();
      expect(backend, contains("'record_beta_test_mission'"));
      expect(backend, contains("'p_mission_key': 'view_story'"));
      expect(backend, contains('catch (_) {}'));
    },
  );
}

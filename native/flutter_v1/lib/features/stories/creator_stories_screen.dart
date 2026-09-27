import 'package:flutter/material.dart';

import '../../data/fameverse_backend.dart';
import '../../data/fameverse_story_backend.dart';
import 'creator_stories_screen_v2.dart';

/// Compatibility entry used by the existing Fameverse shell.
///
/// The previous Story screen exposed several duplicate add controls and used a
/// dimming media-choice modal. Keep the public constructor stable while routing
/// every existing entry point into the repaired V2 experience.
class CreatorStoriesScreen extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return CreatorStoriesScreenV2(
      backend: backend,
      identity: identity,
      profile: profile,
    );
  }
}

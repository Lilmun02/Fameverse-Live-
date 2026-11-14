import 'dart:async';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/fameverse_backend.dart';
import '../../data/fameverse_beta_backend.dart';
import '../../data/fameverse_creator_backend.dart';
import '../../data/fameverse_live_backend.dart';
import '../../data/fameverse_story_backend.dart';
import '../../data/fv_policy_access.dart';
import '../live/livekit_live_screen.dart';
import '../live/native_camera_screen.dart';
import '../profile/creator_studio_build23.dart';
import '../profile/fameverse_edit_profile_screen.dart';
import '../profile/fameverse_policy_screen.dart';
import '../profile/fameverse_inbox_screen.dart';
import '../profile/fameverse_public_profile_screen.dart';
import '../profile/first_verse_beta_screen.dart';
import '../profile/native_profile_build23.dart';
import '../stories/creator_stories_screen.dart';
import 'fameverse_discover_screen.dart';
import 'fameverse_home_build23.dart';
import 'fameverse_vertical_live_feed.dart';

class FameverseBuild23Shell extends StatefulWidget {
  const FameverseBuild23Shell({
    required this.backend,
    required this.liveBackend,
    required this.identity,
    this.policyAccess,
    this.onReviewPolicy,
    super.key,
  });

  final FameverseBackend backend;
  final FameverseLiveBackend liveBackend;
  final FvIdentity identity;
  final FvPolicyAccess? policyAccess;
  final VoidCallback? onReviewPolicy;


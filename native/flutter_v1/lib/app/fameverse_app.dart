import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/fameverse_backend.dart';
import '../data/fameverse_live_backend.dart';
import '../data/fv_policy_access.dart';
import '../data/fv_policy_acceptance_service.dart';
import '../data/startup_update_service.dart';
import '../features/auth/auth_screen.dart';
import '../features/profile/fameverse_policy_consent_screen.dart';
import '../features/shell/fameverse_shell_build23.dart';

/// Build 23 native Fameverse app shell.
///
/// Regression laws:
/// - The installed Build 23 binary must route through the Build 23 shell.
/// - Active backend/app notices are shown once per published notice.
/// - A backend-notice lookup failure must never strand the app on startup.
class FameverseApp extends StatefulWidget {
  const FameverseApp({
    required this.backend,
    required this.liveBackend,
    super.key,
  });

  final FameverseBackend backend;
  final FameverseLiveBackend liveBackend;

  static const productShellKey = Key('fameverse-native-product-shell');
  static const splashKey = Key('fameverse-native-splash');
  static const updateNoticeKey = Key('fameverse-startup-update-notice');

  @override
  State<FameverseApp> createState() => _FameverseAppState();
}

class _FameverseAppState extends State<FameverseApp>
    with WidgetsBindingObserver {
  static const _lastAcknowledgedNoticeKey =
  
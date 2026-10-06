import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/fameverse_backend.dart';
import '../data/fameverse_live_backend.dart';
import '../data/startup_update_service.dart';
import '../features/auth/auth_screen.dart';
import '../features/shell/fameverse_shell_build23.dart';
part 'fameverse_app_widgets.part.dart';


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

class _FameverseAppState extends State<FameverseApp> {
  static const _lastAcknowledgedNoticeKey =
      'fameverse.last_acknowledged_update_notice_id';

  StreamSubscription<FvIdentity?>? _subscription;
  Timer? _splashTimer;
  FvIdentity? _identity;
  FvStartupUpdateNotice? _startupNotice;
  bool _splashComplete = false;
  bool _updateCheckComplete = false;
  bool _noticeAcknowledged = false;

  @override
  void initState() {
    super.initState();
    _identity = widget.backend.currentIdentity;
    _subscription = widget.backend.authChanges.listen((identity) {
      if (mounted) setState(() => _identity = identity);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _splashTimer != null) return;
      _splashTimer = Timer(const Duration(milliseconds: 2500), () {
        if (mounted) setState(() => _splashComplete = true);
      });
    });
    unawaited(_loadStartupNotice());
  }

  Future<void> _loadStartupNotice() async {
    try {
      final notice = await FvStartupUpdateService(
        Supabase.instance.client,
      ).loadLatest(channel: 'internal');

      if (notice == null) {
        if (mounted) setState(() => _updateCheckComplete = true);
        return;
      }

      final preferences = await SharedPreferences.getInstance();
      final lastAcknowledged = preferences.getString(
        _lastAcknowledgedNoticeKey,
      );
      final shouldShow = notice.id.isNotEmpty && notice.id != lastAcknowledged;

      if (!mounted) return;
      setState(() {
        _startupNotice = shouldShow ? notice : null;
        _noticeAcknowledged = !shouldShow;
        _updateCheckComplete = true;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _updateCheckComplete = true);
    }
  }

  Future<void> _acknowledgeStartupNotice() async {
    final notice = _startupNotice;
    if (notice == null) {
      if (mounted) setState(() => _noticeAcknowledged = true);
      return;
    }

    try {
      final preferences = await SharedPreferences.getInstance();
      if (notice.id.isNotEmpty) {
        await preferences.setString(_lastAcknowledgedNoticeKey, notice.id);
      }
    } catch (_) {
      // Local persistence failure must not trap a user on the update notice.
    }

    if (mounted) setState(() => _noticeAcknowledged = true);
  }

  @override
  void dispose() {
    _splashTimer?.cancel();
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF9D55FF),
      brightness: Brightness.dark,
      surface: const Color(0xFF100B15),
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Fameverse',
      theme: ThemeData(
        colorScheme: scheme,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0C0810),
        useMaterial3: true,
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: const Color(0xFF120D17),
          indicatorColor: const Color(0xFF39234F),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            return TextStyle(
              fontSize: 11,
              fontWeight: states.contains(WidgetState.selected)
                  ? FontWeight.w800
                  : FontWeight.w600,
              color: states.contains(WidgetState.selected)
                  ? Colors.white
                  : const Color(0xFFA79DAF),
            );
          }),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF17121E),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
        ),
      ),
      home: KeyedSubtree(
        key: FameverseApp.productShellKey,
        child: _buildStartupRoute(),
      ),
    );
  }

  Widget _buildStartupRoute() {
    if (!_splashComplete || !_updateCheckComplete) {
      return const _BrandSplash();
    }

    final notice = _startupNotice;
    if (notice != null && !_noticeAcknowledged) {
      return _StartupUpdateNoticeScreen(
        key: FameverseApp.updateNoticeKey,
        notice: notice,
        onContinue: () => unawaited(_acknowledgeStartupNotice()),
      );
    }

    if (_identity == null) {
      return AuthScreen(backend: widget.backend);
    }

    return FameverseBuild23Shell(
      key: ValueKey(_identity!.id),
      backend: widget.backend,
      liveBackend: widget.liveBackend,
      identity: _identity!,
    );
  }
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/fameverse_backend.dart';
import '../data/fameverse_live_backend.dart';
import '../data/startup_update_service.dart';
import '../features/auth/auth_screen.dart';
import '../features/shell/fameverse_shell_build23.dart';

/// Build 23 native Fameverse app shell.
///
/// Regression laws:
/// - The installed Build 23 binary must route through the Build 23 shell.
/// - Active backend/app notices must be surfaced before the product shell opens.
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
    _splashTimer = Timer(const Duration(milliseconds: 1050), () {
      if (mounted) setState(() => _splashComplete = true);
    });
    unawaited(_loadStartupNotice());
  }

  Future<void> _loadStartupNotice() async {
    try {
      final notice = await FvStartupUpdateService(
        Supabase.instance.client,
      ).loadLatest(channel: 'internal');
      if (!mounted) return;
      setState(() {
        _startupNotice = notice;
        _updateCheckComplete = true;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _updateCheckComplete = true);
    }
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
        onContinue: () => setState(() => _noticeAcknowledged = true),
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

class _StartupUpdateNoticeScreen extends StatelessWidget {
  const _StartupUpdateNoticeScreen({
    required this.notice,
    required this.onContinue,
    super.key,
  });

  final FvStartupUpdateNotice notice;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final versionBits = <String>[
      if (notice.versionLabel != null && notice.versionLabel!.trim().isNotEmpty)
        notice.versionLabel!.trim(),
      if (notice.buildNumber != null) 'Build ${notice.buildNumber}',
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF08060B),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 36, 22, 28),
          children: [
            const _UpdateMark(),
            const SizedBox(height: 28),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
              decoration: BoxDecoration(
                color: const Color(0xFF301844),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: const Color(0xFF75449A)),
              ),
              child: Text(
                notice.badgeLabel,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFFD69BFF),
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.3,
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              notice.title,
              style: const TextStyle(
                fontSize: 30,
                height: 1.05,
                fontWeight: FontWeight.w900,
                letterSpacing: -.6,
              ),
            ),
            if (versionBits.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                versionBits.join(' • '),
                style: const TextStyle(
                  color: Color(0xFFC287E9),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
            const SizedBox(height: 14),
            if (notice.summary.trim().isNotEmpty)
              Text(
                notice.summary,
                style: const TextStyle(
                  color: Color(0xFFC3B7C7),
                  fontSize: 15,
                  height: 1.5,
                ),
              ),
            if (notice.changelog.isNotEmpty) ...[
              const SizedBox(height: 26),
              const Text(
                'WHAT CHANGED',
                style: TextStyle(
                  color: Color(0xFF988B9E),
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.4,
                ),
              ),
              const SizedBox(height: 10),
              ...notice.changelog.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 5),
                        child: Icon(
                          Icons.auto_awesome_rounded,
                          size: 13,
                          color: Color(0xFFBB71EF),
                        ),
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Text(
                          item,
                          style: const TextStyle(
                            color: Color(0xFFB8ADBb),
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 28),
            FilledButton.icon(
              key: const Key('startup-update-continue'),
              onPressed: onContinue,
              icon: const Icon(Icons.arrow_forward_rounded),
              label: const Text('Continue to Fameverse'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(54),
                textStyle: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'This notice comes from the Fameverse backend release channel. It does not install a new binary by itself.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF776F7A),
                fontSize: 10,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UpdateMark extends StatelessWidget {
  const _UpdateMark();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 92,
        height: 92,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFF8149AE), width: 2),
          gradient: const RadialGradient(
            colors: [Color(0xFF3C1854), Color(0xFF130B19)],
          ),
          boxShadow: const [
            BoxShadow(color: Color(0x554A1467), blurRadius: 32, spreadRadius: 2),
          ],
        ),
        child: const Icon(
          Icons.system_update_alt_rounded,
          size: 42,
          color: Color(0xFFD29BFF),
        ),
      ),
    );
  }
}

class _BrandSplash extends StatelessWidget {
  const _BrandSplash();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: FameverseApp.splashKey,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -.42),
            radius: 1.15,
            colors: [Color(0xFF1D0B2B), Color(0xFF0B0810), Color(0xFF050507)],
            stops: [0, .58, 1],
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            const _GlowField(),
            SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const _FameverseMark(),
                      const SizedBox(height: 22),
                      const Text(
                        'FAMEVERSE',
                        style: TextStyle(
                          fontSize: 29,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 3.4,
                        ),
                      ),
                      const SizedBox(height: 9),
                      const Text(
                        'CREATORS. FANS. FOREVER.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFFA99AAF),
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2.4,
                        ),
                      ),
                      const SizedBox(height: 42),
                      SizedBox(
                        width: 112,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: const LinearProgressIndicator(
                            minHeight: 4,
                            backgroundColor: Color(0xFF24172C),
                            color: Color(0xFFB86BFF),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlowField extends StatelessWidget {
  const _GlowField();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            top: -110,
            left: -80,
            child: Container(
              width: 280,
              height: 280,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [Color(0x332A68FF), Color(0x00000000)],
                ),
              ),
            ),
          ),
          Positioned(
            top: 90,
            right: -120,
            child: Container(
              width: 320,
              height: 320,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [Color(0x33B44CFF), Color(0x00000000)],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FameverseMark extends StatelessWidget {
  const _FameverseMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 116,
      height: 116,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFF8D4FC7), width: 2),
        gradient: const RadialGradient(
          colors: [Color(0xFF3B1751), Color(0xFF130B19)],
        ),
        boxShadow: const [
          BoxShadow(color: Color(0x553E1059), blurRadius: 34, spreadRadius: 3),
        ],
      ),
      child: const Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            top: 19,
            child: Icon(
              Icons.workspace_premium_rounded,
              size: 42,
              color: Color(0xFFC57BFF),
            ),
          ),
          Positioned(
            bottom: 18,
            child: Text(
              'F',
              style: TextStyle(
                fontSize: 48,
                height: 1,
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
                color: Color(0xFFE1AEFF),
                shadows: [Shadow(color: Color(0xFFB34DFF), blurRadius: 15)],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

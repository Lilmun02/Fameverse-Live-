import 'dart:async';

import 'package:flutter/material.dart';

import '../data/backend_runtime.dart';
import '../data/fameverse_backend.dart';
import '../data/fameverse_live_backend.dart';
import '../features/auth/auth_screen.dart';
import '../features/shell/fameverse_release_shell.dart';

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

  @override
  State<FameverseApp> createState() => _FameverseAppState();
}

enum _StartupStage { splash, whatsNew, allSet, ready }

class _FameverseAppState extends State<FameverseApp> {
  StreamSubscription<FvIdentity?>? _subscription;
  FvIdentity? _identity;
  _StartupStage _startupStage = _StartupStage.splash;

  @override
  void initState() {
    super.initState();
    _identity = widget.backend.currentIdentity;
    _subscription = widget.backend.authChanges.listen((identity) {
      if (mounted) setState(() => _identity = identity);
    });
    unawaited(_finishBrandSplash());
  }

  Future<void> _finishBrandSplash() async {
    await Future<void>.delayed(const Duration(milliseconds: 1050));
    if (!mounted) return;
    final hasRealUpdate =
        FvBackendRuntime.backendChangedThisLaunch &&
        FvBackendRuntime.pendingNotice != null;
    setState(
      () => _startupStage = hasRealUpdate
          ? _StartupStage.whatsNew
          : _StartupStage.ready,
    );
  }

  Future<void> _continueFromWhatsNew() async {
    FvBackendRuntime.clearPendingNotice();
    if (!mounted) return;
    setState(() => _startupStage = _StartupStage.allSet);
    await Future<void>.delayed(const Duration(milliseconds: 650));
    if (mounted) setState(() => _startupStage = _StartupStage.ready);
  }

  @override
  void dispose() {
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
        child: _buildStartupSurface(),
      ),
    );
  }

  Widget _buildStartupSurface() {
    switch (_startupStage) {
      case _StartupStage.splash:
        return const _BrandSplash();
      case _StartupStage.whatsNew:
        final notice = FvBackendRuntime.pendingNotice;
        if (notice == null) return const _BrandSplash();
        return _WhatsNewScreen(
          notice: notice,
          onContinue: _continueFromWhatsNew,
        );
      case _StartupStage.allSet:
        return const _BrandSplash(
          status: 'You’re all set!',
          detail: 'Fameverse is up to date.',
          showCheck: true,
        );
      case _StartupStage.ready:
        if (!FvBackendRuntime.manifest.featureEnabled('app_enabled')) {
          return const _MaintenanceSurface();
        }
        if (_identity == null) {
          return AuthScreen(backend: widget.backend);
        }
        return FameverseReleaseShell(
          key: ValueKey(_identity!.id),
          backend: widget.backend,
          liveBackend: widget.liveBackend,
          identity: _identity!,
        );
    }
  }
}

class _BrandSplash extends StatelessWidget {
  const _BrandSplash({
    this.status,
    this.detail,
    this.showCheck = false,
  });

  final String? status;
  final String? detail;
  final bool showCheck;

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
                        'PEOPLE MAKE LEGENDS',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFFA99AAF),
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2.4,
                        ),
                      ),
                      if (status != null) ...[
                        const SizedBox(height: 34),
                        if (showCheck)
                          const Icon(
                            Icons.check_circle_rounded,
                            size: 36,
                            color: Color(0xFFBE77FF),
                          ),
                        if (showCheck) const SizedBox(height: 12),
                        Text(
                          status!,
                          key: const Key('startup-update-status'),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        if (detail != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            detail!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Color(0xFF9F92A5),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ],
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

class _WhatsNewScreen extends StatelessWidget {
  const _WhatsNewScreen({required this.notice, required this.onContinue});

  final FvStartupUpdateNotice notice;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('startup-whats-new'),
      backgroundColor: const Color(0xFF08060A),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(22, 30, 22, 34),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Center(child: _FameverseMark()),
                  const SizedBox(height: 25),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF321A40),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        notice.badgeLabel,
                        style: const TextStyle(
                          color: Color(0xFFE0B9FF),
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    notice.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  if (notice.summary.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      notice.summary,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFFB2A5B8),
                        height: 1.45,
                      ),
                    ),
                  ],
                  if (notice.changelog.isNotEmpty) ...[
                    const SizedBox(height: 22),
                    Container(
                      padding: const EdgeInsets.all(17),
                      decoration: BoxDecoration(
                        color: const Color(0xFF141018),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: const Color(0xFF382740)),
                      ),
                      child: Column(
                        children: notice.changelog
                            .map(
                              (item) => Padding(
                                padding: const EdgeInsets.symmetric(vertical: 7),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(
                                      Icons.auto_awesome_rounded,
                                      size: 16,
                                      color: Color(0xFFBF7AFF),
                                    ),
                                    const SizedBox(width: 9),
                                    Expanded(
                                      child: Text(
                                        item,
                                        style: const TextStyle(height: 1.35),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  FilledButton(
                    key: const Key('startup-update-continue'),
                    onPressed: onContinue,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Continue to Fameverse'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MaintenanceSurface extends StatelessWidget {
  const _MaintenanceSurface();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      key: Key('backend-maintenance-surface'),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _FameverseMark(),
                SizedBox(height: 24),
                Text(
                  'Fameverse is updating',
                  style: TextStyle(fontSize: 23, fontWeight: FontWeight.w900),
                ),
                SizedBox(height: 8),
                Text(
                  'A service update is in progress. Reopen Fameverse in a moment.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFFAA9CAF), height: 1.4),
                ),
              ],
            ),
          ),
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

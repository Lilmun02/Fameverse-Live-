import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/fameverse_backend.dart';
import '../data/fameverse_live_backend.dart';
import '../data/startup_update_service.dart';
import '../features/auth/auth_screen.dart';
import '../features/shell/fameverse_shell_build16.dart';

const _releaseChannel = String.fromEnvironment(
  'FAMEVERSE_RELEASE_CHANNEL',
  defaultValue: 'internal',
);

enum _StartupPhase { brand, checking, syncing, ready, unavailable }

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

class _FameverseAppState extends State<FameverseApp> {
  StreamSubscription<FvIdentity?>? _subscription;
  FvIdentity? _identity;
  FvStartupUpdateNotice? _startupNotice;
  _StartupPhase _startupPhase = _StartupPhase.brand;
  bool _splashComplete = false;

  @override
  void initState() {
    super.initState();
    _identity = widget.backend.currentIdentity;
    _subscription = widget.backend.authChanges.listen((identity) {
      if (mounted) setState(() => _identity = identity);
    });
    unawaited(_runStartupCheck());
  }

  Future<void> _runStartupCheck() async {
    if (mounted) {
      setState(() {
        _startupNotice = null;
        _startupPhase = _StartupPhase.brand;
      });
    }

    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    setState(() => _startupPhase = _StartupPhase.checking);

    try {
      final notice = await FvStartupUpdateService(Supabase.instance.client)
          .loadLatest(channel: _releaseChannel)
          .timeout(const Duration(seconds: 4));

      if (!mounted) return;
      if (notice != null) {
        setState(() {
          _startupNotice = notice;
          _startupPhase = _StartupPhase.syncing;
        });
        await Future<void>.delayed(const Duration(milliseconds: 850));
        if (!mounted) return;
      }

      setState(() => _startupPhase = _StartupPhase.ready);
    } catch (_) {
      if (!mounted) return;
      setState(() => _startupPhase = _StartupPhase.unavailable);
    }
  }

  void _enterApp() {
    if (!mounted || _splashComplete) return;
    setState(() => _splashComplete = true);
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
        child: !_splashComplete
            ? _FameverseStartupGate(
                phase: _startupPhase,
                notice: _startupNotice,
                onContinue: _enterApp,
                onRetry: _runStartupCheck,
              )
            : _identity == null
            ? AuthScreen(backend: widget.backend)
            : FameverseBuild16Shell(
                key: ValueKey(_identity!.id),
                backend: widget.backend,
                liveBackend: widget.liveBackend,
                identity: _identity!,
              ),
      ),
    );
  }
}

class _FameverseStartupGate extends StatelessWidget {
  const _FameverseStartupGate({
    required this.phase,
    required this.notice,
    required this.onContinue,
    required this.onRetry,
  });

  final _StartupPhase phase;
  final FvStartupUpdateNotice? notice;
  final VoidCallback onContinue;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: FameverseApp.splashKey,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -.42),
            radius: 1.15,
            colors: <Color>[
              Color(0xFF1D0B2B),
              Color(0xFF0B0810),
              Color(0xFF050507),
            ],
            stops: <double>[0, .58, 1],
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            const _StartupGlowField(),
            SafeArea(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 360),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                child: switch (phase) {
                  _StartupPhase.brand => const _BrandSplash(
                      key: ValueKey<String>('brand'),
                    ),
                  _StartupPhase.checking => const _StartupProgressScreen(
                      key: ValueKey<String>('checking'),
                      icon: Icons.sync_rounded,
                      title: 'Checking for updates…',
                      subtitle: 'Connecting to Fameverse services',
                      progress: .38,
                    ),
                  _StartupPhase.syncing => _StartupProgressScreen(
                      key: const ValueKey<String>('syncing'),
                      icon: Icons.cloud_download_rounded,
                      title: _syncTitle(notice),
                      subtitle: 'Preparing the latest Fameverse experience',
                      progress: .72,
                    ),
                  _StartupPhase.ready => _StartupReadyScreen(
                      key: const ValueKey<String>('ready'),
                      notice: notice,
                      onContinue: onContinue,
                    ),
                  _StartupPhase.unavailable => _StartupUnavailableScreen(
                      key: const ValueKey<String>('unavailable'),
                      onContinue: onContinue,
                      onRetry: onRetry,
                    ),
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _syncTitle(FvStartupUpdateNotice? notice) {
    return switch (notice?.updateType) {
      'app' => 'Checking app update…',
      'maintenance' => 'Refreshing Fameverse services…',
      'feature' => 'Loading what’s new…',
      _ => 'Syncing Fameverse services…',
    };
  }
}

class _StartupGlowField extends StatelessWidget {
  const _StartupGlowField();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: <Widget>[
          Positioned(
            top: -110,
            left: -80,
            child: Container(
              width: 280,
              height: 280,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: <Color>[Color(0x332A68FF), Color(0x00000000)],
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
                  colors: <Color>[Color(0x33B44CFF), Color(0x00000000)],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BrandSplash extends StatelessWidget {
  const _BrandSplash({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _FameverseMark(),
            SizedBox(height: 22),
            Text(
              'FAMEVERSE',
              style: TextStyle(
                fontSize: 29,
                fontWeight: FontWeight.w900,
                letterSpacing: 3.4,
              ),
            ),
            SizedBox(height: 9),
            Text(
              'CREATORS. FANS. FOREVER.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFFA99AAF),
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 2.4,
              ),
            ),
            SizedBox(height: 48),
            SizedBox(
              width: 118,
              child: _StartupProgressBar(progress: .16),
            ),
            SizedBox(height: 12),
            Text(
              'Starting up…',
              style: TextStyle(color: Color(0xFF8D8194), fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

class _FameverseMark extends StatelessWidget {
  const _FameverseMark();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 128,
      height: 128,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          Container(
            width: 112,
            height: 112,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: <Color>[
                  Color(0x557A2FFF),
                  Color(0x222A0C3D),
                  Color(0x00000000),
                ],
              ),
            ),
          ),
          const CustomPaint(
            size: Size(118, 118),
            painter: _CrownPainter(),
          ),
          const Padding(
            padding: EdgeInsets.only(top: 32),
            child: Text(
              'F',
              style: TextStyle(
                fontSize: 58,
                height: 1,
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
                letterSpacing: -7,
                color: Color(0xFFE4B2FF),
                shadows: <Shadow>[
                  Shadow(color: Color(0xFFB34DFF), blurRadius: 18),
                  Shadow(color: Color(0xFF6F39FF), blurRadius: 34),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CrownPainter extends CustomPainter {
  const _CrownPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width * .18, size.height * .37)
      ..lineTo(size.width * .36, size.height * .49)
      ..lineTo(size.width * .50, size.height * .21)
      ..lineTo(size.width * .64, size.height * .49)
      ..lineTo(size.width * .82, size.height * .37)
      ..lineTo(size.width * .76, size.height * .63)
      ..lineTo(size.width * .24, size.height * .63)
      ..close();

    final glow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round
      ..color = const Color(0x557D3BFF)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawPath(path, glow);

    final crown = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round
      ..shader = const LinearGradient(
        colors: <Color>[
          Color(0xFF9D63FF),
          Color(0xFFC85EFF),
          Color(0xFFF0A0FF),
        ],
      ).createShader(Offset.zero & size);
    canvas.drawPath(path, crown);

    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..shader = const LinearGradient(
        colors: <Color>[Color(0xFF9D63FF), Color(0xFFE79BFF)],
      ).createShader(Offset.zero & size);
    canvas.drawLine(
      Offset(size.width * .29, size.height * .70),
      Offset(size.width * .71, size.height * .70),
      base,
    );

    final dot = Paint()..color = const Color(0xFFD67BFF);
    canvas.drawCircle(
      Offset(size.width * .18, size.height * .37),
      4.5,
      dot,
    );
    canvas.drawCircle(
      Offset(size.width * .50, size.height * .21),
      4.5,
      dot,
    );
    canvas.drawCircle(
      Offset(size.width * .82, size.height * .37),
      4.5,
      dot,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _StartupProgressScreen extends StatelessWidget {
  const _StartupProgressScreen({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.progress,
    super.key,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 34, vertical: 28),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 390),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF24132F),
                  border: Border.all(color: const Color(0xFF4D2B68)),
                  boxShadow: const <BoxShadow>[
                    BoxShadow(
                      color: Color(0x443A1A56),
                      blurRadius: 38,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: Icon(icon, size: 42, color: const Color(0xFFC792FF)),
              ),
              const SizedBox(height: 30),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -.35,
                ),
              ),
              const SizedBox(height: 9),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFFAFA3B7),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 30),
              _StartupProgressBar(progress: progress),
              const SizedBox(height: 14),
              const Text(
                'Fameverse service check · not a signal-strength meter',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF756D7B), fontSize: 10.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StartupProgressBar extends StatelessWidget {
  const _StartupProgressBar({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 7,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(99),
        color: const Color(0xFF2A2132),
      ),
      clipBehavior: Clip.antiAlias,
      child: TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 620),
        curve: Curves.easeOutCubic,
        tween: Tween<double>(begin: 0, end: progress),
        builder: (context, value, child) {
          return FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: value.clamp(0, 1),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(99),
                gradient: const LinearGradient(
                  colors: <Color>[Color(0xFF7C4DFF), Color(0xFFC355FF)],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _StartupReadyScreen extends StatelessWidget {
  const _StartupReadyScreen({required this.notice, required this.onContinue, super.key});

  final FvStartupUpdateNotice? notice;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final notice = this.notice;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 42, 24, 28),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: Column(
            children: <Widget>[
              Container(
                width: 74,
                height: 74,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF0F6C51),
                  boxShadow: <BoxShadow>[
                    BoxShadow(color: Color(0x334AE6B0), blurRadius: 28),
                  ],
                ),
                child: const Icon(
                  Icons.check_rounded,
                  size: 42,
                  color: Color(0xFF9FF5D5),
                ),
              ),
              const SizedBox(height: 22),
              const Text(
                'You’re all set!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 25, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 7),
              Text(
                notice == null
                    ? 'Fameverse is up to date.'
                    : 'Fameverse services are ready.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFFAFA3B7), fontSize: 13),
              ),
              if (notice != null) ...<Widget>[
                const SizedBox(height: 26),
                _StartupChangelogCard(notice: notice),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: onContinue,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF8A35FF),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Continue to App',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StartupUnavailableScreen extends StatelessWidget {
  const _StartupUnavailableScreen({
    required this.onContinue,
    required this.onRetry,
    super.key,
  });

  final VoidCallback onContinue;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 30),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const _FameverseMark(),
              const SizedBox(height: 24),
              const Text(
                'Update check unavailable',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 9),
              const Text(
                'We couldn’t reach the Fameverse update service. This does not mean your mobile signal is weak, and you can still enter the app.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFFB5A9BC), height: 1.45),
              ),
              const SizedBox(height: 26),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton(
                  onPressed: onRetry,
                  child: const Text('Try Again'),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  onPressed: onContinue,
                  child: const Text('Continue to App'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StartupChangelogCard extends StatelessWidget {
  const _StartupChangelogCard({required this.notice});

  final FvStartupUpdateNotice notice;

  @override
  Widget build(BuildContext context) {
    final versionParts = <String>[
      if ((notice.versionLabel ?? '').isNotEmpty) 'v${notice.versionLabel}',
      if (notice.buildNumber != null) 'Build ${notice.buildNumber}',
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[Color(0xFF171020), Color(0xFF100C15)],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF4A2A62)),
        boxShadow: const <BoxShadow>[
          BoxShadow(color: Color(0x22000000), blurRadius: 22, offset: Offset(0, 12)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text(
                      'What’s New',
                      style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900),
                    ),
                    if (versionParts.isNotEmpty) ...<Widget>[
                      const SizedBox(height: 4),
                      Text(
                        versionParts.join(' · '),
                        style: const TextStyle(
                          color: Color(0xFFAFA3B7),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A1739),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  notice.badgeLabel,
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .7,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            notice.title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
          ),
          if (notice.summary.isNotEmpty) ...<Widget>[
            const SizedBox(height: 6),
            Text(
              notice.summary,
              style: const TextStyle(
                color: Color(0xFFC8BDCD),
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ],
          if (notice.changelog.isNotEmpty) ...<Widget>[
            const SizedBox(height: 16),
            ...notice.changelog.map(_changelogRow),
          ],
        ],
      ),
    );
  }

  Widget _changelogRow(String item) {
    final lower = item.toLowerCase();
    final (icon, color) = switch (lower) {
      final text when text.contains('coin') => (
          Icons.monetization_on_rounded,
          const Color(0xFFFFC45C),
        ),
      final text when text.contains('live') => (
          Icons.live_tv_rounded,
          const Color(0xFF62D7FF),
        ),
      final text when text.contains('profile') => (
          Icons.person_rounded,
          const Color(0xFFB984FF),
        ),
      final text when text.contains('payout') => (
          Icons.account_balance_wallet_rounded,
          const Color(0xFF75E5B4),
        ),
      _ => (Icons.auto_awesome_rounded, const Color(0xFFC17BFF)),
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: color.withValues(alpha: .13),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Text(
                item,
                style: const TextStyle(fontSize: 12.5, height: 1.35),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

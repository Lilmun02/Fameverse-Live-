import 'dart:async';

import 'package:flutter/material.dart';

import '../data/fameverse_backend.dart';
import '../data/fameverse_live_backend.dart';
import '../features/auth/auth_screen.dart';
import '../features/shell/fameverse_shell_build16.dart';

/// Native Fameverse app shell.
///
/// Candidate law: startup may show the brand splash once, but it must not replay
/// stale backend/build notices or pretend a backend sync is an app update. Tester
/// update UX will be introduced only after the current physical candidate passes.
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
  Timer? _splashTimer;
  FvIdentity? _identity;
  bool _splashComplete = false;

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
        child: !_splashComplete
            ? const _BrandSplash()
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

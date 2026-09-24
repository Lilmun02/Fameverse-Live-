import 'dart:async';

import 'package:flutter/material.dart';

import '../data/fameverse_backend.dart';
import '../data/fameverse_live_backend.dart';
import '../features/auth/auth_screen.dart';
import '../features/shell/fameverse_shell_build16.dart';

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
    _splashTimer = Timer(const Duration(milliseconds: 1800), () {
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
            ? const _FameverseSplash()
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

class _FameverseSplash extends StatelessWidget {
  const _FameverseSplash();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      key: FameverseApp.splashKey,
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -.2),
            radius: 1.1,
            colors: [Color(0xFF351151), Color(0xFF130A1B), Color(0xFF09070B)],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'F',
                style: TextStyle(
                  fontSize: 64,
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                  letterSpacing: -6,
                ),
              ),
              SizedBox(height: 12),
              Text(
                'FAMEVERSE',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 4,
                ),
              ),
              SizedBox(height: 24),
              SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

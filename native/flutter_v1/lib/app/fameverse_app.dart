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
  bool _splashComplete = false;
  bool _startupBusy = true;
  String _startupStatus = 'Starting Fameverse…';

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
    await Future<void>.delayed(const Duration(milliseconds: 250));
    if (!mounted) return;
    setState(() => _startupStatus = 'Checking for Fameverse updates…');

    try {
      final notice = await FvStartupUpdateService(
        Supabase.instance.client,
      ).loadLatest(channel: _releaseChannel).timeout(const Duration(seconds: 4));

      if (!mounted) return;
      if (notice == null) {
        setState(() {
          _startupBusy = false;
          _startupStatus = 'You’re up to date.';
        });
        await Future<void>.delayed(const Duration(milliseconds: 550));
        _enterApp();
        return;
      }

      setState(() => _startupStatus = 'Syncing Fameverse services…');
      await Future<void>.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;
      setState(() {
        _startupNotice = notice;
        _startupBusy = false;
        _startupStatus = 'Update ready.';
      });

      if (!notice.requiresAcknowledgement) {
        await Future<void>.delayed(const Duration(milliseconds: 650));
        _enterApp();
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _startupBusy = false;
        _startupStatus = 'Update check unavailable — continuing to Fameverse.';
      });
      await Future<void>.delayed(const Duration(milliseconds: 850));
      _enterApp();
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
            ? _FameverseSplash(
                status: _startupStatus,
                busy: _startupBusy,
                notice: _startupNotice,
                onContinue: _enterApp,
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

class _FameverseSplash extends StatelessWidget {
  const _FameverseSplash({
    required this.status,
    required this.busy,
    required this.notice,
    required this.onContinue,
  });

  final String status;
  final bool busy;
  final FvStartupUpdateNotice? notice;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final notice = this.notice;
    return Scaffold(
      key: FameverseApp.splashKey,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -.35),
            radius: 1.2,
            colors: [Color(0xFF2B103F), Color(0xFF120A19), Color(0xFF080609)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 34, 24, 26),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Column(
                  children: <Widget>[
                    const Text(
                      'F',
                      style: TextStyle(
                        fontSize: 64,
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.italic,
                        letterSpacing: -6,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'FAMEVERSE',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 4,
                      ),
                    ),
                    const SizedBox(height: 28),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF17101F).withValues(alpha: .9),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFF372445)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              Icon(
                                busy
                                    ? Icons.cloud_sync_rounded
                                    : Icons.check_circle_rounded,
                                size: 20,
                                color: busy
                                    ? const Color(0xFFB783FF)
                                    : const Color(0xFF75E5B4),
                              ),
                              const SizedBox(width: 9),
                              Expanded(
                                child: Text(
                                  status,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (busy) ...<Widget>[
                            const SizedBox(height: 14),
                            const ClipRRect(
                              borderRadius: BorderRadius.all(Radius.circular(99)),
                              child: LinearProgressIndicator(minHeight: 4),
                            ),
                            const SizedBox(height: 9),
                            const Text(
                              'Fameverse is checking its services — this is not a signal-strength warning.',
                              style: TextStyle(
                                color: Color(0xFFBFB4C7),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (notice != null) ...<Widget>[
                      const SizedBox(height: 16),
                      _StartupChangelogCard(notice: notice),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: busy ? null : onContinue,
                          icon: const Icon(Icons.arrow_forward_rounded),
                          label: const Text('Continue to app'),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
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
        color: const Color(0xFF120D17).withValues(alpha: .96),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF4D2B68)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFF2C1740),
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text(
              notice.badgeLabel,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: .8,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            notice.title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          ),
          if (versionParts.isNotEmpty) ...<Widget>[
            const SizedBox(height: 4),
            Text(
              versionParts.join(' · '),
              style: const TextStyle(
                color: Color(0xFFBBAFC3),
                fontSize: 12,
              ),
            ),
          ],
          if (notice.summary.isNotEmpty) ...<Widget>[
            const SizedBox(height: 10),
            Text(
              notice.summary,
              style: const TextStyle(color: Color(0xFFD7CDD9), height: 1.35),
            ),
          ],
          if (notice.changelog.isNotEmpty) ...<Widget>[
            const SizedBox(height: 16),
            const Text(
              'What’s new',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            ...notice.changelog.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 7),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Padding(
                      padding: EdgeInsets.only(top: 3),
                      child: Icon(
                        Icons.auto_awesome_rounded,
                        size: 13,
                        color: Color(0xFFB783FF),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(item)),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

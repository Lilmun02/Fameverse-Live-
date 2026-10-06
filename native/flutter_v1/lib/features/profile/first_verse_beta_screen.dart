import 'dart:ui';

import 'package:flutter/material.dart';

import '../../data/fameverse_beta_backend.dart';
part 'first_verse_widgets.part.dart';


class FirstVerseBetaScreen extends StatefulWidget {
  const FirstVerseBetaScreen({this.backend, super.key});

  final FameverseBetaBackend? backend;

  @override
  State<FirstVerseBetaScreen> createState() => _FirstVerseBetaScreenState();
}

class _FirstVerseBetaScreenState extends State<FirstVerseBetaScreen> {
  late final FameverseBetaBackend _backend;
  FvBetaProgramStatus? _status;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _backend = widget.backend ?? SupabaseFameverseBetaBackend.instance;
    _load();
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final status = await _backend.loadProgramStatus();
      if (!mounted) return;
      setState(() {
        _status = status;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Beta progress could not load. Pull to try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = _status;
    return Scaffold(
      key: const Key('first-verse-beta-screen'),
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'First Verse',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 34),
            children: [
              if (_loading && status == null)
                const _LoadingCard()
              else if (_error != null && status == null)
                _MessageCard(
                  icon: Icons.sync_problem_rounded,
                  title: 'Progress unavailable',
                  body: _error!,
                )
              else if (status == null || !status.enrolled)
                const _MessageCard(
                  icon: Icons.lock_outline_rounded,
                  title: 'Beta access is not active',
                  body:
                      'First Verse progress is only available to enrolled external Fameverse beta testers.',
                )
              else ...[
                _FirstVerseHero(status: status),
                const SizedBox(height: 24),
                const _SectionTitle('REQUIRED BETA MISSIONS'),
                const SizedBox(height: 9),
                ...fvFirstVerseMissions
                    .where((mission) => mission.required)
                    .map(
                      (mission) => Padding(
                        padding: const EdgeInsets.only(bottom: 9),
                        child: _MissionCard(
                          mission: mission,
                          completed: status.completed(mission.key),
                        ),
                      ),
                    ),
                const SizedBox(height: 18),
                const _SectionTitle('BONUS CHECKS'),
                const SizedBox(height: 9),
                ...fvFirstVerseMissions
                    .where((mission) => !mission.required)
                    .map(
                      (mission) => Padding(
                        padding: const EdgeInsets.only(bottom: 9),
                        child: _MissionCard(
                          mission: mission,
                          completed: status.completed(mission.key),
                        ),
                      ),
                    ),
                const SizedBox(height: 14),
                const _TesterSafetyNote(),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

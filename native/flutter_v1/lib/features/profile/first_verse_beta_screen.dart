import 'dart:ui';

import 'package:flutter/material.dart';

import '../../data/fameverse_beta_backend.dart';

class FirstVerseBetaScreen extends StatefulWidget {
  const FirstVerseBetaScreen({this.backend, this.ownerPreview = false, super.key});

  /// A clear owner-only preview does not grant First Verse.
  final bool ownerPreview;

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
              else if (status == null || (!status.enrolled && !widget.ownerPreview))
                const _MessageCard(
                  icon: Icons.lock_outline_rounded,
                  title: 'Beta access is not active',
                  body:
                      'First Verse progress is only available to enrolled external Fameverse beta testers.',
                )
              else ...[
                _FirstVerseHero(status: status, ownerPreview: widget.ownerPreview),
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

class _FirstVerseHero extends StatelessWidget {
  const _FirstVerseHero({required this.status, required this.ownerPreview});

  final FvBetaProgramStatus status;
  final bool ownerPreview;

  @override
  Widget build(BuildContext context) {
    final unlocked = status.badgeUnlocked;
    return Container(
      key: const Key('first-verse-progress-card'),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: unlocked ? const Color(0xFFB96BFF) : const Color(0xFF4A3155),
        ),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF271334), Color(0xFF130D18), Color(0xFF09070B)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _BadgePreview(unlocked: unlocked, ownerPreview: ownerPreview),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      unlocked
                           ? 'First Verse earned'
                           : ownerPreview
                           ? 'Owner preview · not yet earned'
                           : 'Your badge is waiting',
                      style: const TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      unlocked
                          ? 'You completed the required external beta checks. This legacy badge stays with your account.'
                          : ownerPreview
                           ? 'This is a clear owner preview only. Enrolled testers must complete all eight required missions to earn First Verse.'
                           : 'Complete the required beta missions to reveal and permanently unlock First Verse.',
                      style: const TextStyle(
                        color: Color(0xFFB8ACBC),
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Text(
                '${status.completedRequired}/${status.requiredTotal} required tests',
                key: const Key('first-verse-progress-text'),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Spacer(),
              Text(
                '${(status.progress * 100).round()}%',
                style: const TextStyle(
                  color: Color(0xFFD7A5FF),
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              key: const Key('first-verse-progress-bar'),
              minHeight: 10,
              value: status.progress,
              backgroundColor: const Color(0xFF241B28),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFFA653F2),
              ),
            ),
          ),
          if (status.completedOptional > 0) ...[
            const SizedBox(height: 9),
            Text(
              '${status.completedOptional} bonus check${status.completedOptional == 1 ? '' : 's'} completed',
              style: const TextStyle(
                color: Color(0xFF938898),
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _BadgePreview extends StatelessWidget {
  const _BadgePreview({required this.unlocked, required this.ownerPreview});

  final bool unlocked;
  final bool ownerPreview;

  @override
  Widget build(BuildContext context) {
    final badge = Container(
      key: const Key('first-verse-badge-art'),
      width: 84,
      height: 84,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(
          colors: [Color(0xFFC679FF), Color(0xFF6C2CB8), Color(0xFF24102F)],
        ),
        border: Border.all(color: const Color(0xFFE1B7FF), width: 2),
        boxShadow: const [
          BoxShadow(color: Color(0x665C1B8A), blurRadius: 18, spreadRadius: 2),
        ],
      ),
      child: const Stack(
        alignment: Alignment.center,
        children: [
          Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 36),
          Positioned(
            bottom: 12,
            child: Text(
              'FV',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ],
      ),
    );

    if (unlocked || ownerPreview) return badge;
    return Stack(
      alignment: Alignment.center,
      children: [
        ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: 5.5, sigmaY: 5.5),
          child: Opacity(opacity: .55, child: badge),
        ),
        Container(
          width: 84,
          height: 84,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0x66000000),
          ),
          child: const Icon(
            Icons.lock_rounded,
            color: Color(0xFFE2C7F5),
            size: 27,
          ),
        ),
      ],
    );
  }
}

class _MissionCard extends StatelessWidget {
  const _MissionCard({required this.mission, required this.completed});

  final FvBetaMissionDefinition mission;
  final bool completed;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: Key('beta-mission-${mission.key}'),
      padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
      decoration: BoxDecoration(
        color: const Color(0xFF141017),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: completed ? const Color(0xFF5D3B70) : const Color(0xFF302638),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: completed
                  ? const Color(0xFF49215F)
                  : const Color(0xFF221B26),
            ),
            child: Icon(
              completed ? Icons.check_rounded : Icons.lock_outline_rounded,
              size: 20,
              color: completed
                  ? const Color(0xFFD7A0FF)
                  : const Color(0xFF817686),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        mission.title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    if (!mission.required)
                      const Text(
                        'BONUS',
                        style: TextStyle(
                          color: Color(0xFFA772C8),
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  mission.detail,
                  style: const TextStyle(
                    color: Color(0xFF9F94A3),
                    fontSize: 11,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TesterSafetyNote extends StatelessWidget {
  const _TesterSafetyNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF101015),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF2F2933)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.science_outlined, color: Color(0xFFB783D4), size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'First Verse missions cover normal app testing only. Real-money payout operations and private internal controls are never part of this external beta checklist.',
              style: TextStyle(
                color: Color(0xFFA59AA8),
                fontSize: 11,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFF8D8191),
        fontSize: 10,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.3,
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 220,
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF151116),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF342A39)),
      ),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFFB37BD6), size: 32),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF9F94A3),
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

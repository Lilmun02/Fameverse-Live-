import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/fameverse_beta_backend.dart';
import '../../data/fameverse_economy_backend.dart';

class FirstVerseBetaScreen extends StatefulWidget {
  const FirstVerseBetaScreen({
    this.backend,
    this.economyBackend,
    super.key,
  });

  final FameverseBetaBackend? backend;
  final SupabaseFameverseEconomyBackend? economyBackend;

  @override
  State<FirstVerseBetaScreen> createState() => _FirstVerseBetaScreenState();
}

class _FirstVerseBetaScreenState extends State<FirstVerseBetaScreen> {
  late final FameverseBetaBackend _backend;
  SupabaseFameverseEconomyBackend? _economyBackend;
  final TextEditingController _referralController = TextEditingController();

  FvBetaProgramStatus? _status;
  FvBetaReferralSummary _referralSummary = FvBetaReferralSummary.empty;
  String? _error;
  String? _referralError;
  bool _loading = true;
  bool _referralBusy = false;

  @override
  void initState() {
    super.initState();
    _backend = widget.backend ?? SupabaseFameverseBetaBackend.instance;
    _economyBackend = widget.economyBackend;
    _load();
  }

  @override
  void dispose() {
    _referralController.dispose();
    super.dispose();
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
      var referral = FvBetaReferralSummary.empty;
      final economy = _economyBackend;
      if (status.enrolled && economy != null) {
        try {
          await economy.ensureBetaReferralCode();
          referral = await economy.loadBetaReferralSummary();
        } catch (_) {
          // Referral availability must never hide First Verse progress.
        }
      }
      if (!mounted) return;
      setState(() {
        _status = status;
        _referralSummary = referral;
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

  Future<void> _copyReferralCode() async {
    final code = _referralSummary.referralCode;
    if (code == null || code.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: code));
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Referral code copied.')));
  }

  Future<void> _claimReferralCode() async {
    final code = _referralController.text.trim();
    if (code.isEmpty || _referralBusy) return;
    final economy = _economyBackend;
    if (economy == null) {
      setState(() => _referralError = 'Referral service is unavailable in this test shell.');
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _referralBusy = true;
      _referralError = null;
    });
    try {
      final result = await economy.qualifyBetaReferral(code);
      if (!mounted) return;
      _referralController.clear();
      setState(() => _referralBusy = false);
      await _load();
      if (!mounted) return;
      final message = result.accepted
          ? 'Referral qualified: you received ${result.referredRewardCoins} promo Fame Coins.'
          : 'That account already used a referral reward.';
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _referralBusy = false;
        _referralError = _friendlyReferralError(error);
      });
    }
  }

  String _friendlyReferralError(Object error) {
    final text = error.toString().toLowerCase();
    if (text.contains('self referral')) return 'You cannot use your own referral code.';
    if (text.contains('complete your fameverse profile')) {
      return 'Complete your Fameverse name and username before claiming referral coins.';
    }
    if (text.contains('referral code unavailable')) {
      return 'That referral code is not active.';
    }
    return 'Referral could not be applied. Check the code and try again.';
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
                const SizedBox(height: 22),
                const _SectionTitle('INVITE TO FAMEVERSE'),
                const SizedBox(height: 9),
                _ReferralCard(
                  summary: _referralSummary,
                  controller: _referralController,
                  busy: _referralBusy,
                  error: _referralError,
                  onCopy: _copyReferralCode,
                  onClaim: _claimReferralCode,
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
  const _FirstVerseHero({required this.status});

  final FvBetaProgramStatus status;

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
              _BadgePreview(unlocked: unlocked),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      unlocked ? 'First Verse earned' : 'Your badge is waiting',
                      style: const TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      unlocked
                          ? 'You completed the required external beta checks. This legacy badge stays with your account.'
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
  const _BadgePreview({required this.unlocked});

  final bool unlocked;

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

    if (unlocked) return badge;
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

class _ReferralCard extends StatelessWidget {
  const _ReferralCard({
    required this.summary,
    required this.controller,
    required this.busy,
    required this.error,
    required this.onCopy,
    required this.onClaim,
  });

  final FvBetaReferralSummary summary;
  final TextEditingController controller;
  final bool busy;
  final String? error;
  final VoidCallback onCopy;
  final VoidCallback onClaim;

  @override
  Widget build(BuildContext context) {
    final code = summary.referralCode;
    return Container(
      key: const Key('first-verse-referral-card'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF141017),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF4A3155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Bring someone into Fameverse',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 5),
          const Text(
            'You get 100 promo Fame Coins for each qualified referral. The person you bring gets 50 promo Fame Coins.',
            key: Key('first-verse-referral-reward-copy'),
            style: TextStyle(color: Color(0xFFB5A9B9), fontSize: 12, height: 1.4),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF0E0B10),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF35273C)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'YOUR REFERRAL CODE',
                        style: TextStyle(
                          color: Color(0xFF8F8394),
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        code ?? 'Generating…',
                        key: const Key('first-verse-referral-code'),
                        style: const TextStyle(
                          color: Color(0xFFE1B7FF),
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  key: const Key('first-verse-copy-referral-code'),
                  onPressed: code == null ? null : onCopy,
                  tooltip: 'Copy referral code',
                  icon: const Icon(Icons.copy_rounded),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '${summary.qualifiedReferrals} qualified · ${summary.promoCoinsEarned} promo coins earned',
            style: const TextStyle(
              color: Color(0xFFD0B3E3),
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Have a referral code?',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 7),
          Row(
            children: [
              Expanded(
                child: TextField(
                  key: const Key('first-verse-referral-input'),
                  controller: controller,
                  enabled: !busy,
                  textCapitalization: TextCapitalization.characters,
                  autocorrect: false,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => onClaim(),
                  decoration: const InputDecoration(
                    hintText: 'Enter code',
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                key: const Key('first-verse-claim-referral'),
                onPressed: busy ? null : onClaim,
                child: Text(busy ? 'Checking…' : 'Apply'),
              ),
            ],
          ),
          if (error != null) ...[
            const SizedBox(height: 8),
            Text(
              error!,
              style: const TextStyle(color: Color(0xFFFF8D9F), fontSize: 11),
            ),
          ],
          const SizedBox(height: 14),
          const _PromoCoinRule(),
          const SizedBox(height: 10),
          const Text(
            'Referral activity is separate from your First Verse badge missions and does not count toward badge progress.',
            key: Key('first-verse-referral-not-mission'),
            style: TextStyle(color: Color(0xFF8F8493), fontSize: 10, height: 1.35),
          ),
        ],
      ),
    );
  }
}

class _PromoCoinRule extends StatelessWidget {
  const _PromoCoinRule();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('first-verse-promo-coin-rule'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF211328),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF51325F)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.redeem_rounded, color: Color(0xFFD19BFF), size: 19),
          SizedBox(width: 9),
          Expanded(
            child: Text(
              'Promo Fame Coins are gifting-only. They cannot be transferred, exchanged, converted, replaced, or cashed out. Gifts funded by promo coins do not create creator cash earnings.',
              style: TextStyle(color: Color(0xFFC6B6CC), fontSize: 10.5, height: 1.4),
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

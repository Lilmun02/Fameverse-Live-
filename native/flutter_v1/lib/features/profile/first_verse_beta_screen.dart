import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/fameverse_beta_backend.dart';
import '../../data/fameverse_economy_backend.dart';

class FirstVerseBetaScreen extends StatefulWidget {
  const FirstVerseBetaScreen({this.backend, this.economyBackend, super.key});

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

  void _message(String value) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(value)));
  }

  Future<void> _copyReferralCode() async {
    final code = _referralSummary.referralCode;
    if (code == null || code.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: code));
    _message('Referral code copied.');
  }

  Future<void> _claimReferralCode() async {
    final code = _referralController.text.trim();
    if (code.isEmpty || _referralBusy) return;
    final economy = _economyBackend;
    if (economy == null) {
      setState(
        () => _referralError =
            'Referral service is unavailable in this test shell.',
      );
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
      _message(
        result.accepted
            ? 'Referral qualified: you received ${result.referredRewardCoins} promo Fame Coins.'
            : 'That account already used a referral reward.',
      );
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
    if (text.contains('self referral')) {
      return 'You cannot use your own referral code.';
    }
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
                      'First Verse progress is only available to enrolled Fameverse beta testers and privileged QA accounts.',
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
                _TesterSafetyNote(privileged: status.privilegedAccess),
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
    final ownerPreview = status.privilegedAccess && !unlocked;
    final visible = unlocked || status.privilegedAccess;
    return Container(
      key: const Key('first-verse-progress-card'),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: visible ? const Color(0xFFB96BFF) : const Color(0xFF4A3155),
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
          if (status.privilegedAccess) ...[
            Container(
              key: const Key('first-verse-owner-preview'),
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFF3B1D50),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: const Color(0xFF744793)),
              ),
              child: const Text(
                'OWNER / ADMIN PREVIEW · NO FEATURE LOCKS',
                style: TextStyle(
                  color: Color(0xFFE4C4FF),
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: .8,
                ),
              ),
            ),
            const SizedBox(height: 13),
          ],
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _BadgePreview(
                unlocked: unlocked,
                privilegedPreview: status.privilegedAccess,
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      unlocked
                          ? 'First Verse earned'
                          : ownerPreview
                          ? 'First Verse owner preview'
                          : 'Your badge is waiting',
                      style: const TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      unlocked
                          ? 'You completed the required beta checks. This legacy badge stays with your account.'
                          : ownerPreview
                          ? 'You can inspect the real badge art and every First Verse surface without faking mission completion or awarding the badge.'
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
  const _BadgePreview({
    required this.unlocked,
    required this.privilegedPreview,
  });

  final bool unlocked;
  final bool privilegedPreview;

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

    if (unlocked || privilegedPreview) return badge;
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
          Icon(
            completed ? Icons.check_circle_rounded : Icons.circle_outlined,
            color: completed
                ? const Color(0xFFB86AFF)
                : const Color(0xFF766A7A),
            size: 21,
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mission.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  mission.detail,
                  style: const TextStyle(
                    color: Color(0xFF9D919F),
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
        border: Border.all(color: const Color(0xFF3A2942)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Bring someone into Fameverse',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          const Text(
            'You get 100 promo Fame Coins after a qualified referral. The person you invite gets 50 promo Fame Coins.',
            style: TextStyle(
              color: Color(0xFFB7A9BC),
              fontSize: 12,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF211528),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    code ?? 'Referral code loading…',
                    key: const Key('first-verse-referral-code'),
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.1,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: code == null ? null : onCopy,
                  tooltip: 'Copy referral code',
                  icon: const Icon(Icons.copy_rounded, size: 18),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${summary.qualifiedReferrals} qualified · ${summary.promoCoinsEarned} promo coins earned',
            style: const TextStyle(color: Color(0xFF948899), fontSize: 11),
          ),
          const SizedBox(height: 16),
          TextField(
            key: const Key('first-verse-referral-input'),
            controller: controller,
            enabled: !busy,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              labelText: 'Have a referral code?',
              hintText: 'Enter code',
              errorText: error,
            ),
          ),
          const SizedBox(height: 9),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: busy ? null : onClaim,
              child: Text(busy ? 'Applying…' : 'Apply referral code'),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Promo Fame Coins are gifting-only. They cannot be transferred, transformed, replaced, exchanged, or cashed out. Gifts funded with promo/referral coins do not create creator cash earnings. Referral activity does not count toward badge progress.',
            style: TextStyle(
              color: Color(0xFF8F8394),
              fontSize: 10.5,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _TesterSafetyNote extends StatelessWidget {
  const _TesterSafetyNote({required this.privileged});

  final bool privileged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0E0B11),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2B222F)),
      ),
      child: Text(
        privileged
            ? 'Owner/admin access is never blocked by First Verse. Mission progress remains real so you can test the same achievement flow without granting yourself a fake earned badge.'
            : 'First Verse unlocks only from the required beta missions. Payouts, owner tools, and internal controls are never beta missions.',
        style: const TextStyle(
          color: Color(0xFF928795),
          fontSize: 10.5,
          height: 1.4,
        ),
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 56),
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
        color: const Color(0xFF141017),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF34283B)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFFC783FF)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 5),
                Text(
                  body,
                  style: const TextStyle(
                    color: Color(0xFFA99DAE),
                    height: 1.4,
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

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.value);

  final String value;

  @override
  Widget build(BuildContext context) {
    return Text(
      value,
      style: const TextStyle(
        color: Color(0xFF9A8BA1),
        fontSize: 10,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.3,
      ),
    );
  }
}

part of 'native_profile_build23.dart';

class _Build23SettingsScreen extends StatelessWidget {
  const _Build23SettingsScreen({
    required this.profile,
    required this.isOwner,
    required this.betaStatus,
    required this.avatarBusy,
    required this.onChangePhoto,
    required this.onEdit,
    required this.onCreatorStudio,
    required this.onFirstVerse,
    required this.onPolicies,
    required this.onSignOut,
  });

  final FvProfile profile;
  final bool isOwner;
  final FvBetaProgramStatus betaStatus;
  final bool avatarBusy;
  final VoidCallback onChangePhoto;
  final VoidCallback onEdit;
  final VoidCallback onCreatorStudio;
  final VoidCallback? onFirstVerse;
  final VoidCallback onPolicies;
  final Future<void> Function() onSignOut;

  Future<void> _signOut(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text('You can sign back in to Fameverse at any time.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await onSignOut();
    if (context.mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('build23-settings-screen'),
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Settings'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 34),
          children: [
            if (isOwner) ...[
              Container(
                key: const Key('settings-owner-premium-card'),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFB47B32)),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF3F2715), Color(0xFF1B111D)],
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.workspace_premium_rounded,
                      color: Color(0xFFFFD17F),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Owner Premium',
                            style: TextStyle(fontWeight: FontWeight.w900),
                          ),
                          SizedBox(height: 3),
                          Text(
                            'Owner previews are shown clearly — no blurred or fake locked cards.',
                            style: TextStyle(
                              color: Color(0xFFC5B7C8),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
            ],
            _Section(
              title: 'PROFILE',
              children: [
                _RowItem(
                  label: 'Edit profile',
                  value: '${profile.displayName} · ${profile.handle}',
                  icon: Icons.person_outline_rounded,
                  onTap: onEdit,
                ),
                _RowItem(
                  label: 'Profile photo',
                  value: avatarBusy ? 'Updating…' : 'Change your public image',
                  icon: Icons.photo_camera_outlined,
                  onTap: avatarBusy ? null : onChangePhoto,
                ),
              ],
            ),
            const SizedBox(height: 22),
            _Section(
              title: 'CREATOR',
              children: [
                _RowItem(
                  label: isOwner ? 'Owner Studio' : 'Creator Studio',
                  value: isOwner
                      ? 'Moderation, payouts, platform finance and your creator account'
                      : 'Earnings, payouts and creator tools',
                  icon: Icons.workspace_premium_outlined,
                  onTap: onCreatorStudio,
                ),
              ],
            ),
            const SizedBox(height: 22),
            const Text(
              'FIRST VERSE',
              style: TextStyle(
                color: Color(0xFF8D8191),
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.15,
              ),
            ),
            const SizedBox(height: 8),
            _FirstVerseSettingsCard(status: betaStatus, onTap: onFirstVerse),
            const SizedBox(height: 22),
            _Section(
              title: 'SAFETY & ACCOUNT',
              children: [
                _RowItem(
                  label: 'Safety & legal',
                  value: 'Terms, privacy, community and creator rules',
                  icon: Icons.shield_outlined,
                  onTap: onPolicies,
                ),
                _RowItem(
                  label: 'Sign out',
                  value: 'Sign out of this Fameverse account',
                  icon: Icons.logout_rounded,
                  danger: true,
                  onTap: () => _signOut(context),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FirstVerseSettingsCard extends StatelessWidget {
  const _FirstVerseSettingsCard({required this.status, required this.onTap});

  final FvBetaProgramStatus status;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final complete = status.completedRequired;
    final total = status.requiredTotal;
    final label = !status.enrolled
        ? 'Not enrolled'
        : status.badgeUnlocked
        ? 'First Verse unlocked'
        : '$complete of $total required missions complete';

    return InkWell(
      key: const Key('settings-first-verse-entry'),
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Ink(
        padding: const EdgeInsets.all(17),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFF684285)),
          gradient: const LinearGradient(
            colors: [Color(0xFF2D173A), Color(0xFF130E17)],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  status.badgeUnlocked
                      ? Icons.auto_awesome_rounded
                      : Icons.stars_outlined,
                  color: const Color(0xFFD59CFF),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'First Verse',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                  ),
                ),
                if (onTap != null) const Icon(Icons.chevron_right_rounded),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(color: Color(0xFFB8ABBd), fontSize: 12),
            ),
            if (status.enrolled) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  key: const Key('settings-first-verse-progress'),
                  minHeight: 8,
                  value: status.progress,
                  backgroundColor: const Color(0xFF33273A),
                  color: const Color(0xFFB661F3),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${(status.progress * 100).round()}% complete',
                style: const TextStyle(
                  color: Color(0xFF9E91A5),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Text(
            title,
            style: const TextStyle(
              color: Color(0xFF8D8191),
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.15,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF151417),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFF2B242E)),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _RowItem extends StatelessWidget {
  const _RowItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
    this.danger = false,
  });

  final String label;
  final String value;
  final IconData icon;
  final VoidCallback? onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 13, 11, 13),
        child: Row(
          children: [
            Container(
              width: 39,
              height: 39,
              decoration: BoxDecoration(
                color: danger
                    ? const Color(0xFF34171E)
                    : const Color(0xFF291833),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(
                icon,
                size: 19,
                color: danger
                    ? const Color(0xFFFF8C9B)
                    : const Color(0xFFC992F1),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: danger ? const Color(0xFFFFB3BC) : null,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    value,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF9E939F),
                      fontSize: 11,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null) const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    );
  }
}

class _Build23VerificationBadge extends StatefulWidget {
  const _Build23VerificationBadge({
    required this.userId,
    required this.isOwner,
  });

  final String userId;
  final bool isOwner;

  @override
  State<_Build23VerificationBadge> createState() =>
      _Build23VerificationBadgeState();
}

class _Build23VerificationBadgeState extends State<_Build23VerificationBadge> {
  bool _verified = false;

  @override
  void initState() {
    super.initState();
    if (!widget.isOwner) _loadVerification();
  }

  @override
  void didUpdateWidget(covariant _Build23VerificationBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId ||
        oldWidget.isOwner != widget.isOwner) {
      if (widget.isOwner) {
        _verified = false;
      } else {
        _loadVerification();
      }
    }
  }

  Future<void> _loadVerification() async {
    try {
      final row = await Supabase.instance.client
          .from('creator_verification_requests')
          .select('status')
          .eq('user_id', widget.userId)
          .maybeSingle();
      final verified =
          (row?['status'] as String?)?.trim().toLowerCase() == 'verified';
      if (mounted) setState(() => _verified = verified);
    } catch (_) {
      if (mounted) setState(() => _verified = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isOwner) {
      return const Padding(
        padding: EdgeInsets.only(left: 6),
        child: Icon(
          Icons.workspace_premium_rounded,
          color: Color(0xFFFFD27D),
          size: 21,
        ),
      );
    }
    if (!_verified) return const SizedBox.shrink();
    return const Padding(
      padding: EdgeInsets.only(left: 6),
      child: Icon(Icons.verified_rounded, color: Color(0xFFA95AFF), size: 21),
    );
  }
}

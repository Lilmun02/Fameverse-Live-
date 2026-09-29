import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/fameverse_backend.dart';
import '../../data/fameverse_beta_backend.dart';

class NativeProfileBuild23Screen extends StatelessWidget {
  const NativeProfileBuild23Screen({
    required this.profile,
    required this.identity,
    required this.network,
    required this.isOwner,
    required this.betaStatus,
    required this.avatarBusy,
    required this.onChangePhoto,
    required this.onEdit,
    required this.onCreatorStudio,
    required this.onFirstVerse,
    required this.onPolicies,
    required this.onSignOut,
    super.key,
  });

  final FvProfile profile;
  final FvIdentity identity;
  final FvFollowNetwork network;
  final bool isOwner;
  final FvBetaProgramStatus betaStatus;
  final bool avatarBusy;
  final VoidCallback onChangePhoto;
  final VoidCallback onEdit;
  final VoidCallback onCreatorStudio;
  final VoidCallback? onFirstVerse;
  final VoidCallback onPolicies;
  final Future<void> Function() onSignOut;

  int get _friends =>
      network.followingIds.intersection(network.followerIds).length;

  String get _publicBio {
    final value = profile.bio.trim();
    final normalized = value.toLowerCase();
    if (normalized == 'admin - owner' || normalized == 'admin-owner') return '';
    return value;
  }

  void _openSettings(BuildContext context) {
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (context) => _Build23SettingsScreen(
          profile: profile,
          isOwner: isOwner,
          betaStatus: betaStatus,
          avatarBusy: avatarBusy,
          onChangePhoto: onChangePhoto,
          onEdit: onEdit,
          onCreatorStudio: onCreatorStudio,
          onFirstVerse: onFirstVerse,
          onPolicies: onPolicies,
          onSignOut: onSignOut,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        key: const Key('build23-profile-screen'),
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 116),
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'FAMEVERSE',
                      style: TextStyle(
                        color: Color(0xFFC982FF),
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Profile',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                key: const Key('profile-settings-button'),
                onPressed: () => _openSettings(context),
                icon: const Icon(Icons.settings_rounded),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _PremiumHero(
            profile: profile,
            isOwner: isOwner,
            avatarBusy: avatarBusy,
            onChangePhoto: onChangePhoto,
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  profile.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 29,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              _Build23VerificationBadge(userId: profile.id, isOwner: isOwner),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            profile.handle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFFA69AA9),
              fontWeight: FontWeight.w700,
            ),
          ),
          if (isOwner) ...[
            const SizedBox(height: 8),
            const Text(
              'FAMEVERSE OWNER • PREMIUM',
              key: Key('owner-premium-profile-label'),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFFFFD695),
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.3,
              ),
            ),
          ],
          const SizedBox(height: 13),
          Text(
            _publicBio.isEmpty
                ? 'Add a bio and tell Fameverse who you are.'
                : _publicBio,
            textAlign: TextAlign.center,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: _publicBio.isEmpty
                  ? const Color(0xFF7A707E)
                  : const Color(0xFFE8DFEA),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 22),
          _Stats(
            followers: network.followers.length,
            following: network.following.length,
            friends: _friends,
          ),
          const SizedBox(height: 14),
          _WalletCard(userId: identity.id),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  key: const Key('edit-profile-button'),
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_rounded, size: 18),
                  label: const Text('Edit profile'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                  ),
                ),
              ),
              const SizedBox(width: 9),
              IconButton.filledTonal(
                onPressed: onCreatorStudio,
                tooltip: 'Creator Studio',
                icon: const Icon(Icons.workspace_premium_rounded),
              ),
            ],
          ),
          const SizedBox(height: 24),
          InkWell(
            key: const Key('open-creator-studio'),
            onTap: onCreatorStudio,
            borderRadius: BorderRadius.circular(20),
            child: Ink(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF54366B)),
                gradient: const LinearGradient(
                  colors: [Color(0xFF2B1738), Color(0xFF130E17)],
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.workspace_premium_rounded,
                    color: Color(0xFFD49CFF),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isOwner ? 'Owner Creator Studio' : 'Creator Studio',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          isOwner
                              ? 'Premium tools, earnings and payout controls'
                              : 'Earnings, payouts and creator tools',
                          style: const TextStyle(
                            color: Color(0xFFAA9DAE),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PremiumHero extends StatelessWidget {
  const _PremiumHero({
    required this.profile,
    required this.isOwner,
    required this.avatarBusy,
    required this.onChangePhoto,
  });

  final FvProfile profile;
  final bool isOwner;
  final bool avatarBusy;
  final VoidCallback onChangePhoto;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 182,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            bottom: 54,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(26),
                border: Border.all(
                  color: isOwner
                      ? const Color(0xFFB98543)
                      : const Color(0xFF6E348A),
                  width: 1.2,
                ),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isOwner
                      ? const [
                          Color(0xFF4B2B16),
                          Color(0xFF251426),
                          Color(0xFF0B080E),
                        ]
                      : const [
                          Color(0xFF321342),
                          Color(0xFF1A0D22),
                          Color(0xFF0B080E),
                        ],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(17),
                child: Align(
                  alignment: Alignment.topLeft,
                  child: Text(
                    isOwner ? 'OWNER PREMIUM PROFILE' : 'YOUR FAMEVERSE',
                    style: TextStyle(
                      color: isOwner
                          ? const Color(0xFFFFD99A)
                          : const Color(0xFFBFA5CB),
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.6,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 118,
                height: 118,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black,
                  border: Border.all(
                    color: isOwner
                        ? const Color(0xFFFFC96C)
                        : const Color(0xFFB45FFF),
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isOwner
                          ? const Color(0x66C9862F)
                          : const Color(0x665B1688),
                      blurRadius: 24,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: ClipOval(child: _Avatar(profile: profile)),
              ),
              Positioned(
                right: -3,
                bottom: 5,
                child: Material(
                  color: isOwner
                      ? const Color(0xFFB77B2D)
                      : const Color(0xFF913CE6),
                  shape: const CircleBorder(),
                  child: InkWell(
                    onTap: avatarBusy ? null : onChangePhoto,
                    customBorder: const CircleBorder(),
                    child: SizedBox(
                      width: 40,
                      height: 40,
                      child: Center(
                        child: avatarBusy
                            ? const SizedBox(
                                width: 17,
                                height: 17,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(
                                Icons.camera_alt_rounded,
                                size: 18,
                                color: Colors.white,
                              ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.profile});
  final FvProfile profile;

  @override
  Widget build(BuildContext context) {
    final url = profile.avatarUrl?.trim();
    if (url != null && url.isNotEmpty) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _Fallback(initial: profile.initial),
      );
    }
    return _Fallback(initial: profile.initial);
  }
}

class _Fallback extends StatelessWidget {
  const _Fallback({required this.initial});
  final String initial;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFF352044),
      child: Center(
        child: Text(
          initial,
          style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900),
        ),
      ),
    );
  }
}

class _Stats extends StatelessWidget {
  const _Stats({
    required this.followers,
    required this.following,
    required this.friends,
  });

  final int followers;
  final int following;
  final int friends;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 15),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: Color(0xFF2B202F)),
          bottom: BorderSide(color: Color(0xFF2B202F)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _Stat(value: followers, label: 'Followers'),
          ),
          const _Divider(),
          Expanded(
            child: _Stat(value: following, label: 'Following'),
          ),
          const _Divider(),
          Expanded(
            child: _Stat(value: friends, label: 'Friends'),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();
  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 1,
      height: 34,
      child: ColoredBox(color: Color(0xFF2C2230)),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});
  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          '$value',
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF9D929F),
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _WalletCard extends StatefulWidget {
  const _WalletCard({required this.userId});
  final String userId;

  @override
  State<_WalletCard> createState() => _WalletCardState();
}

class _WalletCardState extends State<_WalletCard> {
  int? _balance;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) setState(() => _loading = true);
    try {
      final row = await Supabase.instance.client
          .from('beta_coin_wallets')
          .select('balance')
          .eq('user_id', widget.userId)
          .maybeSingle();
      if (!mounted) return;
      setState(() {
        _balance = (row?['balance'] as num?)?.toInt() ?? 0;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF5C3470)),
        gradient: const LinearGradient(
          colors: [Color(0xFF271334), Color(0xFF151019)],
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.toll_rounded, color: Color(0xFFD7A5FF)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Fame Coins',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                Text(
                  _loading && _balance == null
                      ? 'Loading…'
                      : '${_balance ?? 0}',
                  style: const TextStyle(
                    color: Color(0xFFE2BCFF),
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const Text(
                  'Gifting balance. Creator cash earnings remain separate.',
                  style: TextStyle(color: Color(0xFF9F92A4), fontSize: 10),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _loading ? null : _load,
            icon: _loading
                ? const SizedBox(
                    width: 17,
                    height: 17,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
    );
  }
}

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
                  label: isOwner ? 'Owner Control Center' : 'Creator Studio',
                  value: isOwner
                      ? 'Premium tools, earnings and promo QA'
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

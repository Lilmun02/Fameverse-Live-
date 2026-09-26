import 'package:flutter/material.dart';

import '../../data/fameverse_backend.dart';

/// Public-facing Fameverse profile.
///
/// Product law: this is a social identity surface. Owner QA, recharge controls,
/// payout moderation, account email, backend/build diagnostics, and other
/// internal tools must never render here.
class NativeProfileScreen extends StatelessWidget {
  const NativeProfileScreen({
    required this.profile,
    required this.identity,
    required this.network,
    required this.avatarBusy,
    required this.onChangePhoto,
    required this.onSettings,
    required this.onEdit,
    required this.onCreatorStudio,
    required this.onSignOut,
    super.key,
  });

  final FvProfile profile;
  final FvIdentity identity;
  final FvFollowNetwork network;
  final bool avatarBusy;
  final VoidCallback onChangePhoto;
  final VoidCallback onSettings;
  final VoidCallback onEdit;
  final VoidCallback onCreatorStudio;
  final Future<void> Function() onSignOut;

  int get _friendCount =>
      network.followingIds.intersection(network.followerIds).length;

  String get _publicBio {
    final value = profile.bio.trim();
    if (value.toLowerCase() == 'admin - owner' ||
        value.toLowerCase() == 'admin-owner') {
      return '';
    }
    return value;
  }

  void _openSettings(BuildContext context) {
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (context) => _FameverseSettingsScreen(
          profile: profile,
          avatarBusy: avatarBusy,
          onChangePhoto: onChangePhoto,
          onEditProfile: onEdit,
          onCreatorStudio: onCreatorStudio,
          onLegalAndSafety: onSettings,
          onSignOut: onSignOut,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async {},
        child: CustomScrollView(
          key: const Key('native-profile-screen'),
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 116),
              sliver: SliverList.list(
                children: [
                  _ProfileTopBar(onSettings: () => _openSettings(context)),
                  const SizedBox(height: 18),
                  _ProfileHero(
                    profile: profile,
                    avatarBusy: avatarBusy,
                    onChangePhoto: onChangePhoto,
                  ),
                  const SizedBox(height: 16),
                  _ProfileIdentity(profile: profile, publicBio: _publicBio),
                  const SizedBox(height: 22),
                  _ConnectionStats(
                    followers: network.followers.length,
                    following: network.following.length,
                    friends: _friendCount,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          key: const Key('edit-profile-button'),
                          onPressed: onEdit,
                          icon: const Icon(Icons.edit_rounded, size: 18),
                          label: const Text('Edit profile'),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(52),
                            backgroundColor: const Color(0xFF8F4FE8),
                            foregroundColor: Colors.white,
                            textStyle: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 15,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      _SquareProfileAction(
                        tooltip: 'Creator Studio',
                        icon: Icons.workspace_premium_rounded,
                        onTap: onCreatorStudio,
                      ),
                      const SizedBox(width: 10),
                      _SquareProfileAction(
                        tooltip: 'Settings',
                        icon: Icons.settings_rounded,
                        onTap: () => _openSettings(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  const _SectionLabel('CREATOR SPACE'),
                  const SizedBox(height: 10),
                  _CreatorStudioRow(onTap: onCreatorStudio),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileTopBar extends StatelessWidget {
  const _ProfileTopBar({required this.onSettings});

  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Row(
            children: [
              _FameverseMark(),
              SizedBox(width: 9),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'FAMEVERSE',
                    style: TextStyle(
                      color: Color(0xFFC985FF),
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2.1,
                    ),
                  ),
                  SizedBox(height: 1),
                  Text(
                    'Profile',
                    key: Key('profile-title'),
                    style: TextStyle(
                      fontSize: 24,
                      height: 1,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -.35,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        IconButton(
          key: const Key('profile-settings-button'),
          onPressed: onSettings,
          tooltip: 'Settings',
          style: IconButton.styleFrom(
            minimumSize: const Size(46, 46),
            backgroundColor: const Color(0xFF171019),
            foregroundColor: const Color(0xFFEFE6F4),
            side: const BorderSide(color: Color(0xFF432A51)),
          ),
          icon: const Icon(Icons.settings_rounded, size: 21),
        ),
      ],
    );
  }
}

class _FameverseMark extends StatelessWidget {
  const _FameverseMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFB663FF), Color(0xFF522080)],
        ),
        boxShadow: [BoxShadow(color: Color(0x665E1B9B), blurRadius: 14)],
      ),
      child: const Center(
        child: Text(
          'F',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            fontStyle: FontStyle.italic,
          ),
        ),
      ),
    );
  }
}

class _ProfileHero extends StatelessWidget {
  const _ProfileHero({
    required this.profile,
    required this.avatarBusy,
    required this.onChangePhoto,
  });

  final FvProfile profile;
  final bool avatarBusy;
  final VoidCallback onChangePhoto;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 204,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            bottom: 46,
            child: Container(
              key: const Key('profile-cover'),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: const Color(0xFF6B318B), width: 1.2),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF341348),
                    Color(0xFF1A0C24),
                    Color(0xFF0B080E),
                  ],
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x442B0B40),
                    blurRadius: 30,
                    offset: Offset(0, 14),
                  ),
                ],
              ),
              child: const Stack(
                children: [
                  Positioned(
                    left: 20,
                    top: 18,
                    child: Text(
                      'YOUR FAMEVERSE',
                      style: TextStyle(
                        color: Color(0xFFD3ACEA),
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.7,
                      ),
                    ),
                  ),
                  Positioned(
                    right: 18,
                    top: 20,
                    child: Icon(
                      Icons.auto_awesome_rounded,
                      color: Color(0x335E2380),
                      size: 76,
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 6,
                    child: Icon(
                      Icons.workspace_premium_rounded,
                      color: Color(0x226E2DA0),
                      size: 104,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 122,
                  height: 122,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF08060A),
                    border: Border.all(
                      color: const Color(0xFFB35CFF),
                      width: 3,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x884F137A),
                        blurRadius: 22,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: ClipOval(child: _ProfileAvatar(profile: profile)),
                ),
                Positioned(
                  right: -2,
                  bottom: 5,
                  child: Material(
                    color: const Color(0xFF913CE6),
                    shape: const CircleBorder(),
                    child: InkWell(
                      key: const Key('change-profile-photo-button'),
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
          ),
        ],
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({required this.profile});

  final FvProfile profile;

  @override
  Widget build(BuildContext context) {
    final url = profile.avatarUrl?.trim();
    if (url != null && url.isNotEmpty) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _AvatarFallback(profile: profile),
      );
    }
    return _AvatarFallback(profile: profile);
  }
}

class _AvatarFallback extends StatelessWidget {
  const _AvatarFallback({required this.profile});

  final FvProfile profile;

  @override
  Widget build(BuildContext context) {
    final text = profile.displayName.trim();
    final initial = text.isEmpty ? 'F' : text.characters.first.toUpperCase();
    return ColoredBox(
      color: const Color(0xFF352044),
      child: Center(
        child: Text(
          initial,
          style: const TextStyle(
            fontSize: 39,
            fontWeight: FontWeight.w900,
            color: Color(0xFFF2E9F7),
          ),
        ),
      ),
    );
  }
}

class _ProfileIdentity extends StatelessWidget {
  const _ProfileIdentity({required this.profile, required this.publicBio});

  final FvProfile profile;
  final String publicBio;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                profile.displayName,
                key: const Key('profile-display-name'),
                maxLines: 1,
                overflow: TextOverflow.fade,
                softWrap: false,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 29,
                  height: 1.05,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -.65,
                ),
              ),
            ),
            const SizedBox(width: 6),
            const Icon(
              Icons.verified_rounded,
              color: Color(0xFFA85BFF),
              size: 20,
            ),
          ],
        ),
        const SizedBox(height: 5),
        Text(
          profile.handle,
          key: const Key('profile-handle'),
          style: const TextStyle(
            color: Color(0xFFA99FAC),
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 14),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 330),
          child: Text(
            publicBio.isEmpty
                ? 'Add a bio and tell Fameverse who you are.'
                : publicBio,
            key: const Key('profile-bio'),
            textAlign: TextAlign.center,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: publicBio.isEmpty
                  ? const Color(0xFF817783)
                  : const Color(0xFFE8E0EB),
              fontSize: 14,
              height: 1.42,
              fontWeight: publicBio.isEmpty ? FontWeight.w500 : FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _ConnectionStats extends StatelessWidget {
  const _ConnectionStats({
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
      key: const Key('profile-social-stats'),
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: Color(0xFF2B202F)),
          bottom: BorderSide(color: Color(0xFF2B202F)),
        ),
      ),
      child: Row(
        children: [
          Expanded(child: _Stat(value: followers, label: 'Followers')),
          Expanded(child: _Stat(value: following, label: 'Following')),
          Expanded(child: _Stat(value: friends, label: 'Friends')),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});

  final int value;
  final String label;

  String get _formatted {
    if (value >= 1000000) {
      final text = (value / 1000000).toStringAsFixed(value >= 10000000 ? 0 : 1);
      return '${text.replaceAll('.0', '')}M';
    }
    if (value >= 1000) {
      final text = (value / 1000).toStringAsFixed(value >= 10000 ? 0 : 1);
      return '${text.replaceAll('.0', '')}K';
    }
    return '$value';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          _formatted,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFFA49AA9),
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _SquareProfileAction extends StatelessWidget {
  const _SquareProfileAction({
    required this.tooltip,
    required this.icon,
    required this.onTap,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      tooltip: tooltip,
      style: IconButton.styleFrom(
        minimumSize: const Size(52, 52),
        backgroundColor: const Color(0xFF171019),
        foregroundColor: const Color(0xFFECE4F1),
        side: const BorderSide(color: Color(0xFF3A2942)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      icon: Icon(icon, size: 22),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFF8E7D97),
        fontSize: 10,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.5,
      ),
    );
  }
}

class _CreatorStudioRow extends StatelessWidget {
  const _CreatorStudioRow({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: const Key('open-creator-studio'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          padding: const EdgeInsets.fromLTRB(16, 16, 14, 16),
          decoration: BoxDecoration(
            color: const Color(0xFF141017),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF3C2948)),
          ),
          child: const Row(
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF4A2364), Color(0xFF25122F)],
                  ),
                  borderRadius: BorderRadius.all(Radius.circular(15)),
                ),
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Icon(
                    Icons.workspace_premium_outlined,
                    color: Color(0xFFD39DFF),
                    size: 23,
                  ),
                ),
              ),
              SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Creator Studio',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Earnings, payouts and creator tools',
                      style: TextStyle(color: Color(0xFFA89EAD), fontSize: 12),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: Color(0xFFC6BACB)),
            ],
          ),
        ),
      ),
    );
  }
}

class _FameverseSettingsScreen extends StatelessWidget {
  const _FameverseSettingsScreen({
    required this.profile,
    required this.avatarBusy,
    required this.onChangePhoto,
    required this.onEditProfile,
    required this.onCreatorStudio,
    required this.onLegalAndSafety,
    required this.onSignOut,
  });

  final FvProfile profile;
  final bool avatarBusy;
  final VoidCallback onChangePhoto;
  final VoidCallback onEditProfile;
  final VoidCallback onCreatorStudio;
  final VoidCallback onLegalAndSafety;
  final Future<void> Function() onSignOut;

  String get _publicBio {
    final value = profile.bio.trim();
    if (value.toLowerCase() == 'admin - owner' ||
        value.toLowerCase() == 'admin-owner') {
      return '';
    }
    return value;
  }

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
      key: const Key('fameverse-profile-settings-screen'),
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        centerTitle: true,
        title: const Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                'FAMEVERSE',
                style: TextStyle(
                  color: Color(0xFFBA6BFF),
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.4,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 34),
          children: [
            const SizedBox(height: 6),
            Center(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 118,
                    height: 118,
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFA653FF),
                        width: 2.5,
                      ),
                      boxShadow: const [
                        BoxShadow(color: Color(0x665A1A85), blurRadius: 22),
                      ],
                    ),
                    child: ClipOval(child: _ProfileAvatar(profile: profile)),
                  ),
                  Positioned(
                    right: -4,
                    bottom: 2,
                    child: IconButton.filled(
                      onPressed: avatarBusy ? null : onChangePhoto,
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(0xFF8F43E0),
                        foregroundColor: Colors.white,
                      ),
                      icon: avatarBusy
                          ? const SizedBox(
                              width: 17,
                              height: 17,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.camera_alt_rounded, size: 19),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: TextButton(
                onPressed: avatarBusy ? null : onChangePhoto,
                child: const Text(
                  'Change photo',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const _SettingsSectionTitle('PROFILE INFO'),
            const SizedBox(height: 8),
            _SettingsGroup(
              children: [
                _SettingsRow(
                  label: 'Username',
                  value: profile.handle,
                  onTap: onEditProfile,
                ),
                _SettingsRow(
                  label: 'Name',
                  value: profile.displayName,
                  onTap: onEditProfile,
                ),
                _SettingsRow(
                  label: 'Bio',
                  value: _publicBio.isEmpty ? 'Add a bio' : _publicBio,
                  maxValueLines: 3,
                  onTap: onEditProfile,
                ),
              ],
            ),
            const SizedBox(height: 22),
            const _SettingsSectionTitle('CREATOR'),
            const SizedBox(height: 8),
            _SettingsGroup(
              children: [
                _SettingsRow(
                  label: 'Creator Studio',
                  value: 'Earnings, payouts and creator tools',
                  icon: Icons.workspace_premium_outlined,
                  onTap: onCreatorStudio,
                ),
              ],
            ),
            const SizedBox(height: 22),
            const _SettingsSectionTitle('ACCOUNT & SAFETY'),
            const SizedBox(height: 8),
            _SettingsGroup(
              children: [
                _SettingsRow(
                  label: 'Legal & safety',
                  value: 'Terms, privacy and community rules',
                  icon: Icons.shield_outlined,
                  onTap: onLegalAndSafety,
                ),
                _SettingsRow(
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

class _SettingsSectionTitle extends StatelessWidget {
  const _SettingsSectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF8C8191),
          fontSize: 11,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.1,
        ),
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF151417),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF282229)),
      ),
      child: Column(children: children),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.label,
    required this.value,
    required this.onTap,
    this.icon,
    this.maxValueLines = 2,
    this.danger = false,
  });

  final String label;
  final String value;
  final VoidCallback onTap;
  final IconData? icon;
  final int maxValueLines;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 15, 12, 15),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: danger
                      ? const Color(0xFF34171E)
                      : const Color(0xFF2A1933),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: danger
                      ? const Color(0xFFFF718A)
                      : const Color(0xFFCA8AFF),
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: danger
                          ? const Color(0xFFFF8297)
                          : const Color(0xFFF2EDF4),
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    value,
                    maxLines: maxValueLines,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF8F878F),
                      fontSize: 13,
                      height: 1.25,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFF8D858E)),
          ],
        ),
      ),
    );
  }
}

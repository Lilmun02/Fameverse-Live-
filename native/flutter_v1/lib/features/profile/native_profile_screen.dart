import 'package:flutter/material.dart';

import '../../data/fameverse_backend.dart';

/// Public Fameverse identity surface.
///
/// Internal roles, QA controls, payment controls, account email, backend/build
/// diagnostics, and moderation tooling never belong on this screen.
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
    final normalized = value.toLowerCase();
    if (normalized == 'admin - owner' || normalized == 'admin-owner') return '';
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
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 116),
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
                  const SizedBox(height: 18),
                  _ProfileActions(
                    onEdit: onEdit,
                    onCreatorStudio: onCreatorStudio,
                    onSettings: () => _openSettings(context),
                  ),
                  const SizedBox(height: 30),
                  const _SectionLabel('CREATOR SPACE'),
                  const SizedBox(height: 9),
                  _CreatorStudioRow(onTap: onCreatorStudio),
                  const SizedBox(height: 24),
                  const _ProfileFooterNote(),
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
                key: Key('profile-title'),
                style: TextStyle(
                  fontSize: 28,
                  height: 1,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -.5,
                ),
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
            foregroundColor: const Color(0xFFF2EAF5),
            side: const BorderSide(color: Color(0xFF422B4D)),
          ),
          icon: const Icon(Icons.settings_rounded, size: 21),
        ),
      ],
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
      height: 176,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            bottom: 52,
            child: Container(
              key: const Key('profile-cover'),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: const Color(0xFF6E348A), width: 1.2),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF321342),
                    Color(0xFF1A0D22),
                    Color(0xFF0B080E),
                  ],
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x3D45105F),
                    blurRadius: 28,
                    offset: Offset(0, 12),
                  ),
                ],
              ),
              child: const Stack(
                children: [
                  Positioned(
                    left: 18,
                    top: 16,
                    child: Text(
                      'YOUR FAMEVERSE',
                      style: TextStyle(
                        color: Color(0xFFBFA5CB),
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.6,
                      ),
                    ),
                  ),
                  Positioned(
                    right: 18,
                    top: 14,
                    child: Icon(
                      Icons.auto_awesome_rounded,
                      color: Color(0x4D8B3EAF),
                      size: 52,
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
                  width: 116,
                  height: 116,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black,
                    border: Border.all(
                      color: const Color(0xFFB45FFF),
                      width: 3,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x885B1688),
                        blurRadius: 22,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: ClipOval(child: _ProfileAvatar(profile: profile)),
                ),
                Positioned(
                  right: -3,
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
                  fontSize: 30,
                  height: 1.05,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -.7,
                ),
              ),
            ),
            const SizedBox(width: 6),
            const Icon(
              Icons.verified_rounded,
              color: Color(0xFFA95AFF),
              size: 20,
            ),
          ],
        ),
        const SizedBox(height: 5),
        Text(
          profile.handle,
          key: const Key('profile-handle'),
          style: const TextStyle(
            color: Color(0xFF9F94A3),
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 13),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 340),
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
                  ? const Color(0xFF746C77)
                  : const Color(0xFFE7DEE9),
              fontSize: 14,
              height: 1.4,
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
      padding: const EdgeInsets.symmetric(vertical: 15),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: Color(0xFF2B202F)),
          bottom: BorderSide(color: Color(0xFF2B202F)),
        ),
      ),
      child: Row(
        children: [
          Expanded(child: _Stat(value: followers, label: 'Followers')),
          const _StatDivider(),
          Expanded(child: _Stat(value: following, label: 'Following')),
          const _StatDivider(),
          Expanded(child: _Stat(value: friends, label: 'Friends')),
        ],
      ),
    );
  }
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();

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
            color: Color(0xFF9D929F),
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _ProfileActions extends StatelessWidget {
  const _ProfileActions({
    required this.onEdit,
    required this.onCreatorStudio,
    required this.onSettings,
  });

  final VoidCallback onEdit;
  final VoidCallback onCreatorStudio;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            key: const Key('edit-profile-button'),
            onPressed: onEdit,
            icon: const Icon(Icons.edit_rounded, size: 18),
            label: const Text('Edit profile'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
              backgroundColor: const Color(0xFF8D47DF),
              foregroundColor: Colors.white,
              textStyle: const TextStyle(fontWeight: FontWeight.w900),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
        const SizedBox(width: 9),
        _SquareAction(
          tooltip: 'Creator Studio',
          icon: Icons.workspace_premium_rounded,
          onTap: onCreatorStudio,
        ),
        const SizedBox(width: 9),
        _SquareAction(
          tooltip: 'Settings',
          icon: Icons.settings_rounded,
          onTap: onSettings,
        ),
      ],
    );
  }
}

class _SquareAction extends StatelessWidget {
  const _SquareAction({
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
        minimumSize: const Size(50, 50),
        backgroundColor: const Color(0xFF171019),
        foregroundColor: const Color(0xFFEDE5F0),
        side: const BorderSide(color: Color(0xFF3A2942)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      icon: Icon(icon, size: 21),
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
        color: Color(0xFF8D7F94),
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
          padding: const EdgeInsets.fromLTRB(15, 15, 13, 15),
          decoration: BoxDecoration(
            color: const Color(0xFF141017),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF3B2946)),
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
                  borderRadius: BorderRadius.all(Radius.circular(14)),
                ),
                child: Padding(
                  padding: EdgeInsets.all(11),
                  child: Icon(
                    Icons.workspace_premium_outlined,
                    color: Color(0xFFD39DFF),
                    size: 22,
                  ),
                ),
              ),
              SizedBox(width: 12),
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
                      style: TextStyle(color: Color(0xFFA79DAB), fontSize: 12),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: Color(0xFFC5B9C9)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileFooterNote extends StatelessWidget {
  const _ProfileFooterNote();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.public_rounded, size: 13, color: Color(0xFF726A75)),
        SizedBox(width: 6),
        Text(
          'Your public Fameverse identity',
          style: TextStyle(
            color: Color(0xFF726A75),
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
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
    return ColoredBox(
      color: const Color(0xFF352044),
      child: Center(
        child: Text(
          profile.initial,
          style: const TextStyle(
            fontSize: 38,
            fontWeight: FontWeight.w900,
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
    final normalized = value.toLowerCase();
    if (normalized == 'admin - owner' || normalized == 'admin-owner') return '';
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
                'F',
                style: TextStyle(
                  color: Color(0xFFC57EFF),
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 34),
          children: [
            _SettingsIdentityCard(
              profile: profile,
              avatarBusy: avatarBusy,
              onChangePhoto: onChangePhoto,
              onEditProfile: onEditProfile,
            ),
            const SizedBox(height: 24),
            const _SettingsSectionTitle('PROFILE'),
            const SizedBox(height: 8),
            _SettingsGroup(
              children: [
                _SettingsRow(
                  label: 'Username',
                  value: profile.handle,
                  icon: Icons.alternate_email_rounded,
                  onTap: onEditProfile,
                ),
                _SettingsRow(
                  label: 'Name',
                  value: profile.displayName,
                  icon: Icons.badge_outlined,
                  onTap: onEditProfile,
                ),
                _SettingsRow(
                  label: 'Bio',
                  value: _publicBio.isEmpty ? 'Add a bio' : _publicBio,
                  icon: Icons.notes_rounded,
                  maxValueLines: 3,
                  onTap: onEditProfile,
                ),
                _SettingsRow(
                  label: 'Profile photo',
                  value: 'Change your public profile image',
                  icon: Icons.photo_camera_outlined,
                  onTap: onChangePhoto,
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
            const _SettingsSectionTitle('SAFETY & ACCOUNT'),
            const SizedBox(height: 8),
            _SettingsGroup(
              children: [
                _SettingsRow(
                  label: 'Safety & legal',
                  value: 'Terms, privacy, community and creator rules',
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

class _SettingsIdentityCard extends StatelessWidget {
  const _SettingsIdentityCard({
    required this.profile,
    required this.avatarBusy,
    required this.onChangePhoto,
    required this.onEditProfile,
  });

  final FvProfile profile;
  final bool avatarBusy;
  final VoidCallback onChangePhoto;
  final VoidCallback onEditProfile;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF24132F), Color(0xFF120D16)],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF4A3155)),
      ),
      child: Row(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 72,
                height: 72,
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFA957F8), width: 2),
                ),
                child: ClipOval(child: _ProfileAvatar(profile: profile)),
              ),
              Positioned(
                right: -3,
                bottom: -1,
                child: InkWell(
                  onTap: avatarBusy ? null : onChangePhoto,
                  customBorder: const CircleBorder(),
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF8C42DF),
                    ),
                    child: avatarBusy
                        ? const Padding(
                            padding: EdgeInsets.all(7),
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(
                            Icons.camera_alt_rounded,
                            size: 14,
                            color: Colors.white,
                          ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  profile.handle,
                  style: const TextStyle(
                    color: Color(0xFFA89BAB),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 9),
                GestureDetector(
                  onTap: onEditProfile,
                  child: const Text(
                    'Edit public profile',
                    style: TextStyle(
                      color: Color(0xFFC985FF),
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onEditProfile,
            icon: const Icon(Icons.chevron_right_rounded),
          ),
        ],
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
          color: Color(0xFF8D8191),
          fontSize: 11,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.15,
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
        border: Border.all(color: const Color(0xFF2B242E)),
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
    required this.icon,
    this.maxValueLines = 2,
    this.danger = false,
  });

  final String label;
  final String value;
  final VoidCallback onTap;
  final IconData icon;
  final int maxValueLines;
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
                    ? const Color(0xFFFF718A)
                    : const Color(0xFFCA8AFF),
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
                      color: danger
                          ? const Color(0xFFFF8297)
                          : const Color(0xFFF1ECF2),
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    value,
                    maxLines: maxValueLines,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF8E858F),
                      fontSize: 12,
                      height: 1.25,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 7),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFF8E858F)),
          ],
        ),
      ),
    );
  }
}

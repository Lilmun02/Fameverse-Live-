import 'package:flutter/material.dart';

import '../../data/fameverse_backend.dart';

/// Public-facing native profile.
///
/// Product rule: the Profile tab is a social identity surface. Account actions,
/// owner QA, payout moderation, and other internal tooling do not belong here.
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

  int get _friendCount => network.followingIds.intersection(network.followerIds).length;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: CustomScrollView(
        key: const Key('native-profile-screen'),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 112),
            sliver: SliverList.list(
              children: [
                _ProfileTopBar(onSettings: onSettings),
                const SizedBox(height: 18),
                _ProfileHero(
                  profile: profile,
                  avatarBusy: avatarBusy,
                  onChangePhoto: onChangePhoto,
                ),
                const SizedBox(height: 18),
                _ProfileIdentity(profile: profile),
                const SizedBox(height: 20),
                _ConnectionStats(
                  followers: network.followers.length,
                  following: network.following.length,
                  friends: _friendCount,
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    key: const Key('edit-profile-button'),
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('Edit profile'),
                  ),
                ),
                const SizedBox(height: 28),
                const _SectionLabel('CREATOR TOOLS'),
                const SizedBox(height: 10),
                _CreatorStudioCard(onTap: onCreatorStudio),
              ],
            ),
          ),
        ],
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
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'FAMEVERSE',
              style: TextStyle(
                color: Color(0xFFB98BFF),
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.6,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'Profile',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
            ),
          ],
        ),
        const Spacer(),
        IconButton.filledTonal(
          key: const Key('profile-settings-button'),
          onPressed: onSettings,
          icon: const Icon(Icons.settings_outlined),
          tooltip: 'Settings',
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
      height: 182,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            bottom: 38,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: const Color(0xFF4D3265)),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF4B236D),
                    Color(0xFF25132F),
                    Color(0xFF120C18),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 20,
            bottom: 0,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 112,
                  height: 112,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF0C0810),
                    border: Border.all(color: const Color(0xFFB978FF), width: 2),
                  ),
                  child: ClipOval(child: _ProfileAvatar(profile: profile)),
                ),
                Positioned(
                  right: -2,
                  bottom: 3,
                  child: IconButton.filled(
                    key: const Key('change-profile-photo-button'),
                    onPressed: avatarBusy ? null : onChangePhoto,
                    icon: avatarBusy
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.camera_alt_rounded, size: 17),
                    tooltip: 'Change profile photo',
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
      color: const Color(0xFF332043),
      child: Center(
        child: Text(
          initial,
          style: const TextStyle(fontSize: 38, fontWeight: FontWeight.w900),
        ),
      ),
    );
  }
}

class _ProfileIdentity extends StatelessWidget {
  const _ProfileIdentity({required this.profile});

  final FvProfile profile;

  @override
  Widget build(BuildContext context) {
    final bio = profile.bio.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          profile.displayName,
          key: const Key('profile-display-name'),
          style: const TextStyle(
            fontSize: 27,
            height: 1.05,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          profile.handle,
          key: const Key('profile-handle'),
          style: const TextStyle(
            color: Color(0xFFB7AABE),
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 13),
        Text(
          bio.isEmpty ? 'Add a bio so people know what you are about.' : bio,
          key: const Key('profile-bio'),
          style: TextStyle(
            color: bio.isEmpty ? const Color(0xFF8F8497) : const Color(0xFFD8D0DD),
            fontSize: 14,
            height: 1.45,
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
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF17111D),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF30243A)),
      ),
      child: Row(
        children: [
          Expanded(child: _Stat(value: followers, label: 'Followers')),
          const _Divider(),
          Expanded(child: _Stat(value: following, label: 'Following')),
          const _Divider(),
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

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          '$value',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: const TextStyle(color: Color(0xFF9F93A8), fontSize: 11),
        ),
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 34, color: const Color(0xFF35283E));
  }
}

class _CreatorStudioCard extends StatelessWidget {
  const _CreatorStudioCard({required this.onTap});

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
          padding: const EdgeInsets.all(17),
          decoration: BoxDecoration(
            color: const Color(0xFF17111D),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF3D2A48)),
          ),
          child: const Row(
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: Color(0xFF342047),
                  borderRadius: BorderRadius.all(Radius.circular(14)),
                ),
                child: Padding(
                  padding: EdgeInsets.all(11),
                  child: Icon(
                    Icons.auto_graph_rounded,
                    color: Color(0xFFC69BFF),
                    size: 22,
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
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Creator earnings and payout tools',
                      style: TextStyle(color: Color(0xFF9F93A8), fontSize: 12),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: Color(0xFFBBAFC4)),
            ],
          ),
        ),
      ),
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
        color: Color(0xFF8E8297),
        fontSize: 10,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.35,
      ),
    );
  }
}

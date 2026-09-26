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

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: CustomScrollView(
        key: const Key('native-profile-screen'),
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 116),
            sliver: SliverList.list(
              children: [
                _ProfileTopBar(onSettings: onSettings),
                const SizedBox(height: 16),
                _ProfileHero(
                  profile: profile,
                  avatarBusy: avatarBusy,
                  onChangePhoto: onChangePhoto,
                ),
                const SizedBox(height: 12),
                _ProfileIdentity(profile: profile),
                const SizedBox(height: 20),
                _ConnectionStats(
                  followers: network.followers.length,
                  following: network.following.length,
                  friends: _friendCount,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    key: const Key('edit-profile-button'),
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_rounded, size: 18),
                    label: const Text('Edit profile'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                      backgroundColor: const Color(0xFFB889FF),
                      foregroundColor: const Color(0xFF160B20),
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                _CreatorStudioRow(onTap: onCreatorStudio),
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
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'FAMEVERSE',
                style: TextStyle(
                  color: Color(0xFFB978FF),
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.7,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Profile',
                key: Key('profile-title'),
                style: TextStyle(
                  fontSize: 25,
                  height: 1,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -.35,
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
            backgroundColor: const Color(0xFF1B1321),
            foregroundColor: const Color(0xFFD9CFE0),
            side: const BorderSide(color: Color(0xFF382943)),
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
      height: 206,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomLeft,
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
                border: Border.all(color: const Color(0xFF6E3A91), width: 1.25),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF4B1E6D),
                    Color(0xFF26112F),
                    Color(0xFF100B14),
                  ],
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x332C0B42),
                    blurRadius: 28,
                    offset: Offset(0, 12),
                  ),
                ],
              ),
              child: const Stack(
                children: [
                  Positioned(
                    left: 20,
                    top: 18,
                    child: Text(
                      'YOUR SPACE',
                      style: TextStyle(
                        color: Color(0xFFD8B8F4),
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.55,
                      ),
                    ),
                  ),
                  Positioned(
                    right: 18,
                    bottom: 18,
                    child: Icon(
                      Icons.auto_awesome_rounded,
                      color: Color(0x338F51C0),
                      size: 78,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 18,
            bottom: 0,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 118,
                  height: 118,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF0C0810),
                    border: Border.all(
                      color: const Color(0xFFC17DFF),
                      width: 2.5,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x553A0E55),
                        blurRadius: 20,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: ClipOval(child: _ProfileAvatar(profile: profile)),
                ),
                Positioned(
                  right: -3,
                  bottom: 5,
                  child: Material(
                    color: const Color(0xFF9B54F5),
                    shape: const CircleBorder(),
                    child: InkWell(
                      key: const Key('change-profile-photo-button'),
                      onTap: avatarBusy ? null : onChangePhoto,
                      customBorder: const CircleBorder(),
                      child: SizedBox(
                        width: 38,
                        height: 38,
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
  const _ProfileIdentity({required this.profile});

  final FvProfile profile;

  @override
  Widget build(BuildContext context) {
    final bio = profile.bio.trim();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            profile.displayName,
            key: const Key('profile-display-name'),
            maxLines: 2,
            overflow: TextOverflow.fade,
            style: const TextStyle(
              fontSize: 27,
              height: 1.05,
              fontWeight: FontWeight.w900,
              letterSpacing: -.5,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            profile.handle,
            key: const Key('profile-handle'),
            style: const TextStyle(
              color: Color(0xFFB8AABD),
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            bio.isEmpty ? 'Add a bio so people know what you are about.' : bio,
            key: const Key('profile-bio'),
            style: TextStyle(
              color: bio.isEmpty
                  ? const Color(0xFF8E8494)
                  : const Color(0xFFE5DDE8),
              fontSize: 14,
              height: 1.42,
            ),
          ),
        ],
      ),
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
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF151019),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF32253A)),
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
          style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFFA49AA9),
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 32, color: const Color(0xFF382A40));
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
          padding: const EdgeInsets.fromLTRB(16, 15, 14, 15),
          decoration: BoxDecoration(
            color: const Color(0xFF151019),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF3C2948)),
          ),
          child: const Row(
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: Color(0xFF2C1B38),
                  borderRadius: BorderRadius.all(Radius.circular(14)),
                ),
                child: Padding(
                  padding: EdgeInsets.all(11),
                  child: Icon(
                    Icons.workspace_premium_outlined,
                    color: Color(0xFFC99BFF),
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
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Earnings and creator tools',
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

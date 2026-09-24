import 'package:flutter/material.dart';

import '../../data/fameverse_backend.dart';

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
  final Future<void> Function() onChangePhoto;
  final VoidCallback onSettings;
  final VoidCallback onEdit;
  final VoidCallback onCreatorStudio;
  final Future<void> Function() onSignOut;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        key: const Key('native-profile-revamp'),
        padding: const EdgeInsets.fromLTRB(0, 8, 0, 120),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Row(
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'FAMEVERSE',
                      style: TextStyle(
                        color: Color(0xFFB784FF),
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.25,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Profile',
                      key: Key('profile-title'),
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                IconButton.filledTonal(
                  key: const Key('profile-settings'),
                  onPressed: onSettings,
                  icon: const Icon(Icons.settings_rounded),
                  tooltip: 'Settings',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _ProfileHero(
            profile: profile,
            avatarBusy: avatarBusy,
            onChangePhoto: onChangePhoto,
          ),
          Transform.translate(
            offset: const Offset(0, -36),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Column(
                children: [
                  const SizedBox(height: 76),
                  Text(
                    profile.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 27,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    profile.handle,
                    style: const TextStyle(
                      color: Color(0xFFB7ACBF),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    profile.bio.trim().isEmpty
                        ? 'Add a bio so people know what you are about.'
                        : profile.bio.trim(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      height: 1.45,
                      color: profile.bio.trim().isEmpty
                          ? const Color(0xFF8F8497)
                          : const Color(0xFFE9E2ED),
                    ),
                  ),
                  const SizedBox(height: 22),
                  _ConnectionStrip(network: network),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      key: const Key('profile-edit'),
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit_outlined, size: 19),
                      label: const Text('Edit profile'),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  _CreatorStudioCard(onTap: onCreatorStudio),
                  const SizedBox(height: 28),
                  const _SectionLabel('ACCOUNT'),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: _profilePanel(),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: const Color(0xFF352245),
                            borderRadius: BorderRadius.circular(13),
                          ),
                          child: const Icon(Icons.mail_outline_rounded, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Signed in as',
                                style: TextStyle(
                                  color: Color(0xFFAFA4B8),
                                  fontSize: 11,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                identity.email,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: onSignOut,
                      icon: const Icon(Icons.logout_rounded),
                      label: const Text('Sign out'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
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
  final Future<void> Function() onChangePhoto;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 190,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          Positioned.fill(
            bottom: 36,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: const Color(0xFF5D3978)),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF55257A),
                    Color(0xFF2A143C),
                    Color(0xFF130C19),
                  ],
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: -22,
                    top: -30,
                    child: Icon(
                      Icons.auto_awesome,
                      size: 148,
                      color: Colors.white.withValues(alpha: .035),
                    ),
                  ),
                  const Positioned(
                    left: 18,
                    top: 18,
                    child: Text(
                      'YOUR SPACE',
                      style: TextStyle(
                        color: Color(0xFFDCC8ED),
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.3,
                      ),
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
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF0C0810),
                  ),
                  child: CircleAvatar(
                    radius: 58,
                    backgroundColor: const Color(0xFF45285F),
                    foregroundImage: profile.avatarUrl == null
                        ? null
                        : NetworkImage(profile.avatarUrl!),
                    child: Text(
                      profile.initial,
                      style: const TextStyle(
                        fontSize: 35,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: -3,
                  bottom: 7,
                  child: Material(
                    color: const Color(0xFF9D55FF),
                    shape: const CircleBorder(),
                    child: InkWell(
                      key: const Key('profile-change-photo'),
                      customBorder: const CircleBorder(),
                      onTap: avatarBusy ? null : onChangePhoto,
                      child: SizedBox(
                        width: 38,
                        height: 38,
                        child: avatarBusy
                            ? const Padding(
                                padding: EdgeInsets.all(10),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(
                                Icons.photo_camera_outlined,
                                size: 19,
                                color: Colors.white,
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

class _ConnectionStrip extends StatelessWidget {
  const _ConnectionStrip({required this.network});

  final FvFollowNetwork network;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 15),
      decoration: _profilePanel(),
      child: Row(
        children: [
          _ConnectionStat(label: 'Followers', value: network.followers.length),
          const _StatDivider(),
          _ConnectionStat(label: 'Following', value: network.following.length),
          const _StatDivider(),
          _ConnectionStat(label: 'Friends', value: network.friends.length),
        ],
      ),
    );
  }
}

class _ConnectionStat extends StatelessWidget {
  const _ConnectionStat({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            _compactProfile(value),
            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(color: Color(0xFFAFA4B8), fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 30, color: const Color(0xFF34283D));
  }
}

class _CreatorStudioCard extends StatelessWidget {
  const _CreatorStudioCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: const Key('open-creator-studio'),
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Ink(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF39204D), Color(0xFF1B1123)],
          ),
          border: Border.all(color: const Color(0xFF604079)),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFF9D55FF).withValues(alpha: .16),
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Icon(
                Icons.workspace_premium_outlined,
                color: Color(0xFFC99BFF),
              ),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CREATOR TOOLS',
                    style: TextStyle(
                      color: Color(0xFFB784FF),
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.1,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Creator Studio',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Earnings, payouts & creator tools',
                    style: TextStyle(
                      color: Color(0xFFB5A9BE),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFFC7B9CF)),
          ],
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
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF9F91A8),
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

BoxDecoration _profilePanel() {
  return BoxDecoration(
    color: const Color(0xFF17111E),
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: const Color(0xFF2E2238)),
  );
}

String _compactProfile(int value) {
  if (value >= 1000000) {
    return '${(value / 1000000).toStringAsFixed(value >= 10000000 ? 0 : 1)}M';
  }
  if (value >= 1000) {
    return '${(value / 1000).toStringAsFixed(value >= 10000 ? 0 : 1)}K';
  }
  return '$value';
}

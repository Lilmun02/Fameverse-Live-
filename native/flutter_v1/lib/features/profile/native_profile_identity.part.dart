part of 'native_profile_screen.dart';

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

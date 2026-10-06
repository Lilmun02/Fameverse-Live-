part of 'native_profile_screen.dart';

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
          Expanded(
            child: _Stat(value: followers, label: 'Followers'),
          ),
          const _StatDivider(),
          Expanded(
            child: _Stat(value: following, label: 'Following'),
          ),
          const _StatDivider(),
          Expanded(
            child: _Stat(value: friends, label: 'Friends'),
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
          style: const TextStyle(fontSize: 38, fontWeight: FontWeight.w900),
        ),
      ),
    );
  }
}

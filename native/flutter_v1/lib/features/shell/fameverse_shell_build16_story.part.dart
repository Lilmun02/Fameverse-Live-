part of 'fameverse_shell_build16.dart';

class _HomeStoryLauncher extends StatelessWidget {
  const _HomeStoryLauncher({required this.profile, required this.onTap});

  final FvProfile profile;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Open Creator Stories',
      child: GestureDetector(
        key: const Key('home-stories-ring'),
        onTap: onTap,
        child: Container(
          width: 64,
          height: 64,
          padding: const EdgeInsets.all(3),
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [Color(0xFFF05A86), Color(0xFFB95EFF), Color(0xFF604BFF)],
            ),
            boxShadow: [BoxShadow(color: Color(0x665E1B9B), blurRadius: 14)],
          ),
          child: Container(
            padding: const EdgeInsets.all(2),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black,
            ),
            child: ClipOval(
              child: profile.avatarUrl != null && profile.avatarUrl!.isNotEmpty
                  ? Image.network(
                      profile.avatarUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          _StoryLauncherFallback(initial: profile.initial),
                    )
                  : _StoryLauncherFallback(initial: profile.initial),
            ),
          ),
        ),
      ),
    );
  }
}

class _StoryLauncherFallback extends StatelessWidget {
  const _StoryLauncherFallback({required this.initial});

  final String initial;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFF352044),
      child: Center(
        child: Text(
          initial,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
        ),
      ),
    );
  }
}

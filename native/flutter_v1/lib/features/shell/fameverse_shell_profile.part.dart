part of 'fameverse_shell.dart';

class _ProfileScreen extends StatelessWidget {
  const _ProfileScreen({
    required this.profile,
    required this.identity,
    required this.network,
    required this.avatarBusy,
    required this.onChangePhoto,
    required this.onSettings,
    required this.onEdit,
    required this.onSignOut,
  });

  final FvProfile profile;
  final FvIdentity identity;
  final FvFollowNetwork network;
  final bool avatarBusy;
  final Future<void> Function() onChangePhoto;
  final VoidCallback onSettings;
  final VoidCallback onEdit;
  final Future<void> Function() onSignOut;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 120),
        children: [
          Row(
            children: [
              const Text(
                'PROFILE',
                key: Key('profile-title'),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.3,
                ),
              ),
              const Spacer(),
              IconButton.filledTonal(
                key: const Key('profile-settings'),
                onPressed: onSettings,
                icon: const Icon(Icons.settings_rounded),
                tooltip: 'Settings',
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_rounded),
                tooltip: 'Edit profile',
              ),
            ],
          ),
          const SizedBox(height: 26),
          Center(child: _LargeAvatar(profile: profile)),
          const SizedBox(height: 10),
          Center(
            child: TextButton.icon(
              key: const Key('profile-change-photo'),
              onPressed: avatarBusy ? null : onChangePhoto,
              icon: avatarBusy
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.photo_camera_outlined),
              label: Text(avatarBusy ? 'Updating…' : 'Change photo'),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              profile.displayName,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
            ),
          ),
          const SizedBox(height: 4),
          Center(
            child: Text(
              profile.handle,
              style: const TextStyle(color: Color(0xFFAFA5B7)),
            ),
          ),
          if (profile.bio.trim().isNotEmpty) ...[
            const SizedBox(height: 14),
            Center(
              child: Text(
                profile.bio,
                textAlign: TextAlign.center,
                style: const TextStyle(height: 1.4),
              ),
            ),
          ],
          const SizedBox(height: 28),
          Row(
            children: [
              _StatCard(label: 'Followers', value: network.followers.length),
              const SizedBox(width: 10),
              _StatCard(label: 'Following', value: network.following.length),
              const SizedBox(width: 10),
              _StatCard(label: 'Friends', value: network.friends.length),
            ],
          ),
          const SizedBox(height: 28),
          const _Eyebrow('ACCOUNT'),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: _panelDecoration(),
            child: Row(
              children: [
                const Icon(Icons.mail_outline_rounded),
                const SizedBox(width: 12),
                Expanded(child: Text(identity.email)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onSignOut,
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Sign out'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
            ),
          ),
        ],
      ),
    );
  }
}

class _EditProfileSheet extends StatefulWidget {
  const _EditProfileSheet({required this.profile, required this.onSave});

  final FvProfile profile;
  final Future<void> Function({
    required String displayName,
    required String username,
    required String bio,
  })
  onSave;

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  late final TextEditingController _displayName;
  late final TextEditingController _username;
  late final TextEditingController _bio;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _displayName = TextEditingController(text: widget.profile.displayName);
    _username = TextEditingController(text: widget.profile.username ?? '');
    _bio = TextEditingController(text: widget.profile.bio);
  }

  @override
  void dispose() {
    _displayName.dispose();
    _username.dispose();
    _bio.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_busy) return;
    setState(() => _busy = true);
    await widget.onSave(
      displayName: _displayName.text,
      username: _username.text,
      bio: _bio.text,
    );
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        8,
        20,
        MediaQuery.viewInsetsOf(context).bottom + 28,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Edit profile',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: _displayName,
              maxLength: 40,
              decoration: const InputDecoration(labelText: 'Display name'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _username,
              maxLength: 24,
              decoration: const InputDecoration(labelText: 'Username'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _bio,
              maxLength: 160,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'Bio'),
            ),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: _busy ? null : _save,
              child: _busy
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save profile'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsSheet extends StatelessWidget {
  const _SettingsSheet();

  static const _terms =
      '''Fameverse Beta Terms of Use\n\nFameverse is currently a beta service. Features may change while we test and improve the product. You must use Fameverse lawfully and may not abuse, disrupt, exploit, automate attacks against, or attempt to bypass safety and moderation systems.\n\nBeta test coins and beta gifts are test-only. They are not money, cannot be purchased for real money in this beta, and are not eligible for cash-out or payout. Real purchases, creator earnings, and payout terms will be presented separately before those features are activated.\n\nYou remain responsible for content you create, stream, upload, or send. Fameverse may remove content or restrict accounts when needed to enforce these terms, protect users, or comply with law.''';

  static const _privacy =
      '''Fameverse Beta Privacy Notice\n\nFameverse uses account information, profile information, social connections, live-room activity, comments, gifts, FameTaps, moderation signals, and technical information needed to operate and secure the beta.\n\nProfile information you choose to publish can be visible to other Fameverse users. Live activity is shared with participants as required for the experience. Authentication and authoritative app data are handled through Fameverse backend services.\n\nAs the beta expands, this notice will be updated before new real-money, payout, or materially different data uses are activated.''';

  static const _community =
      '''Fameverse Community Standards\n\nFameverse is for real people to create, watch, gift, and belong. Do not use Fameverse for credible threats, targeted harassment, hateful abuse, sexual exploitation, scams, impersonation intended to defraud, illegal content, spam, platform manipulation, or attempts to compromise another user's account or device.\n\nCreators are responsible for moderating their live spaces with the tools provided. Fameverse may remove content, end a live, restrict features, or suspend accounts when necessary to protect the community and enforce these standards.''';

  static const _creator =
      '''Fameverse Creator Beta Terms\n\nCreators are responsible for their live content, titles, goals, interactions, and moderation choices. Do not misrepresent beta gifts or test coins as real-money earnings. During this beta, gift balances and creator gift activity are testing data only and do not create a payout entitlement.\n\nCreators must not encourage fraud, artificial engagement, coordinated abuse, or manipulation of gifts, FameTaps, rankings, or safety systems. Additional purchase, high-value gifting, earnings, and payout terms will be added and presented before real-money creator monetization is enabled.''';

  void _open(BuildContext context, String title, String body) {
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (context) => _LegalDocumentScreen(title: title, body: body),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * .72,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: [
            const Text(
              'Settings',
              key: Key('native-settings-title'),
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            const Text(
              'Fameverse beta policies and account information.',
              style: TextStyle(color: Color(0xFFAFA4B8)),
            ),
            const SizedBox(height: 22),
            _SettingsTile(
              icon: Icons.description_outlined,
              title: 'Terms of Use',
              onTap: () => _open(context, 'Terms of Use', _terms),
            ),
            _SettingsTile(
              icon: Icons.privacy_tip_outlined,
              title: 'Privacy Notice',
              onTap: () => _open(context, 'Privacy Notice', _privacy),
            ),
            _SettingsTile(
              icon: Icons.shield_outlined,
              title: 'Community Standards',
              onTap: () => _open(context, 'Community Standards', _community),
            ),
            _SettingsTile(
              icon: Icons.live_tv_outlined,
              title: 'Creator Beta Terms',
              onTap: () => _open(context, 'Creator Beta Terms', _creator),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      ),
    );
  }
}

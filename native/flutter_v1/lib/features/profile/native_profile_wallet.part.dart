part of 'native_profile_screen.dart';

class _FameCoinWalletCard extends StatefulWidget {
  const _FameCoinWalletCard({required this.userId});

  final String userId;

  @override
  State<_FameCoinWalletCard> createState() => _FameCoinWalletCardState();
}

class _FameCoinWalletCardState extends State<_FameCoinWalletCard>
    with WidgetsBindingObserver {
  int? _balance;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _load();
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
    final balanceText = _balance == null ? '—' : '${_balance!}';
    return Container(
      key: const Key('profile-fame-coin-wallet'),
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF5C3470)),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF271334), Color(0xFF151019)],
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF4B2465),
            ),
            child: const Icon(Icons.toll_rounded, color: Color(0xFFD7A5FF)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Fame Coins',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 2),
                Text(
                  _loading && _balance == null
                      ? 'Loading balance…'
                      : balanceText,
                  style: const TextStyle(
                    color: Color(0xFFE2BCFF),
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                const Text(
                  'Spendable gifting balance · creator cash-out uses separate Creator Earnings.',
                  style: TextStyle(color: Color(0xFF9F92A4), fontSize: 10),
                ),
              ],
            ),
          ),
          IconButton(
            key: const Key('refresh-fame-coin-wallet'),
            onPressed: _loading ? null : _load,
            tooltip: 'Refresh Fame Coins',
            icon: _loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh_rounded),
          ),
        ],
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

part of 'native_profile_build23.dart';

class _PremiumHero extends StatelessWidget {
  const _PremiumHero({
    required this.profile,
    required this.isOwner,
    required this.avatarBusy,
    required this.onChangePhoto,
  });

  final FvProfile profile;
  final bool isOwner;
  final bool avatarBusy;
  final VoidCallback onChangePhoto;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 182,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            bottom: 54,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(26),
                border: Border.all(
                  color: isOwner
                      ? const Color(0xFFB98543)
                      : const Color(0xFF6E348A),
                  width: 1.2,
                ),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isOwner
                      ? const [
                          Color(0xFF4B2B16),
                          Color(0xFF251426),
                          Color(0xFF0B080E),
                        ]
                      : const [
                          Color(0xFF321342),
                          Color(0xFF1A0D22),
                          Color(0xFF0B080E),
                        ],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(17),
                child: Align(
                  alignment: Alignment.topLeft,
                  child: Text(
                    isOwner ? 'OWNER PREMIUM PROFILE' : 'YOUR FAMEVERSE',
                    style: TextStyle(
                      color: isOwner
                          ? const Color(0xFFFFD99A)
                          : const Color(0xFFBFA5CB),
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.6,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 118,
                height: 118,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black,
                  border: Border.all(
                    color: isOwner
                        ? const Color(0xFFFFC96C)
                        : const Color(0xFFB45FFF),
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isOwner
                          ? const Color(0x66C9862F)
                          : const Color(0x665B1688),
                      blurRadius: 24,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: ClipOval(child: _Avatar(profile: profile)),
              ),
              Positioned(
                right: -3,
                bottom: 5,
                child: Material(
                  color: isOwner
                      ? const Color(0xFFB77B2D)
                      : const Color(0xFF913CE6),
                  shape: const CircleBorder(),
                  child: InkWell(
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
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.profile});
  final FvProfile profile;

  @override
  Widget build(BuildContext context) {
    final url = profile.avatarUrl?.trim();
    if (url != null && url.isNotEmpty) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _Fallback(initial: profile.initial),
      );
    }
    return _Fallback(initial: profile.initial);
  }
}

class _Fallback extends StatelessWidget {
  const _Fallback({required this.initial});
  final String initial;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFF352044),
      child: Center(
        child: Text(
          initial,
          style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900),
        ),
      ),
    );
  }
}

class _Stats extends StatelessWidget {
  const _Stats({
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

class _Divider extends StatelessWidget {
  const _Divider();
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

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          '$value',
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

class _WalletCard extends StatefulWidget {
  const _WalletCard({required this.userId});
  final String userId;

  @override
  State<_WalletCard> createState() => _WalletCardState();
}

class _WalletCardState extends State<_WalletCard> {
  int? _balance;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
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

  Future<void> _openStore() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => FameCoinStoreScreen(
          userId: widget.userId,
          onBalanceChanged: (balance) {
            if (mounted) setState(() => _balance = balance);
          },
        ),
      ),
    );
    if (mounted) await _load();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: const Key('profile-fame-coins-card'),
      behavior: HitTestBehavior.opaque,
      onTap: _loading ? null : _openStore,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFF5C3470)),
          gradient: const LinearGradient(
            colors: [Color(0xFF271334), Color(0xFF151019)],
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.toll_rounded, color: Color(0xFFD7A5FF)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Fame Coins',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                  Text(
                    _loading && _balance == null
                        ? 'Loading…'
                        : '${_balance ?? 0}',
                    style: const TextStyle(
                      color: Color(0xFFE2BCFF),
                      fontSize: 21,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const Text(
                    'Gifting balance. Creator cash earnings remain separate.',
                    style: TextStyle(color: Color(0xFF9F92A4), fontSize: 10),
                  ),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                FilledButton.tonal(
                  key: const Key('profile-buy-fame-coins'),
                  onPressed: _loading ? null : _openStore,
                  child: const Text('Buy'),
                ),
                IconButton(
                  onPressed: _loading ? null : _load,
                  tooltip: 'Refresh Fame Coins',
                  icon: _loading
                      ? const SizedBox(
                          width: 17,
                          height: 17,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh_rounded),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

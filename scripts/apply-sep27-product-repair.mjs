import fs from 'node:fs';

function read(path) {
  return fs.readFileSync(path, 'utf8');
}

function write(path, text) {
  fs.writeFileSync(path, text);
}

function replaceOnce(text, from, to, label) {
  const first = text.indexOf(from);
  if (first < 0) throw new Error(`Missing patch target: ${label}`);
  if (text.indexOf(from, first + from.length) >= 0) {
    throw new Error(`Patch target is not unique: ${label}`);
  }
  return text.slice(0, first) + to + text.slice(first + from.length);
}

function patch(path, operations) {
  let text = read(path);
  for (const operation of operations) {
    text = replaceOnce(text, operation.from, operation.to, operation.label);
  }
  write(path, text);
}

const returnBase = 'https://fameverse-live-jen9qlbv8-aiw-core.vercel.app/paypal-return.html';

patch('supabase/functions/recharge/index.ts', [
  {
    label: 'PayPal return URL constant',
    from: 'const CUSTOM_CENTS_PER_COIN = 1;\n',
    to: `const CUSTOM_CENTS_PER_COIN = 1;\nconst PAYPAL_RETURN_URL = "${returnBase}";\n`,
  },
  {
    label: 'PayPal approval experience context',
    from: '          body: JSON.stringify({\n            intent: "CAPTURE",\n            purchase_units: [',
    to: '          body: JSON.stringify({\n            intent: "CAPTURE",\n            payment_source: {\n              paypal: {\n                experience_context: {\n                  brand_name: "Fameverse",\n                  landing_page: "LOGIN",\n                  shipping_preference: "NO_SHIPPING",\n                  user_action: "PAY_NOW",\n                  return_url: `${PAYPAL_RETURN_URL}?status=approved`,\n                  cancel_url: `${PAYPAL_RETURN_URL}?status=cancelled`,\n                },\n              },\n            },\n            purchase_units: [',
  },
]);

patch('native/flutter_v1/lib/features/profile/native_profile_screen.dart', [
  {
    label: 'profile Supabase import',
    from: "import 'package:flutter/material.dart';\n\nimport '../../data/fameverse_backend.dart';",
    to: "import 'package:flutter/material.dart';\nimport 'package:supabase_flutter/supabase_flutter.dart';\n\nimport '../../data/fameverse_backend.dart';",
  },
  {
    label: 'profile Fame Coin wallet card placement',
    from: '                  _ConnectionStats(\n                    followers: network.followers.length,\n                    following: network.following.length,\n                    friends: _friendCount,\n                  ),\n                  const SizedBox(height: 18),\n                  _ProfileActions(',
    to: '                  _ConnectionStats(\n                    followers: network.followers.length,\n                    following: network.following.length,\n                    friends: _friendCount,\n                  ),\n                  const SizedBox(height: 14),\n                  _FameCoinWalletCard(userId: identity.id),\n                  const SizedBox(height: 18),\n                  _ProfileActions(',
  },
  {
    label: 'profile Fame Coin wallet component',
    from: 'class _FameverseSettingsScreen extends StatelessWidget {',
    to: `class _FameCoinWalletCard extends StatefulWidget {
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
    final balanceText = _balance == null ? '—' : '\${_balance!}';
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
                  _loading && _balance == null ? 'Loading balance…' : balanceText,
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

class _FameverseSettingsScreen extends StatelessWidget {`,
  },
]);

patch('native/flutter_v1/lib/data/fameverse_creator_backend.dart', [
  {
    label: 'creator payout method model',
    from: 'class SupabaseFameverseCreatorBackend {',
    to: `class FvCreatorPayoutMethod {
  const FvCreatorPayoutMethod({
    required this.provider,
    required this.recipientEmail,
    required this.enabled,
  });

  final String provider;
  final String recipientEmail;
  final bool enabled;

  factory FvCreatorPayoutMethod.fromMap(Map<String, dynamic> row) {
    return FvCreatorPayoutMethod(
      provider: row['provider']?.toString() ?? 'paypal',
      recipientEmail: row['recipient_email']?.toString() ?? '',
      enabled: row['enabled'] == true,
    );
  }
}

class SupabaseFameverseCreatorBackend {`,
  },
  {
    label: 'creator payout method backend methods',
    from: "  Future<FvCreatorPayoutSummary> loadPayoutSummary() async {",
    to: `  Future<FvCreatorPayoutMethod?> loadPayoutMethod() async {
    final response = await _client.rpc('get_creator_payout_method');
    final rows = _rows(response);
    if (rows.isEmpty) return null;
    return FvCreatorPayoutMethod.fromMap(rows.first);
  }

  Future<FvCreatorPayoutMethod> setPayoutMethod({
    required String recipientEmail,
  }) async {
    final response = await _client.rpc(
      'set_creator_payout_method',
      params: {
        'p_provider': 'paypal',
        'p_recipient_email': recipientEmail.trim(),
      },
    );
    final rows = _rows(response);
    if (rows.isEmpty) throw Exception('Payout method was not saved.');
    return FvCreatorPayoutMethod.fromMap(rows.first);
  }

  Future<FvCreatorPayoutSummary> loadPayoutSummary() async {`,
  },
]);

patch('native/flutter_v1/lib/features/profile/creator_studio_screen.dart', [
  {
    label: 'creator studio payout method state',
    from: '  FvCreatorPayoutSummary _summary = FvCreatorPayoutSummary.empty;\n  List<FvCreatorPayoutRequest> _requests = const [];',
    to: '  FvCreatorPayoutSummary _summary = FvCreatorPayoutSummary.empty;\n  FvCreatorPayoutMethod? _payoutMethod;\n  List<FvCreatorPayoutRequest> _requests = const [];',
  },
  {
    label: 'creator studio load payout method',
    from: '        widget.backend.loadPayoutSummary(),\n        widget.backend.listPayoutRequests(),\n        widget.backend.loadRole(widget.identity.id),',
    to: '        widget.backend.loadPayoutSummary(),\n        widget.backend.listPayoutRequests(),\n        widget.backend.loadPayoutMethod(),\n        widget.backend.loadRole(widget.identity.id),',
  },
  {
    label: 'creator studio assign payout method',
    from: '        _summary = results[0] as FvCreatorPayoutSummary;\n        _requests = results[1] as List<FvCreatorPayoutRequest>;\n        _accountRole = results[2] as String?;',
    to: '        _summary = results[0] as FvCreatorPayoutSummary;\n        _requests = results[1] as List<FvCreatorPayoutRequest>;\n        _payoutMethod = results[2] as FvCreatorPayoutMethod?;\n        _accountRole = results[3] as String?;',
  },
  {
    label: 'creator studio payout method editor',
    from: '  Future<void> _openPayoutRequest() async {',
    to: `  Future<void> _openPayoutMethod() async {
    if (_busy) return;
    final controller = TextEditingController(
      text: _payoutMethod?.recipientEmail ?? '',
    );
    final email = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('PayPal payout email'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter the email attached to the PayPal account where Fameverse should send approved creator payouts.',
              style: TextStyle(color: Color(0xFFB5A9BE), height: 1.35),
            ),
            const SizedBox(height: 16),
            TextField(
              key: const Key('creator-paypal-payout-email'),
              controller: controller,
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              textCapitalization: TextCapitalization.none,
              decoration: const InputDecoration(
                labelText: 'PayPal email',
                prefixIcon: Icon(Icons.paypal_outlined),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (email == null) return;
    if (!email.contains('@') || !email.substring(email.indexOf('@') + 1).contains('.')) {
      _message('Enter a valid PayPal email address.');
      return;
    }

    setState(() => _busy = true);
    try {
      final method = await widget.backend.setPayoutMethod(recipientEmail: email);
      if (mounted) setState(() => _payoutMethod = method);
      _message('PayPal payout method saved.');
      await _refresh();
    } catch (_) {
      _message('Could not save that PayPal payout email.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openPayoutRequest() async {`,
  },
  {
    label: 'creator studio payout method card placement',
    from: "                _PayoutEligibilityCard(status: _summary.verificationStatus),\n                const SizedBox(height: 12),\n                _PayoutCard(\n                  summary: _summary,\n                  busy: _busy,\n                  onRequest: _openPayoutRequest,\n                ),",
    to: "                _PayoutEligibilityCard(status: _summary.verificationStatus),\n                const SizedBox(height: 12),\n                _PayoutMethodCard(\n                  method: _payoutMethod,\n                  busy: _busy,\n                  onEdit: _openPayoutMethod,\n                ),\n                const SizedBox(height: 12),\n                _PayoutCard(\n                  summary: _summary,\n                  hasPayoutMethod: _payoutMethod?.enabled == true,\n                  busy: _busy,\n                  onRequest: _openPayoutRequest,\n                ),",
  },
  {
    label: 'creator studio payout method card component',
    from: 'class _PayoutCard extends StatelessWidget {',
    to: `class _PayoutMethodCard extends StatelessWidget {
  const _PayoutMethodCard({
    required this.method,
    required this.busy,
    required this.onEdit,
  });

  final FvCreatorPayoutMethod? method;
  final bool busy;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final configured = method?.enabled == true && method!.recipientEmail.isNotEmpty;
    return Container(
      key: const Key('creator-paypal-payout-method'),
      padding: const EdgeInsets.all(18),
      decoration: _panelDecoration(),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF1C2B55),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.paypal_outlined, color: Color(0xFF8BB7FF)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'PayPal payout method',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 3),
                Text(
                  configured ? method!.recipientEmail : 'No PayPal payout email added',
                  style: TextStyle(
                    color: configured
                        ? const Color(0xFFDAD0DF)
                        : const Color(0xFFFFB5C2),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Fame Coins are not cashable. Approved Creator Earnings are paid separately.',
                  style: TextStyle(color: Color(0xFF93889B), fontSize: 10, height: 1.3),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: busy ? null : onEdit,
            child: Text(configured ? 'Change' : 'Add'),
          ),
        ],
      ),
    );
  }
}

class _PayoutCard extends StatelessWidget {`,
  },
  {
    label: 'creator studio payout card method requirement constructor',
    from: '    required this.summary,\n    required this.busy,\n    required this.onRequest,',
    to: '    required this.summary,\n    required this.hasPayoutMethod,\n    required this.busy,\n    required this.onRequest,',
  },
  {
    label: 'creator studio payout card method requirement field',
    from: '  final FvCreatorPayoutSummary summary;\n  final bool busy;',
    to: '  final FvCreatorPayoutSummary summary;\n  final bool hasPayoutMethod;\n  final bool busy;',
  },
  {
    label: 'creator studio payout disabled reason',
    from: "    final disabledReason = !summary.isVerified\n        ? 'Payout setup required'\n        : summary.withdrawableCents < summary.minimumPayoutCents",
    to: "    final disabledReason = !hasPayoutMethod\n        ? 'Add PayPal payout email'\n        : !summary.isVerified\n        ? 'Payout setup required'\n        : summary.withdrawableCents < summary.minimumPayoutCents",
  },
  {
    label: 'creator studio payout button method gate',
    from: '              onPressed: busy || !summary.canRequestPayout ? null : onRequest,',
    to: '              onPressed: busy || !hasPayoutMethod || !summary.canRequestPayout\n                  ? null\n                  : onRequest,',
  },
]);

patch('native/flutter_v1/lib/features/shell/fameverse_home_screen.dart', [
  {
    label: 'home creator profile callback constructor',
    from: '    required this.onToggleFollow,\n    required this.followBusy,',
    to: '    required this.onToggleFollow,\n    required this.onCreatorSelected,\n    required this.followBusy,',
  },
  {
    label: 'home creator profile callback field',
    from: '  final ValueChanged<String> onToggleFollow;\n  final bool followBusy;',
    to: '  final ValueChanged<String> onToggleFollow;\n  final ValueChanged<FvProfile> onCreatorSelected;\n  final bool followBusy;',
  },
  {
    label: 'home creator card open callback',
    from: '                      onFollow: () => widget.onToggleFollow(creator.profile.id),\n                    );',
    to: '                      onFollow: () => widget.onToggleFollow(creator.profile.id),\n                      onOpen: () => widget.onCreatorSelected(creator.profile),\n                    );',
  },
  {
    label: 'home suggested creator constructor open callback',
    from: '    required this.busy,\n    required this.onFollow,\n  });',
    to: '    required this.busy,\n    required this.onFollow,\n    required this.onOpen,\n  });',
  },
  {
    label: 'home suggested creator open callback field',
    from: '  final bool busy;\n  final VoidCallback onFollow;\n\n  @override\n  Widget build(BuildContext context) {\n    return Container(',
    to: '  final bool busy;\n  final VoidCallback onFollow;\n  final VoidCallback onOpen;\n\n  @override\n  Widget build(BuildContext context) {\n    return Container(',
  },
  {
    label: 'home suggested creator tappable avatar',
    from: '          _Avatar(profile: creator.profile, radius: 29),',
    to: '          GestureDetector(\n            key: Key(\'home-creator-profile-${creator.profile.id}\'),\n            onTap: onOpen,\n            child: _Avatar(profile: creator.profile, radius: 29),\n          ),',
  },
]);

patch('native/flutter_v1/lib/features/shell/fameverse_discover_screen.dart', [
  {
    label: 'discover creator profile callback constructor',
    from: '    required this.onToggleFollow,\n    required this.followBusy,\n    required this.onOpenProfile,',
    to: '    required this.onToggleFollow,\n    required this.onCreatorSelected,\n    required this.followBusy,\n    required this.onOpenProfile,',
  },
  {
    label: 'discover creator profile callback field',
    from: '  final ValueChanged<String> onToggleFollow;\n  final bool followBusy;',
    to: '  final ValueChanged<String> onToggleFollow;\n  final ValueChanged<FvProfile> onCreatorSelected;\n  final bool followBusy;',
  },
  {
    label: 'discover creator card open callback',
    from: '                        onFollow: () =>\n                            widget.onToggleFollow(creator.profile.id),\n                      ),',
    to: '                        onFollow: () =>\n                            widget.onToggleFollow(creator.profile.id),\n                        onOpen: () => widget.onCreatorSelected(creator.profile),\n                      ),',
  },
  {
    label: 'discover creator result constructor open callback',
    from: '    required this.busy,\n    required this.onFollow,\n  });',
    to: '    required this.busy,\n    required this.onFollow,\n    required this.onOpen,\n  });',
  },
  {
    label: 'discover creator result open callback field',
    from: '  final bool busy;\n  final VoidCallback onFollow;\n\n  @override\n  Widget build(BuildContext context) {',
    to: '  final bool busy;\n  final VoidCallback onFollow;\n  final VoidCallback onOpen;\n\n  @override\n  Widget build(BuildContext context) {',
  },
  {
    label: 'discover creator tappable avatar',
    from: '          _DiscoverAvatar(profile: creator.profile, radius: 27),',
    to: '          GestureDetector(\n            key: Key(\'discover-creator-profile-${creator.profile.id}\'),\n            onTap: onOpen,\n            child: _DiscoverAvatar(profile: creator.profile, radius: 27),\n          ),',
  },
]);

patch('native/flutter_v1/lib/features/shell/fameverse_shell_build16.dart', [
  {
    label: 'shell public profile import',
    from: "import '../profile/fameverse_policy_screen.dart';\nimport '../profile/native_profile_screen.dart';",
    to: "import '../profile/fameverse_policy_screen.dart';\nimport '../profile/fameverse_public_profile_screen.dart';\nimport '../profile/native_profile_screen.dart';",
  },
  {
    label: 'shell public profile navigator',
    from: '  void _openCreatorStudio(FvProfile profile) {\n    Navigator.of(context).push<void>(\n      MaterialPageRoute(\n        builder: (context) => CreatorStudioScreen(\n          backend: SupabaseFameverseCreatorBackend(Supabase.instance.client),\n          identity: widget.identity,\n          profile: profile,\n        ),\n      ),\n    );\n  }\n\n  void _openRoom(FvLiveRoom room, FvProfile profile) {',
    to: `  void _openCreatorStudio(FvProfile profile) {
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (context) => CreatorStudioScreen(
          backend: SupabaseFameverseCreatorBackend(Supabase.instance.client),
          identity: widget.identity,
          profile: profile,
        ),
      ),
    );
  }

  Future<void> _openPublicProfile(FvProfile target) async {
    if (target.id == widget.identity.id) {
      _setTab(3);
      return;
    }
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (context) => FameversePublicProfileScreen(
          viewerUserId: widget.identity.id,
          targetUserId: target.id,
          initialProfile: target,
        ),
      ),
    );
    try {
      final network = await widget.backend.loadFollowNetwork(widget.identity.id);
      if (mounted) setState(() => _network = network);
    } catch (_) {}
  }

  void _openRoom(FvLiveRoom room, FvProfile profile) {`,
  },
  {
    label: 'shell home creator profile wiring',
    from: '            onToggleFollow: _toggleFollow,\n            followBusy: _followBusy,\n          ),',
    to: '            onToggleFollow: _toggleFollow,\n            onCreatorSelected: _openPublicProfile,\n            followBusy: _followBusy,\n          ),',
  },
  {
    label: 'shell discover creator profile wiring',
    from: '            onToggleFollow: _toggleFollow,\n            followBusy: _followBusy,\n            onOpenProfile: () => _setTab(3),',
    to: '            onToggleFollow: _toggleFollow,\n            onCreatorSelected: _openPublicProfile,\n            followBusy: _followBusy,\n            onOpenProfile: () => _setTab(3),',
  },
]);

patch('native/flutter_v1/lib/features/live/stream_host_live_screen.dart', [
  {
    label: 'host F menu share action',
    from: "                  FvRoundLiveButton(\n                    icon: Icons.group_add_rounded,\n                    label: 'Co-host',\n                    onPressed: () {\n                      Navigator.of(context).pop();\n                      _showCohostSheet();\n                    },\n                  ),\n                ],\n              ),",
    to: "                  FvRoundLiveButton(\n                    icon: Icons.group_add_rounded,\n                    label: 'Co-host',\n                    onPressed: () {\n                      Navigator.of(context).pop();\n                      _showCohostSheet();\n                    },\n                  ),\n                ],\n              ),\n              const SizedBox(height: 10),\n              TextButton.icon(\n                key: const Key('host-share-live-action'),\n                onPressed: () {\n                  Navigator.of(context).pop();\n                  unawaited(_shareLive());\n                },\n                icon: const Icon(Icons.ios_share_rounded),\n                label: const Text('Share live'),\n              ),",
  },
  {
    label: 'host remove standalone share button',
    from: "                        const SizedBox(width: 4),\n                        IconButton.filledTonal(\n                          onPressed: _shareLive,\n                          icon: const Icon(Icons.ios_share_rounded),\n                          tooltip: 'Share',\n                        ),\n                        const SizedBox(width: 4),\n                        FvFameActionButton(",
    to: "                        const SizedBox(width: 4),\n                        FvFameActionButton(",
  },
  {
    label: 'host Live top spacing',
    from: '                padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),',
    to: '                padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),',
  },
  {
    label: 'host wordmark spacing',
    from: '                      const SizedBox(height: 10),',
    to: '                      const SizedBox(height: 14),',
  },
  {
    label: 'host avatar identity spacing',
    from: '                        const SizedBox(width: 9),',
    to: '                        const SizedBox(width: 11),',
  },
  {
    label: 'host smaller End button',
    from: "                            padding: const EdgeInsets.symmetric(\n                              horizontal: 15,\n                              vertical: 12,\n                            ),\n                            shape: RoundedRectangleBorder(\n                              borderRadius: BorderRadius.circular(18),\n                            ),",
    to: "                            minimumSize: const Size(0, 36),\n                            visualDensity: VisualDensity.compact,\n                            padding: const EdgeInsets.symmetric(\n                              horizontal: 11,\n                              vertical: 8,\n                            ),\n                            shape: RoundedRectangleBorder(\n                              borderRadius: BorderRadius.circular(14),\n                            ),",
  },
]);

patch('native/flutter_v1/lib/features/live/stream_viewer_live_screen.dart', [
  {
    label: 'owner admin only gift box',
    from: "                          const SizedBox(width: 4),\n                          IconButton.filled(\n                            key: const Key('viewer-gift-button'),\n                            onPressed: _walletReady ? _showGiftTray : null,\n                            style: IconButton.styleFrom(\n                              backgroundColor: const Color(0xFF211529),\n                              foregroundColor: const Color(0xFFFFC65A),\n                              side: const BorderSide(color: Color(0xFF4B365B)),\n                            ),\n                            icon: const Icon(Icons.card_giftcard_rounded),\n                            tooltip: 'Gifts',\n                          ),\n                          const SizedBox(width: 4),\n                          FvFameActionButton(",
    to: "                          if (_canRefill) ...[\n                            const SizedBox(width: 4),\n                            IconButton.filled(\n                              key: const Key('viewer-gift-button'),\n                              onPressed: _walletReady ? _showGiftTray : null,\n                              style: IconButton.styleFrom(\n                                backgroundColor: const Color(0xFF211529),\n                                foregroundColor: const Color(0xFFFFC65A),\n                                side: const BorderSide(color: Color(0xFF4B365B)),\n                              ),\n                              icon: const Icon(Icons.card_giftcard_rounded),\n                              tooltip: 'Gifts',\n                            ),\n                          ],\n                          const SizedBox(width: 4),\n                          FvFameActionButton(",
  },
]);

patch('native/flutter_v1/test/live_v2_release_contract_test.dart', [
  {
    label: 'live contract role gated gift',
    from: "      expect(viewer, contains(\"Key('viewer-gift-button')\"));",
    to: "      expect(viewer, contains(\"Key('viewer-gift-button')\"));\n      expect(viewer, contains('if (_canRefill) ...['));",
  },
]);

patch('native/flutter_v1/test/social_surfaces_v2_contract_test.dart', [
  {
    label: 'social contract public profiles',
    from: "    expect(shell, contains('NativeProfileScreen('));",
    to: "    expect(shell, contains('NativeProfileScreen('));\n    expect(shell, contains('FameversePublicProfileScreen('));\n    expect(home, contains('onCreatorSelected'));\n    expect(discover, contains('onCreatorSelected'));",
  },
]);

console.log('Sep 27 Fameverse product repair applied.');

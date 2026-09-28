import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'fameverse_system_status_screen.dart';

class FameversePolicyScreen extends StatefulWidget {
  const FameversePolicyScreen({super.key});

  @override
  State<FameversePolicyScreen> createState() => _FameversePolicyScreenState();
}

class _FameversePolicyScreenState extends State<FameversePolicyScreen> {
  static const _terms =
      '''Fameverse Beta Terms of Use\n\nFameverse is currently a beta service. Features may change while we test and improve the product. You must use Fameverse lawfully and may not abuse, disrupt, exploit, automate attacks against, or attempt to bypass safety, payout, gift-funding, recommendation, or moderation systems.\n\nYou remain responsible for content you create, stream, upload, comment, or send. Fameverse may remove content or restrict accounts when needed to enforce these terms, protect users, prevent fraud, or comply with law.\n\nFameverse may distinguish purchased, promotional, referral, test, and other coin funding sources internally even when the app displays one Fame Coin balance. That accounting is used to prevent unfunded creator-cash liabilities and abuse.''';

  static const _privacy =
      '''Fameverse Beta Privacy Notice\n\nFameverse uses account information, profile information, social connections, live-room activity, comments, gifts, FameTaps, story views, moderation signals, verification status, payout status, referral activity, and technical information needed to operate and secure the beta.\n\nProfile information you choose to publish can be visible to other Fameverse users. Live activity is shared with participants as required for the experience. Authentication and authoritative app data are handled through Fameverse backend services.\n\nRecommendation systems may use follows, mutual connections, eligible FameTaps, gifts, active Stories, active Live sessions, engagement momentum, freshness, and creator-discovery signals. Gift/popularity signals are capped so paid activity alone does not control ranking.\n\nPayment and payout providers may require additional information when real-money recharge or payouts are enabled. Promotional and referral coin provenance is stored separately from cash-backed coin provenance even though users see one spendable Fame Coin balance.''';

  static const _community =
      '''Fameverse Community Standards\n\nFameverse is for real people to create, watch, gift, and belong. Do not use Fameverse for credible threats, targeted harassment, hateful abuse, sexual exploitation, scams, impersonation intended to defraud, illegal content, spam, platform manipulation, or attempts to compromise another user's account or device.\n\nDo not manipulate FameTaps, referrals, gifts, creator earnings, payouts, recommendation signals, or beta achievements through automation, coordinated fraud, duplicate accounts, or other deceptive behavior.\n\nCreators are responsible for moderating their live spaces with the tools provided. Fameverse may remove content, end a live, restrict features, suspend accounts, or hold monetization when necessary to protect the community and enforce these standards.''';

  static const _creator =
      '''Fameverse Creator Beta Terms\n\nCreators are responsible for their live content, titles, goals, interactions, and moderation choices. Payout eligibility is separate from Fame Coins and requires cleared creator earnings, creator verification, account good standing, an active payout method, and Fameverse payout review. The minimum payout request is \$25.00.\n\nThe current creator gift split is 70% of eligible cash-backed gross gift value to the creator and 30% to Fameverse. Promotional, referral, and test Fame Coins may be spent as gifts but do not create creator cash earnings. Fame Coins cannot be cashed out. Creator Earnings may be exchanged one-way into Fame Coins at 100 Fame Coins per US dollar; that exchange cannot be reversed back into earnings.\n\nA balance shown as pending, reserved, processing, or under review is not yet paid. Fameverse may hold, reject, reverse, or investigate earnings or payouts where fraud, chargebacks, manipulation, policy violations, or verification problems are identified.''';

  static const _coins =
      '''Fame Coins & Referral Rules\n\nFameverse displays one Fame Coin balance for gifting, while the backend keeps funding provenance separate. Purchased or creator-exchanged coins are cash-backed. Promotional, referral, and internal test coins are promotional.\n\nQualified First Verse referrals award 100 promotional Fame Coins to the referrer and 50 promotional Fame Coins to the referred user. Promotional coins are gifting-only. They cannot be transferred, exchanged, converted, replaced, or cashed out, and gifts funded by promotional coins do not create creator cash earnings.\n\nSelf-referrals, duplicate reward claims, fabricated activity, or attempts to convert promotional value into cash are prohibited.''';

  bool _securityBusy = false;

  void _openDocument(String title, String body) {
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (context) => _PolicyDocument(title: title, body: body),
      ),
    );
  }

  void _openSystem(String section) {
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (context) =>
            FameverseSystemStatusScreen(initialSection: section),
      ),
    );
  }

  void _message(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _changePassword() async {
    if (_securityBusy) return;
    final password = TextEditingController();
    final confirm = TextEditingController();
    final submitted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              key: const Key('settings-new-password'),
              controller: password,
              obscureText: true,
              autocorrect: false,
              decoration: const InputDecoration(labelText: 'New password'),
            ),
            const SizedBox(height: 10),
            TextField(
              key: const Key('settings-confirm-password'),
              controller: confirm,
              obscureText: true,
              autocorrect: false,
              decoration: const InputDecoration(labelText: 'Confirm password'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Update'),
          ),
        ],
      ),
    );
    final next = password.text;
    final repeated = confirm.text;
    password.dispose();
    confirm.dispose();
    if (submitted != true) return;
    if (next.length < 8) {
      _message('Use at least 8 characters for your new password.');
      return;
    }
    if (next != repeated) {
      _message('Those passwords do not match.');
      return;
    }

    setState(() => _securityBusy = true);
    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: next),
      );
      _message('Fameverse password updated.');
    } catch (_) {
      _message('Password could not be updated right now.');
    } finally {
      if (mounted) setState(() => _securityBusy = false);
    }
  }

  Future<void> _signOutOtherSessions() async {
    if (_securityBusy) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign out other devices?'),
        content: const Text(
          'Your current device stays signed in. Other Fameverse sessions for this account will be signed out.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Sign out others'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _securityBusy = true);
    try {
      await Supabase.instance.client.auth.signOut(scope: SignOutScope.others);
      _message('Other Fameverse sessions signed out.');
    } catch (_) {
      _message('Other sessions could not be signed out right now.');
    } finally {
      if (mounted) setState(() => _securityBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = Supabase.instance.client.auth.currentUser?.email;
    return Scaffold(
      key: const Key('fameverse-policy-safety-screen'),
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        centerTitle: true,
        title: const Text(
          'Privacy, safety & system',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 34),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF271334), Color(0xFF130D17)],
                ),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xFF4A3056)),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.shield_rounded,
                    color: Color(0xFFC47CFF),
                    size: 27,
                  ),
                  SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Your account. Your safety. Your Fameverse system.',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'Account security, Fame Algo, backend updates, community standards, creator economics and legal terms.',
                          style: TextStyle(
                            color: Color(0xFFB2A6B6),
                            fontSize: 12,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const _PolicySectionLabel('FAMEVERSE SYSTEM'),
            const SizedBox(height: 8),
            _PolicyGroup(
              children: [
                _PolicyRow(
                  key: const Key('settings-fame-algo-entry'),
                  icon: Icons.auto_awesome_rounded,
                  title: 'Fame Algo',
                  subtitle: 'See what powers For You and creator discovery',
                  onTap: () => _openSystem('algo'),
                ),
                _PolicyRow(
                  key: const Key('settings-backend-updater-entry'),
                  icon: Icons.system_update_alt_rounded,
                  title: 'App & backend updates',
                  subtitle: 'Revision, release label, status and Check now',
                  onTap: () => _openSystem('updates'),
                ),
              ],
            ),
            const SizedBox(height: 22),
            const _PolicySectionLabel('ACCOUNT SECURITY'),
            const SizedBox(height: 8),
            _PolicyGroup(
              children: [
                _PolicyRow(
                  key: const Key('settings-change-password'),
                  icon: Icons.password_rounded,
                  title: 'Change password',
                  subtitle:
                      'Update the password for ${email ?? 'this account'}',
                  onTap: _securityBusy ? null : _changePassword,
                ),
                _PolicyRow(
                  key: const Key('settings-signout-others'),
                  icon: Icons.devices_other_rounded,
                  title: 'Sign out other devices',
                  subtitle: 'Keep this device signed in and end other sessions',
                  onTap: _securityBusy ? null : _signOutOtherSessions,
                ),
              ],
            ),
            const SizedBox(height: 22),
            const _PolicySectionLabel('PRIVACY & SAFETY'),
            const SizedBox(height: 8),
            _PolicyGroup(
              children: [
                _PolicyRow(
                  icon: Icons.privacy_tip_outlined,
                  title: 'Privacy Notice',
                  subtitle: 'What Fameverse uses and why',
                  onTap: () => _openDocument('Privacy Notice', _privacy),
                ),
                _PolicyRow(
                  icon: Icons.groups_2_outlined,
                  title: 'Community Standards',
                  subtitle: 'What Fameverse will and will not tolerate',
                  onTap: () => _openDocument('Community Standards', _community),
                ),
              ],
            ),
            const SizedBox(height: 22),
            const _PolicySectionLabel('MONEY & CREATOR RULES'),
            const SizedBox(height: 8),
            _PolicyGroup(
              children: [
                _PolicyRow(
                  icon: Icons.live_tv_outlined,
                  title: 'Creator Beta Terms',
                  subtitle: '70/30 gifts, payouts and creator responsibilities',
                  onTap: () => _openDocument('Creator Beta Terms', _creator),
                ),
                _PolicyRow(
                  key: const Key('fame-coins-referral-rules'),
                  icon: Icons.toll_rounded,
                  title: 'Fame Coins & referrals',
                  subtitle: 'Purchased vs promotional coins and 100/50 rewards',
                  onTap: () =>
                      _openDocument('Fame Coins & Referral Rules', _coins),
                ),
              ],
            ),
            const SizedBox(height: 22),
            const _PolicySectionLabel('LEGAL'),
            const SizedBox(height: 8),
            _PolicyGroup(
              children: [
                _PolicyRow(
                  icon: Icons.description_outlined,
                  title: 'Terms of Use',
                  subtitle: 'Rules for using Fameverse',
                  onTap: () => _openDocument('Terms of Use', _terms),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PolicySectionLabel extends StatelessWidget {
  const _PolicySectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF8E8192),
          fontSize: 11,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.15,
        ),
      ),
    );
  }
}

class _PolicyGroup extends StatelessWidget {
  const _PolicyGroup({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF151417),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF2C242F)),
      ),
      child: Column(children: children),
    );
  }
}

class _PolicyRow extends StatelessWidget {
  const _PolicyRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(15, 14, 12, 14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF291833),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icon, color: const Color(0xFFC783FF), size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xFF8E858F),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFF8E858F)),
          ],
        ),
      ),
    );
  }
}

class _PolicyDocument extends StatelessWidget {
  const _PolicyDocument({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.black, title: Text(title)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 36),
          children: [
            Text(
              body,
              style: const TextStyle(
                color: Color(0xFFE4DCE7),
                fontSize: 14,
                height: 1.58,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

class FameversePolicyScreen extends StatelessWidget {
  const FameversePolicyScreen({super.key});

  static const _terms =
      '''Fameverse Beta Terms of Use\n\nFameverse is currently a beta service. Features may change while we test and improve the product. You must use Fameverse lawfully and may not abuse, disrupt, exploit, automate attacks against, or attempt to bypass safety and moderation systems.\n\nBeta test coins and beta gifts remain test-only unless Fameverse clearly identifies a real-money recharge as active. Real-money purchase terms will be presented before recharge is enabled for a user.\n\nYou remain responsible for content you create, stream, upload, or send. Fameverse may remove content or restrict accounts when needed to enforce these terms, protect users, or comply with law.''';

  static const _privacy =
      '''Fameverse Beta Privacy Notice\n\nFameverse uses account information, profile information, social connections, live-room activity, comments, gifts, FameTaps, moderation signals, verification status, payout status, and technical information needed to operate and secure the beta.\n\nProfile information you choose to publish can be visible to other Fameverse users. Live activity is shared with participants as required for the experience. Authentication and authoritative app data are handled through Fameverse backend services.\n\nIdentity and payment providers may require additional information when real-money verification, recharge, or payouts are enabled.''';

  static const _community =
      '''Fameverse Community Standards\n\nFameverse is for real people to create, watch, gift, and belong. Do not use Fameverse for credible threats, targeted harassment, hateful abuse, sexual exploitation, scams, impersonation intended to defraud, illegal content, spam, platform manipulation, or attempts to compromise another user's account or device.\n\nCreators are responsible for moderating their live spaces with the tools provided. Fameverse may remove content, end a live, restrict features, suspend accounts, or hold monetization when necessary to protect the community and enforce these standards.''';

  static const _creator =
      '''Fameverse Creator Beta Terms\n\nCreators are responsible for their live content, titles, goals, interactions, and moderation choices. Payout eligibility is separate from Fame Coins and requires cleared creator earnings, creator verification, account good standing, and Fameverse payout review. The minimum payout request is \$25.00.\n\nA balance shown as pending or under review is not yet available for payout. Fameverse may hold, reject, reverse, or investigate earnings or payouts where fraud, chargebacks, manipulation, policy violations, or verification problems are identified.\n\nThe creator revenue split and any coin-to-earnings conversion will not be activated until Fameverse publishes those economics.''';

  void _open(BuildContext context, String title, String body) {
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (context) => _PolicyDocument(title: title, body: body),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('fameverse-policy-safety-screen'),
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        centerTitle: true,
        title: const Text(
          'Safety & legal',
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
                          'Know the rules before you go live',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'Fameverse policy, privacy, community safety and creator beta terms live here.',
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
            const _PolicySectionLabel('FAMEVERSE POLICIES'),
            const SizedBox(height: 8),
            _PolicyGroup(
              children: [
                _PolicyRow(
                  icon: Icons.description_outlined,
                  title: 'Terms of Use',
                  subtitle: 'Rules for using Fameverse',
                  onTap: () => _open(context, 'Terms of Use', _terms),
                ),
                _PolicyRow(
                  icon: Icons.privacy_tip_outlined,
                  title: 'Privacy Notice',
                  subtitle: 'How beta information is used',
                  onTap: () => _open(context, 'Privacy Notice', _privacy),
                ),
                _PolicyRow(
                  icon: Icons.groups_2_outlined,
                  title: 'Community Standards',
                  subtitle: 'What Fameverse will and will not tolerate',
                  onTap: () =>
                      _open(context, 'Community Standards', _community),
                ),
                _PolicyRow(
                  icon: Icons.live_tv_outlined,
                  title: 'Creator Beta Terms',
                  subtitle: 'Live, monetization and payout responsibilities',
                  onTap: () =>
                      _open(context, 'Creator Beta Terms', _creator),
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
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

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
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(title),
      ),
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

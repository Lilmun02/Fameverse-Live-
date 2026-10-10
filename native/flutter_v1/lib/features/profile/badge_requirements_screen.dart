import 'package:flutter/material.dart';

import '../../data/fameverse_beta_backend.dart';
import '../live/native_live_profile_sheet.dart';

/// Requirements are informational; only Fameverse backend can award a badge.
class BadgeRequirementsScreen extends StatelessWidget {
  const BadgeRequirementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('badge-requirements-screen'),
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.black,
          title: const Text('How to get badges')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            const _BadgeInfo(
              title: 'First Verse · Beta legacy',
              description: 'Enroll in the Fameverse external beta and '
                  'complete all eight required missions to earn a permanent '
                  'First Verse badge. Optional checks do not block earning '
                  'it. Owner previews never automatically award the badge.',
            ),
            ...fvFirstVerseMissions.where((m) => m.required).map(
              (mission) => ListTile(
                dense: true,
                leading: const Icon(Icons.checklist_rounded),
                title: Text(mission.title),
                subtitle: Text(mission.detail),
              ),
            ),
            const SizedBox(height: 18),
            const _BadgeInfo(
              title: 'Gifter badges',
              description: 'Send eligible Fame Coin gifts to creators to '
                  'build your gifter level. Buying coins alone does not '
                  'award a gifter badge. Your earned tier is shown in Live.',
            ),
            ...fvNativeGifterBadgeTiers.map(
              (tier) => ListTile(
                dense: true,
                leading: Text(tier.icon,
                    style: const TextStyle(fontSize: 22)),
                title: Text(tier.label),
                subtitle: Text(
                  'Level ' +
                      tier.minLevel.toString() +
                      (tier.maxLevel > tier.minLevel
                          ? '–' + tier.maxLevel.toString()
                          : ''),
                ),
              ),
            ),
            const SizedBox(height: 18),
            const _BadgeInfo(
              title: 'Verified Creator',
              description: 'Reach at least 100 followers and receive '
                  '500,000 eligible cash-backed Fame Coins in gifts. '
                  'Submit for review once eligible. Promotional, referral, '
                  'self-gifts and owner QA gifts do not count.',
            ),
            const SizedBox(height: 12),
            const _BadgeInfo(
              title: 'Bring your badge · Coming soon',
              description: 'Planned for TikTok, Favorited and EPIC. '
                  'Submit one recording showing the source account and '
                  'earned badge. Fameverse must review the proof. '
                  'Transfers are not enabled yet; importing a badge '
                  'does not grant Fameverse gifter levels.',
            ),
          ],
        ),
      ),
    );
  }
}

class _BadgeInfo extends StatelessWidget {
  const _BadgeInfo({required this.title, required this.description});
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF21142B),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(
                fontSize: 17, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            Text(description, style: const TextStyle(
                color: Color(0xFFC5B7CD), height: 1.4)),
          ],
        ),
      ),
    );
  }
}

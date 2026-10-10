import 'package:flutter/material.dart';

import '../../data/fameverse_beta_backend.dart';
import '../live/native_live_profile_sheet.dart';

/// Requirements are informational; the backend awards badges.
class BadgeRequirementsScreen extends StatelessWidget {
  const BadgeRequirementsScreen({super.key});

  String _tierLabel(FvNativeGifterBadgeTier tier) {
    if (tier.minLevel == tier.maxLevel) {
      return 'Level ${tier.minLevel}';
    }
    return 'Levels ${tier.minLevel}–${tier.maxLevel}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('badge-requirements-screen'),
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('How to get badges'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            const _BadgeInfo(
              title: 'First Verse · Beta legacy',
              description: 'Enroll in the external Fameverse beta and complete all eight required missions to earn the permanent First Verse badge. Bonus missions are optional. Owner previews never award the badge.',
            ),
            ...fvFirstVerseMissions.where((mission) => mission.required).map(
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
              description: 'Send eligible Fame Coin gifts to creators to build your gifter level. Buying Fame Coins does not award a gifter badge. Your earned tier appears in Live.',
            ),
            ...fvNativeGifterBadgeTiers.map(
              (tier) => ListTile(
                dense: true,
                leading: Text(
                  tier.icon,
                  style: const TextStyle(fontSize: 22),
                ),
                title: Text(tier.label),
                subtitle: Text(_tierLabel(tier)),
              ),
            ),
            const SizedBox(height: 18),
            const _BadgeInfo(
              title: 'Verified Creator',
              description: 'Reach 100 followers and 500,000 eligible cash-backed Fame Coins received from gifts, then request manual approval. Promotional, referral, self-gifts and owner QA gifts do not count.',
            ),
            const SizedBox(height: 12),
            const _BadgeInfo(
              title: 'Bring your badge · Coming soon',
              description: 'Planned for TikTok, Favorited and EPIC. Submit a recording showing the source account and earned badge. Fameverse reviews proof; transfers are not active and will not grant automatic Fameverse levels.',
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
            Text(
              title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: const TextStyle(
                color: Color(0xFFC5B7CD),
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

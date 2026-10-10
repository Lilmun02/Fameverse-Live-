import 'package:flutter/material.dart';

import '../../data/fameverse_beta_backend.dart';
import '../live/native_live_profile_sheet.dart';

/// Read-only requirements screen. Never awards or transfers badges.
class BadgeRequirementsScreen extends StatelessWidget {
  const BadgeRequirementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('badge-requirements-screen'),
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('How to earn badges'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 34),
          children: [
            const _Requirement(
              title: 'First Verse',
              detail:
                  'Enrolled beta testers earn this permanent legacy badge '
                  'after completing all 8 required missions. The 2 bonus '
                  'checks are optional. Owner viewing is a preview only.',
            ),
            ...fvFirstVerseMissions
                .where((mission) => mission.required)
                .map(
                  (mission) => _Requirement(
                    title: mission.title,
                    detail: mission.detail,
                  ),
                ),
            const SizedBox(height: 16),
            const _Requirement(
              title: 'Gifter badges',
              detail:
                  'Send gifts to gain gifter levels. The first badge only '
                  'appears after you send a gift. Your level is computed '
                  'from total Fame Coins sent.',
            ),
            ...fvNativeGifterBadgeTiers.map(
              (tier) => _Requirement(
                title: '${tier.icon} ${tier.label}',
                detail: 'Level ${tier.minLevel}'
                    '${tier.maxLevel == tier.minLevel ? '' : '–${tier.maxLevel}'}'
                    ' · at least ${fvGifterMinimumCoinsSentForLevel(tier.minLevel)}'
                    ' coins sent in total'
                    '${tier.minLevel == 1 ? ' (send one gift first)' : ''}.',
              ),
            ),
            const SizedBox(height: 16),
            const _Requirement(
              title: 'Verified creator',
              detail:
                  'Reach 100 followers and 500,000 eligible cash-backed '
                  'Fame Coins received. Request verification in Creator Studio '
                  'and pass manual review. Promotional, referral, owner-QA '
                  'and self-gifts do not count.',
            ),
            const _Requirement(
              title: 'Bring your badge — coming soon',
              detail:
                  'Transfers from TikTok, Favorited and EPIC are not active '
                  'yet. Planned reviews require evidence of the earned badge '
                  'and matching username; external levels never transfer '
                  'automatically.',
            ),
          ],
        ),
      ),
    );
  }
}

class _Requirement extends StatelessWidget {
  const _Requirement({required this.title, required this.detail});
  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF17111B),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF45334D)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Text(
            detail,
            style: const TextStyle(
              fontSize: 12,
              height: 1.4,
              color: Color(0xFFB8ABBC),
            ),
          ),
        ],
      ),
    );
  }
}

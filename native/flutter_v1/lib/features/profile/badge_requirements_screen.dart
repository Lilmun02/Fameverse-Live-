import 'package:flutter/material.dart';

/// Read-only explanation. Actual badges are earned through the backend.
class BadgeRequirementsScreen extends StatelessWidget {
  const BadgeRequirementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('badge-requirements-screen'),
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('How to get badges'),
      ),
      body: const ListView(
        padding: EdgeInsets.all(18),
        children: [
          Text(
            'FIRST VERSE · BETA LEGACY',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          SizedBox(height: 8),
          Text('Enrolled external testers earn First Verse after all eight required missions. Once earned, the badge is permanent. Owner preview is clear but does not automatically award it.'),
          SizedBox(height: 12),
          Text('Required: 1. Build your profile. 2. Browse Home. 3. Explore Discover. 4. Open another profile. 5. Test following. 6. Join a Live. 7. Send a Live comment. 8. View a Story.'),
          SizedBox(height: 8),
          Text('Optional: send a permitted test gift or complete a co-host session. These do not block First Verse.'),
          SizedBox(height: 24),
          Text(
            'GIFTER BADGES',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          SizedBox(height: 8),
          Text('Send eligible Fame Coin gifts to creators to increase your gifter level. Purchasing coins alone does not award a gifter badge.'),
          SizedBox(height: 12),
          Text('Spark: levels 1–4. Bronze: 5–9. Silver: 10–19. Gold: 20–29. Platinum: 30–49. Diamond: 50–69. Royal: 70–84. Legendary: 85–98. Fame Icon: 99.'),
          SizedBox(height: 24),
          Text(
            'VERIFIED CREATOR',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          SizedBox(height: 8),
          Text('Reach 100 followers and receive 500,000 eligible cash-backed Fame Coins in gifts. Request manual review. Promotional, referral, owner QA and self-gifts do not count.'),
          SizedBox(height: 24),
          Text(
            'BRING YOUR BADGE · COMING SOON',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          SizedBox(height: 8),
          Text('Future transfers from TikTok, Favorited and EPIC will require a source-profile and earned-badge screen recording. Transfers are not active and will not grant automatic Fameverse levels.'),
        ],
      ),
    );
  }
}

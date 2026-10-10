import 'package:flutter/material.dart';

/// Explains published badge requirements without issuing or modifying badges.
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
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          ListTile(
            title: Text('First Verse · Beta legacy'),
            subtitle: Text('Enroll as an external Fameverse beta tester and complete all eight required missions. The badge remains permanent once earned. Owner preview does not award it.'),
          ),
          ListTile(
            title: Text('First Verse · Required missions'),
            subtitle: Text('1. Build your profile. 2. Browse Home. 3. Explore Discover. 4. Open another profile. 5. Test following. 6. Join a Live. 7. Send a Live comment. 8. View a Story.'),
          ),
          ListTile(
            title: Text('First Verse · Bonus checks'),
            subtitle: Text('Sending a permitted test gift and completing a co-host session are optional. They do not block the badge.'),
          ),
          Divider(),
          ListTile(
            title: Text('Gifter badge requirements'),
            subtitle: Text('Send eligible gifts to creators to increase your gifter level and unlock the corresponding gifter tier. Buying coins alone does not increase your gifter level.'),
          ),
          ListTile(
            title: Text('Spark Gifter · Levels 1–4'),
          ),
          ListTile(
            title: Text('Bronze Gifter · Levels 5–9'),
          ),
          ListTile(
            title: Text('Silver Gifter · Levels 10–19'),
          ),
          ListTile(
            title: Text('Gold Gifter · Levels 20–29'),
          ),
          ListTile(
            title: Text('Platinum Gifter · Levels 30–49'),
          ),
          ListTile(
            title: Text('Diamond Gifter · Levels 50–69'),
          ),
          ListTile(
            title: Text('Royal Gifter · Levels 70–84'),
          ),
          ListTile(
            title: Text('Legendary Gifter · Levels 85–98'),
          ),
          ListTile(
            title: Text('Fame Icon · Level 99'),
          ),
          Divider(),
          ListTile(
            title: Text('Verified Creator'),
            subtitle: Text('Reach 100 followers and receive 500,000 eligible cash-backed Fame Coins in gifts. Then request manual review. Promotional, referral, owner QA and self-gifts do not count.'),
          ),
          ListTile(
            title: Text('Bring your badge · Coming soon'),
            subtitle: Text('Future badge transfer review from TikTok, Favorited or EPIC requires a recording showing your source account and earned badge. Imports are not available yet.'),
          ),
        ],
      ),
    );
  }
}

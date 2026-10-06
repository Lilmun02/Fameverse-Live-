import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/fameverse_backend.dart';
import '../../data/fameverse_beta_backend.dart';
import '../badges/gifter_profile_section.dart';
import 'fame_coin_store_screen.dart';
part 'native_profile_build23_identity.part.dart';
part 'native_profile_build23_settings.part.dart';


class NativeProfileBuild23Screen extends StatelessWidget {
  const NativeProfileBuild23Screen({
    required this.profile,
    required this.identity,
    required this.network,
    required this.isOwner,
    required this.betaStatus,
    required this.avatarBusy,
    required this.onChangePhoto,
    required this.onEdit,
    required this.onCreatorStudio,
    required this.onFirstVerse,
    required this.onPolicies,
    required this.onSignOut,
    super.key,
  });

  final FvProfile profile;
  final FvIdentity identity;
  final FvFollowNetwork network;
  final bool isOwner;
  final FvBetaProgramStatus betaStatus;
  final bool avatarBusy;
  final VoidCallback onChangePhoto;
  final VoidCallback onEdit;
  final VoidCallback onCreatorStudio;
  final VoidCallback? onFirstVerse;
  final VoidCallback onPolicies;
  final Future<void> Function() onSignOut;

  int get _friends =>
      network.followingIds.intersection(network.followerIds).length;

  String get _publicBio {
    final value = profile.bio.trim();
    final normalized = value.toLowerCase();
    if (normalized == 'admin - owner' || normalized == 'admin-owner') return '';
    return value;
  }

  void _openSettings(BuildContext context) {
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (context) => _Build23SettingsScreen(
          profile: profile,
          isOwner: isOwner,
          betaStatus: betaStatus,
          avatarBusy: avatarBusy,
          onChangePhoto: onChangePhoto,
          onEdit: onEdit,
          onCreatorStudio: onCreatorStudio,
          onFirstVerse: onFirstVerse,
          onPolicies: onPolicies,
          onSignOut: onSignOut,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        key: const Key('build23-profile-screen'),
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 116),
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'FAMEVERSE',
                      style: TextStyle(
                        color: Color(0xFFC982FF),
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Profile',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                key: const Key('profile-settings-button'),
                onPressed: () => _openSettings(context),
                icon: const Icon(Icons.settings_rounded),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _PremiumHero(
            profile: profile,
            isOwner: isOwner,
            avatarBusy: avatarBusy,
            onChangePhoto: onChangePhoto,
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  profile.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 29,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              _Build23VerificationBadge(userId: profile.id, isOwner: isOwner),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            profile.handle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFFA69AA9),
              fontWeight: FontWeight.w700,
            ),
          ),
          if (isOwner) ...[
            const SizedBox(height: 8),
            const Text(
              'FAMEVERSE OWNER • PREMIUM',
              key: Key('owner-premium-profile-label'),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFFFFD695),
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.3,
              ),
            ),
          ],
          const SizedBox(height: 13),
          Text(
            _publicBio.isEmpty
                ? 'Add a bio and tell Fameverse who you are.'
                : _publicBio,
            textAlign: TextAlign.center,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: _publicBio.isEmpty
                  ? const Color(0xFF7A707E)
                  : const Color(0xFFE8DFEA),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 22),
          _Stats(
            followers: network.followers.length,
            following: network.following.length,
            friends: _friends,
          ),
          const SizedBox(height: 14),
          _WalletCard(userId: identity.id),
          const SizedBox(height: 16),
          FvGifterProfileSection(userId: profile.id),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  key: const Key('edit-profile-button'),
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_rounded, size: 18),
                  label: const Text('Edit profile'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                  ),
                ),
              ),
              const SizedBox(width: 9),
              IconButton.filledTonal(
                onPressed: onCreatorStudio,
                tooltip: 'Creator Studio',
                icon: const Icon(Icons.workspace_premium_rounded),
              ),
            ],
          ),
          const SizedBox(height: 24),
          InkWell(
            key: const Key('open-creator-studio'),
            onTap: onCreatorStudio,
            borderRadius: BorderRadius.circular(20),
            child: Ink(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF54366B)),
                gradient: const LinearGradient(
                  colors: [Color(0xFF2B1738), Color(0xFF130E17)],
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.workspace_premium_rounded,
                    color: Color(0xFFD49CFF),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isOwner ? 'Owner Studio' : 'Creator Studio',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          isOwner
                              ? 'Premium tools, earnings and payout controls'
                              : 'Earnings, payouts and creator tools',
                          style: const TextStyle(
                            color: Color(0xFFAA9DAE),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/fameverse_backend.dart';
part 'native_profile_identity.part.dart';
part 'native_profile_actions.part.dart';
part 'native_profile_wallet.part.dart';
part 'native_profile_settings.part.dart';


/// Public Fameverse identity surface.
///
/// Internal roles, QA controls, payment controls, account email, backend/build
/// diagnostics, and moderation tooling never belong on this screen.
class NativeProfileScreen extends StatelessWidget {
  const NativeProfileScreen({
    required this.profile,
    required this.identity,
    required this.network,
    required this.avatarBusy,
    required this.onChangePhoto,
    required this.onSettings,
    required this.onEdit,
    required this.onCreatorStudio,
    required this.onSignOut,
    super.key,
  });

  final FvProfile profile;
  final FvIdentity identity;
  final FvFollowNetwork network;
  final bool avatarBusy;
  final VoidCallback onChangePhoto;
  final VoidCallback onSettings;
  final VoidCallback onEdit;
  final VoidCallback onCreatorStudio;
  final Future<void> Function() onSignOut;

  int get _friendCount =>
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
        builder: (context) => _FameverseSettingsScreen(
          profile: profile,
          avatarBusy: avatarBusy,
          onChangePhoto: onChangePhoto,
          onEditProfile: onEdit,
          onCreatorStudio: onCreatorStudio,
          onLegalAndSafety: onSettings,
          onSignOut: onSignOut,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async {},
        child: CustomScrollView(
          key: const Key('native-profile-screen'),
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 116),
              sliver: SliverList.list(
                children: [
                  _ProfileTopBar(onSettings: () => _openSettings(context)),
                  const SizedBox(height: 18),
                  _ProfileHero(
                    profile: profile,
                    avatarBusy: avatarBusy,
                    onChangePhoto: onChangePhoto,
                  ),
                  const SizedBox(height: 16),
                  _ProfileIdentity(profile: profile, publicBio: _publicBio),
                  const SizedBox(height: 22),
                  _ConnectionStats(
                    followers: network.followers.length,
                    following: network.following.length,
                    friends: _friendCount,
                  ),
                  const SizedBox(height: 14),
                  _FameCoinWalletCard(userId: identity.id),
                  const SizedBox(height: 18),
                  _ProfileActions(
                    onEdit: onEdit,
                    onCreatorStudio: onCreatorStudio,
                    onSettings: () => _openSettings(context),
                  ),
                  const SizedBox(height: 30),
                  const _SectionLabel('CREATOR SPACE'),
                  const SizedBox(height: 9),
                  _CreatorStudioRow(onTap: onCreatorStudio),
                  const SizedBox(height: 24),
                  const _ProfileFooterNote(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

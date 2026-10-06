part of 'fameverse_shell_build23.dart';

class _Build23ShellView extends StatelessWidget {
  const _Build23ShellView({
    required this.tab,
    required this.profile,
    required this.identity,
    required this.backend,
    required this.liveBackend,
    required this.network,
    required this.creators,
    required this.rooms,
    required this.stories,
    required this.loading,
    required this.error,
    required this.isOwner,
    required this.betaStatus,
    required this.avatarBusy,
    required this.followBusy,
    required this.onRefresh,
    required this.onSetTab,
    required this.onOpenStories,
    required this.onRoomSelected,
    required this.onToggleFollow,
    required this.onCreatorSelected,
    required this.onChangePhoto,
    required this.onEdit,
    required this.onCreatorStudio,
    required this.onFirstVerse,
    required this.onPolicies,
    required this.onSignOut,
  });

  final int tab;
  final FvProfile profile;
  final FvIdentity identity;
  final FameverseBackend backend;
  final FameverseLiveBackend liveBackend;
  final FvFollowNetwork network;
  final List<FvCreator> creators;
  final List<FvLiveRoom> rooms;
  final List<FvCreatorStory> stories;
  final bool loading;
  final String? error;
  final bool isOwner;
  final FvBetaProgramStatus betaStatus;
  final bool avatarBusy;
  final bool followBusy;
  final Future<void> Function() onRefresh;
  final ValueChanged<int> onSetTab;
  final VoidCallback onOpenStories;
  final Future<void> Function(FvLiveRoom) onRoomSelected;
  final Future<void> Function(String) onToggleFollow;
  final Future<void> Function(FvProfile) onCreatorSelected;
  final VoidCallback onChangePhoto;
  final VoidCallback onEdit;
  final VoidCallback onCreatorStudio;
  final Future<void> Function()? onFirstVerse;
  final VoidCallback onPolicies;
  final Future<void> Function() onSignOut;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: tab,
        children: [
          FameverseHomeBuild23Screen(
            profile: profile,
            network: network,
            creators: creators,
            rooms: rooms,
            stories: stories,
            loading: loading,
            error: error,
            onRefresh: onRefresh,
            onOpenProfile: () => onSetTab(3),
            onOpenDiscover: () => onSetTab(1),
            onOpenStories: onOpenStories,
            onRoomSelected: onRoomSelected,
            onToggleFollow: onToggleFollow,
            onCreatorSelected: onCreatorSelected,
            followBusy: followBusy,
          ),
          FameverseDiscoverScreen(
            profile: profile,
            network: network,
            creators: creators,
            rooms: rooms,
            loading: loading,
            onRefresh: onRefresh,
            onToggleFollow: onToggleFollow,
            onCreatorSelected: onCreatorSelected,
            followBusy: followBusy,
            onOpenProfile: () => onSetTab(3),
            onRoomSelected: onRoomSelected,
          ),
          NativeCameraScreen(
            liveBackend: liveBackend,
            identity: identity,
            profile: profile,
            onLiveEnded: onRefresh,
          ),
          NativeProfileBuild23Screen(
            profile: profile,
            identity: identity,
            network: network,
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
        ],
      ),
      bottomNavigationBar: NavigationBar(
        key: const Key('fameverse-bottom-nav'),
        selectedIndex: tab,
        onDestinationSelected: onSetTab,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore_rounded),
            label: 'Discover',
          ),
          NavigationDestination(
            icon: Icon(Icons.videocam_outlined),
            selectedIcon: Icon(Icons.videocam_rounded),
            label: 'Live',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

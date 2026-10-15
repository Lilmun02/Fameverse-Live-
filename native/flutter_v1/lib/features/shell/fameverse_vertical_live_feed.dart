import 'package:flutter/material.dart';

import '../../data/fameverse_backend.dart';
import '../../data/fameverse_live_backend.dart';
import '../live/stream_viewer_live_screen.dart';

/// Home Live Feed: one actual full-screen Stream Video room at a time.
///
/// Discover keeps the separate, two-column live-room card browser. This
/// screen deliberately does not substitute creator avatars for video.
class FameverseVerticalLiveFeed extends StatefulWidget {
  const FameverseVerticalLiveFeed({
    required this.backend,
    required this.liveBackend,
    required this.identity,
    required this.profile,
    required this.rooms,
    required this.followingIds,
    required this.onOpenDiscover,
    required this.onOpenStories,
    required this.onRefresh,
    super.key,
  });

  final FameverseBackend backend;
  final FameverseLiveBackend liveBackend;
  final FvIdentity identity;
  final FvProfile profile;
  final List<FvLiveRoom> rooms;
  final Set<String> followingIds;
  final VoidCallback onOpenDiscover;
  final VoidCallback onOpenStories;
  final Future<void> Function() onRefresh;

  @override
  State<FameverseVerticalLiveFeed> createState() =>
      _FameverseVerticalLiveFeedState();
}

enum _LiveFeedLane { forYou, following, rising }

class _FameverseVerticalLiveFeedState extends State<FameverseVerticalLiveFeed> {
  final PageController _pages = PageController();
  _LiveFeedLane _lane = _LiveFeedLane.forYou;
  int _activeIndex = 0;
  String? _activeRoomId;

  List<FvLiveRoom> get _rooms {
    final rooms = widget.rooms.toList();
    if (_lane == _LiveFeedLane.following) {
      rooms.removeWhere(
        (room) => !widget.followingIds.contains(room.hostUserId),
      );
    }
    rooms.sort((left, right) {
      final leftBoost =
          _lane == _LiveFeedLane.forYou &&
              widget.followingIds.contains(left.hostUserId)
          ? 80
          : 0;
      final rightBoost =
          _lane == _LiveFeedLane.forYou &&
              widget.followingIds.contains(right.hostUserId)
          ? 80
          : 0;
      return (right.fameTaps + rightBoost).compareTo(left.fameTaps + leftBoost);
    });
    return rooms;
  }

  @override
  void didUpdateWidget(covariant FameverseVerticalLiveFeed oldWidget) {
    super.didUpdateWidget(oldWidget);
    final rooms = _rooms;
    if (rooms.isEmpty) {
      _activeRoomId = null;
      _activeIndex = 0;
      return;
    }
    final selected = rooms.indexWhere((room) => room.id == _activeRoomId);
    final next = selected >= 0
        ? selected
        : _activeIndex.clamp(0, rooms.length - 1);
    if (next != _activeIndex) {
      _activeIndex = next;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _pages.hasClients) _pages.jumpToPage(_activeIndex);
      });
    }
    _activeRoomId = rooms[_activeIndex].id;
  }

  void _selectLane(_LiveFeedLane lane) {
    if (lane == _lane) return;
    setState(() {
      _lane = lane;
      _activeIndex = 0;
      final nextRooms = _rooms;
      _activeRoomId = nextRooms.isEmpty ? null : nextRooms.first.id;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _pages.hasClients) _pages.jumpToPage(0);
    });
  }

  void _onPageChanged(int index) {
    final rooms = _rooms;
    if (index < 0 || index >= rooms.length) return;
    setState(() {
      _activeIndex = index;
      _activeRoomId = rooms[index].id;
    });
  }

  void _onLeave() {
    if (!mounted) return;
    // The viewer handles its own Stream call leave and transport cleanup.
    // Returning to Discover prevents an ended feed session looping.
    widget.onOpenDiscover();
  }

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rooms = _rooms;
    if (rooms.isEmpty) {
      return ColoredBox(
        color: const Color(0xFF0D0912),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(30),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.live_tv_outlined,
                    size: 48,
                    color: Color(0xFFC18BEB),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    _lane == _LiveFeedLane.following
                        ? 'Nobody you follow is live'
                        : 'No creators are live yet',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Swipe down to refresh, or explore Fameverse creators.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: widget.onOpenDiscover,
                    icon: const Icon(Icons.explore_rounded),
                    label: const Text('Discover'),
                  ),
                  TextButton(
                    onPressed: () => _selectLane(_LiveFeedLane.forYou),
                    child: const Text('For You'),
                  ),
                  TextButton.icon(
                    onPressed: widget.onRefresh,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Refresh Live Feed'),
                  ),
                  TextButton(
                    onPressed: widget.onOpenStories,
                    child: const Text('Stories'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    if (_activeIndex >= rooms.length) _activeIndex = rooms.length - 1;
    _activeRoomId ??= rooms[_activeIndex].id;
    return Stack(
      key: const Key('home-fullscreen-live-feed'),
      fit: StackFit.expand,
      children: [
        PageView.builder(
          key: const Key('home-live-vertical-swiper'),
          controller: _pages,
          scrollDirection: Axis.vertical,
          itemCount: rooms.length,
          onPageChanged: _onPageChanged,
          itemBuilder: (context, index) {
            final room = rooms[index];
            // Adjacent pages must NOT join Stream simultaneously. Stream
            // Video uses a shared client that disconnects on route disposal.
            if (index != _activeIndex) {
              return ColoredBox(
                color: const Color(0xFF120D19),
                child: Center(
                  child: Text(
                    room.hostDisplayName,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              );
            }
            return NativeViewerLiveScreen(
              key: ValueKey('active-live-${room.id}'),
              backend: widget.backend,
              liveBackend: widget.liveBackend,
              identity: widget.identity,
              viewerProfile: widget.profile,
              room: room,
              onExitFeed: _onLeave,
            );
          },
        ),
        Positioned(
          top: MediaQuery.paddingOf(context).top + 74,
          right: 10,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              PopupMenuButton<_LiveFeedLane>(
                key: const Key('live-feed-lane-picker'),
                tooltip: 'Choose Live Feed',
                initialValue: _lane,
                onSelected: _selectLane,
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: _LiveFeedLane.forYou,
                    child: Text('For You'),
                  ),
                  PopupMenuItem(
                    value: _LiveFeedLane.following,
                    child: Text('Following'),
                  ),
                  PopupMenuItem(
                    value: _LiveFeedLane.rising,
                    child: Text('Rising'),
                  ),
                ],
                child: _FeedActionChip(
                  icon: Icons.swap_vert_rounded,
                  label: _lane == _LiveFeedLane.forYou
                      ? 'For You'
                      : _lane == _LiveFeedLane.following
                      ? 'Following'
                      : 'Rising',
                ),
              ),
              const SizedBox(height: 8),
              Semantics(
                button: true,
                label: 'Discover creators',
                child: GestureDetector(
                  onTap: widget.onOpenDiscover,
                  child: const _FeedActionChip(
                    icon: Icons.explore_rounded,
                    label: 'Discover',
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Semantics(
                button: true,
                label: 'Open Stories',
                child: GestureDetector(
                  onTap: widget.onOpenStories,
                  child: const _FeedActionChip(
                    icon: Icons.auto_stories_rounded,
                    label: 'Stories',
                  ),
                ),
              ),
            ],
          ),
        ),
        if (rooms.length > 1)
          const Positioned(
            top: 0,
            right: 0,
            left: 0,
            child: IgnorePointer(
              child: SafeArea(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Padding(
                    padding: EdgeInsets.only(top: 74),
                    child: Text(
                      'SWIPE FOR NEXT LIVE',
                      style: TextStyle(
                        color: Color(0xFFD8CEE0),
                        fontSize: 9,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _FeedActionChip extends StatelessWidget {
  const _FeedActionChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    decoration: BoxDecoration(
      color: const Color(0xCB130D1B),
      border: Border.all(color: const Color(0xFF68437D)),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: const Color(0xFFE4C4FF), size: 15),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    ),
  );
}

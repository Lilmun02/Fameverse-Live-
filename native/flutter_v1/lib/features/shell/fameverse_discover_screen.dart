import 'package:flutter/material.dart';

import '../../data/fameverse_backend.dart';
import '../live/native_live_rankings.dart';
part 'fameverse_discover_featured.part.dart';
part 'fameverse_discover_results.part.dart';


/// Discover is the intentional exploration surface.
///
/// Home decides what to surface algorithmically. Discover lets the user search,
/// filter, and browse live rooms and creators on purpose.
class FameverseDiscoverScreen extends StatefulWidget {
  const FameverseDiscoverScreen({
    required this.profile,
    required this.network,
    required this.creators,
    required this.rooms,
    required this.loading,
    required this.onRefresh,
    required this.onToggleFollow,
    required this.onCreatorSelected,
    required this.followBusy,
    required this.onOpenProfile,
    required this.onRoomSelected,
    super.key,
  });

  final FvProfile profile;
  final FvFollowNetwork network;
  final List<FvCreator> creators;
  final List<FvLiveRoom> rooms;
  final bool loading;
  final Future<void> Function() onRefresh;
  final ValueChanged<String> onToggleFollow;
  final ValueChanged<FvProfile> onCreatorSelected;
  final bool followBusy;
  final VoidCallback onOpenProfile;
  final ValueChanged<FvLiveRoom> onRoomSelected;

  @override
  State<FameverseDiscoverScreen> createState() =>
      _FameverseDiscoverScreenState();
}

enum _DiscoverFilter { all, live, creators, rising, following }

class _FameverseDiscoverScreenState extends State<FameverseDiscoverScreen> {
  final TextEditingController _search = TextEditingController();
  String _query = '';
  _DiscoverFilter _filter = _DiscoverFilter.all;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  bool _matches(Iterable<String?> values) {
    final needle = _query.trim().toLowerCase();
    if (needle.isEmpty) return true;
    return values.whereType<String>().join(' ').toLowerCase().contains(needle);
  }

  int _followerCount(String userId) {
    for (final creator in widget.creators) {
      if (creator.profile.id == userId) return creator.followerCount;
    }
    return 0;
  }

  bool _following(String userId) =>
      widget.network.followingIds.contains(userId);

  List<FvLiveRoom> get _rooms {
    final rooms = widget.rooms.where((room) {
      if (!_matches([room.title, room.host.displayName, room.host.username])) {
        return false;
      }
      if (_filter == _DiscoverFilter.following &&
          !_following(room.hostUserId)) {
        return false;
      }
      if (_filter == _DiscoverFilter.creators) return false;
      return true;
    }).toList();

    if (_filter == _DiscoverFilter.rising) {
      rooms.sort((a, b) {
        final aScore =
            a.fameTaps + (_followerCount(a.hostUserId) < 2500 ? 60 : 0);
        final bScore =
            b.fameTaps + (_followerCount(b.hostUserId) < 2500 ? 60 : 0);
        return bScore.compareTo(aScore);
      });
    } else {
      rooms.sort((a, b) => b.fameTaps.compareTo(a.fameTaps));
    }
    return rooms;
  }

  List<FvCreator> get _creators {
    final creators = widget.creators.where((creator) {
      if (!_matches([
        creator.profile.displayName,
        creator.profile.username,
        creator.profile.bio,
      ])) {
        return false;
      }
      if (_filter == _DiscoverFilter.live) return false;
      if (_filter == _DiscoverFilter.following &&
          !_following(creator.profile.id)) {
        return false;
      }
      return true;
    }).toList();

    if (_filter == _DiscoverFilter.rising) {
      creators.sort((a, b) => a.followerCount.compareTo(b.followerCount));
    } else {
      creators.sort((a, b) => b.followerCount.compareTo(a.followerCount));
    }
    return creators;
  }

  @override
  Widget build(BuildContext context) {
    final rooms = _rooms;
    final creators = _creators;
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: widget.onRefresh,
        child: ListView(
          key: const Key('fameverse-intentional-discover'),
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 116),
          children: [
            _DiscoverTopBar(
              profile: widget.profile,
              onOpenProfile: widget.onOpenProfile,
            ),
            const SizedBox(height: 20),
            TextField(
              key: const Key('discover-search'),
              controller: _search,
              onChanged: (value) => setState(() => _query = value),
              decoration: InputDecoration(
                hintText: 'Search creators, handles or live titles',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          _search.clear();
                          setState(() => _query = '');
                        },
                        icon: const Icon(Icons.close_rounded),
                      ),
                filled: true,
                fillColor: const Color(0xFF17121B),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: const BorderSide(color: Color(0xFF33263B)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: const BorderSide(color: Color(0xFF33263B)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: const BorderSide(
                    color: Color(0xFF9A55E8),
                    width: 1.4,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 38,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _FilterChip(
                    label: 'All',
                    selected: _filter == _DiscoverFilter.all,
                    onTap: () => setState(() => _filter = _DiscoverFilter.all),
                  ),
                  _FilterChip(
                    label: 'Live',
                    selected: _filter == _DiscoverFilter.live,
                    onTap: () => setState(() => _filter = _DiscoverFilter.live),
                  ),
                  _FilterChip(
                    label: 'Creators',
                    selected: _filter == _DiscoverFilter.creators,
                    onTap: () =>
                        setState(() => _filter = _DiscoverFilter.creators),
                  ),
                  _FilterChip(
                    label: 'Rising',
                    selected: _filter == _DiscoverFilter.rising,
                    onTap: () =>
                        setState(() => _filter = _DiscoverFilter.rising),
                  ),
                  _FilterChip(
                    label: 'Following',
                    selected: _filter == _DiscoverFilter.following,
                    onTap: () =>
                        setState(() => _filter = _DiscoverFilter.following),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const _DiscoverFameboardCard(),
            const SizedBox(height: 28),
            if (widget.loading &&
                widget.rooms.isEmpty &&
                widget.creators.isEmpty)
              const _DiscoverLoadingCard()
            else ...[
              if (_filter != _DiscoverFilter.creators) ...[
                _DiscoverSectionHeader(
                  eyebrow: _filter == _DiscoverFilter.rising
                      ? 'RISING LIVE'
                      : 'LIVE NOW',
                  title: _query.isEmpty ? 'Streams to explore' : 'Live matches',
                  count: rooms.length,
                ),
                const SizedBox(height: 12),
                if (rooms.isEmpty)
                  _DiscoverEmptyCard(
                    icon: Icons.live_tv_outlined,
                    title: _query.isEmpty
                        ? 'No matching live rooms'
                        : 'No live results for “$_query”',
                    body: 'Try another filter or search for a creator instead.',
                  )
                else
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: rooms.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: .78,
                        ),
                    itemBuilder: (context, index) {
                      final room = rooms[index];
                      return _DiscoverLiveCard(
                        room: room,
                        onTap: () => widget.onRoomSelected(room),
                      );
                    },
                  ),
                const SizedBox(height: 30),
              ],
              if (_filter != _DiscoverFilter.live) ...[
                _DiscoverSectionHeader(
                  eyebrow: _filter == _DiscoverFilter.rising
                      ? 'RISING CREATORS'
                      : 'PEOPLE',
                  title: _query.isEmpty
                      ? 'Creators to discover'
                      : 'Creator matches',
                  count: creators.length,
                ),
                const SizedBox(height: 12),
                if (creators.isEmpty)
                  _DiscoverEmptyCard(
                    icon: Icons.people_outline_rounded,
                    title: _query.isEmpty
                        ? 'No creators in this filter yet'
                        : 'No creators found for “$_query”',
                    body: 'Try another search or switch back to All.',
                  )
                else
                  ...creators.map((creator) {
                    final following = _following(creator.profile.id);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _CreatorResultCard(
                        creator: creator,
                        following: following,
                        busy: widget.followBusy,
                        onFollow: () =>
                            widget.onToggleFollow(creator.profile.id),
                        onOpen: () => widget.onCreatorSelected(creator.profile),
                      ),
                    );
                  }),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../data/fameverse_backend.dart';

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

class _DiscoverTopBar extends StatelessWidget {
  const _DiscoverTopBar({required this.profile, required this.onOpenProfile});

  final FvProfile profile;
  final VoidCallback onOpenProfile;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'FAMEVERSE',
                style: TextStyle(
                  color: Color(0xFFC985FF),
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Discover',
                key: Key('discover-title'),
                style: TextStyle(
                  fontSize: 29,
                  height: 1,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -.5,
                ),
              ),
              SizedBox(height: 5),
              Text(
                'Search on purpose. Find somebody new.',
                style: TextStyle(color: Color(0xFF9F93A4), fontSize: 12),
              ),
            ],
          ),
        ),
        InkWell(
          onTap: onOpenProfile,
          customBorder: const CircleBorder(),
          child: _DiscoverAvatar(profile: profile, radius: 22),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF6B31B5) : const Color(0xFF17121B),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected
                  ? const Color(0xFFB56CFF)
                  : const Color(0xFF33263B),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _DiscoverSectionHeader extends StatelessWidget {
  const _DiscoverSectionHeader({
    required this.eyebrow,
    required this.title,
    required this.count,
  });

  final String eyebrow;
  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                eyebrow,
                style: const TextStyle(
                  color: Color(0xFFBB78F2),
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.35,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
        Text(
          '$count',
          style: const TextStyle(
            color: Color(0xFF8F8493),
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _DiscoverLiveCard extends StatelessWidget {
  const _DiscoverLiveCard({required this.room, required this.onTap});

  final FvLiveRoom room;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final avatar = room.host.avatarUrl?.trim();
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF3B2845)),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF311541), Color(0xFF110C15)],
            ),
            image: avatar == null || avatar.isEmpty
                ? null
                : DecorationImage(
                    image: NetworkImage(avatar),
                    fit: BoxFit.cover,
                    opacity: .24,
                  ),
          ),
          child: Stack(
            children: [
              const Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(20)),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0x22000000), Color(0xEA000000)],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 10,
                top: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE72C57),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: const Text(
                    'LIVE',
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900),
                  ),
                ),
              ),
              Positioned(
                right: 10,
                top: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xB70B0710),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'F ${_discoverCompact(room.fameTaps)}',
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 11,
                right: 11,
                bottom: 11,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _DiscoverAvatar(profile: room.host, radius: 20),
                    const SizedBox(height: 8),
                    Text(
                      room.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      room.host.handle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFFB2A4B8),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CreatorResultCard extends StatelessWidget {
  const _CreatorResultCard({
    required this.creator,
    required this.following,
    required this.busy,
    required this.onFollow,
  });

  final FvCreator creator;
  final bool following;
  final bool busy;
  final VoidCallback onFollow;

  @override
  Widget build(BuildContext context) {
    final bio = creator.profile.bio.trim();
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFF151018),
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: const Color(0xFF33243C)),
      ),
      child: Row(
        children: [
          _DiscoverAvatar(profile: creator.profile, radius: 27),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        creator.profile.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 5),
                    const Icon(
                      Icons.auto_awesome_rounded,
                      size: 13,
                      color: Color(0xFFA95BFF),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${creator.profile.handle} · ${_discoverCompact(creator.followerCount)} followers',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFA79BAA),
                    fontSize: 11,
                  ),
                ),
                if (bio.isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Text(
                    bio,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFFD8CDD9),
                      fontSize: 11,
                      height: 1.3,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          FilledButton.tonal(
            onPressed: busy ? null : onFollow,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            ),
            child: Text(following ? 'Following' : 'Follow'),
          ),
        ],
      ),
    );
  }
}

class _DiscoverLoadingCard extends StatelessWidget {
  const _DiscoverLoadingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: const Color(0xFF151018),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF33243C)),
      ),
      child: const Center(child: CircularProgressIndicator()),
    );
  }
}

class _DiscoverEmptyCard extends StatelessWidget {
  const _DiscoverEmptyCard({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF151018),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF33243C)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFF2A1834),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: const Color(0xFFC686FF)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: const TextStyle(
                    color: Color(0xFFA79BAA),
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DiscoverAvatar extends StatelessWidget {
  const _DiscoverAvatar({required this.profile, required this.radius});

  final FvProfile profile;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final avatar = profile.avatarUrl?.trim();
    return CircleAvatar(
      radius: radius,
      backgroundColor: const Color(0xFF3A2148),
      foregroundImage: avatar == null || avatar.isEmpty
          ? null
          : NetworkImage(avatar),
      child: Text(
        profile.initial,
        style: const TextStyle(fontWeight: FontWeight.w900),
      ),
    );
  }
}

String _discoverCompact(int value) {
  if (value >= 1000000) {
    final text = (value / 1000000).toStringAsFixed(value >= 10000000 ? 0 : 1);
    return '${text.replaceAll('.0', '')}M';
  }
  if (value >= 1000) {
    final text = (value / 1000).toStringAsFixed(value >= 10000 ? 0 : 1);
    return '${text.replaceAll('.0', '')}K';
  }
  return '$value';
}

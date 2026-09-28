import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/fameverse_backend.dart';

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

enum _DiscoverView { explore, rankings }

enum _DiscoverFilter { all, live, creators, rising, following }

enum _RankingKind { tappers, gifters, creators }

class _RankingEntry {
  const _RankingEntry({
    required this.rank,
    required this.profile,
    required this.score,
    required this.secondary,
  });

  final int rank;
  final FvProfile profile;
  final int score;
  final int secondary;
}

class _FameverseDiscoverScreenState extends State<FameverseDiscoverScreen> {
  final TextEditingController _search = TextEditingController();

  _DiscoverView _view = _DiscoverView.explore;
  _DiscoverFilter _filter = _DiscoverFilter.all;
  _RankingKind _rankingKind = _RankingKind.tappers;
  String _query = '';
  bool _rankingLoading = false;
  String? _rankingError;
  List<_RankingEntry> _ranking = const [];

  @override
  void initState() {
    super.initState();
    _loadRanking();
  }

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

  bool _following(String userId) =>
      widget.network.followingIds.contains(userId);

  int _followerCount(String userId) {
    for (final creator in widget.creators) {
      if (creator.profile.id == userId) return creator.followerCount;
    }
    return 0;
  }

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

    // All/Live/Following preserve the backend Fame Algo order. Rising is an
    // explicit exploration lane and is intentionally re-ordered client-side.
    if (_filter == _DiscoverFilter.rising) {
      rooms.sort((a, b) {
        final aScore =
            a.fameTaps + (_followerCount(a.hostUserId) < 2500 ? 60 : 0);
        final bScore =
            b.fameTaps + (_followerCount(b.hostUserId) < 2500 ? 60 : 0);
        return bScore.compareTo(aScore);
      });
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
    }
    return creators;
  }

  String get _rankingRpcKind => switch (_rankingKind) {
    _RankingKind.tappers => 'tappers',
    _RankingKind.gifters => 'gifters',
    _RankingKind.creators => 'creators',
  };

  Future<void> _loadRanking() async {
    if (_rankingLoading) return;
    if (mounted) {
      setState(() {
        _rankingLoading = true;
        _rankingError = null;
      });
    }
    try {
      final raw = await Supabase.instance.client.rpc(
        'get_fameverse_rankings',
        params: <String, dynamic>{'p_kind': _rankingRpcKind, 'p_limit': 25},
      );
      final entries = (raw as List? ?? const []).map((item) {
        final row = Map<String, dynamic>.from(item as Map);
        final username = row['username']?.toString();
        return _RankingEntry(
          rank: (row['rank_position'] as num?)?.toInt() ?? 0,
          profile: FvProfile(
            id: row['user_id'].toString(),
            displayName: row['display_name']?.toString() ?? 'Fameverse User',
            username: username,
            bio: '',
            avatarUrl: row['avatar_url']?.toString(),
            createdAt: null,
          ),
          score: (row['score'] as num?)?.toInt() ?? 0,
          secondary: (row['secondary'] as num?)?.toInt() ?? 0,
        );
      }).toList();
      if (!mounted) return;
      setState(() {
        _ranking = entries;
        _rankingLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _rankingLoading = false;
        _rankingError = 'Rankings could not refresh right now.';
      });
    }
  }

  Future<void> _refresh() async {
    await widget.onRefresh();
    await _loadRanking();
  }

  void _selectRanking(_RankingKind kind) {
    if (_rankingKind == kind) return;
    setState(() {
      _rankingKind = kind;
      _ranking = const [];
    });
    _loadRanking();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          key: const Key('fameverse-intentional-discover'),
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 116),
          children: [
            _DiscoverTopBar(
              profile: widget.profile,
              onOpenProfile: widget.onOpenProfile,
            ),
            const SizedBox(height: 18),
            const _DiscoverIdentityCard(),
            const SizedBox(height: 16),
            _ViewPicker(
              view: _view,
              onChanged: (value) => setState(() => _view = value),
            ),
            const SizedBox(height: 18),
            if (_view == _DiscoverView.explore) _buildExplore(),
            if (_view == _DiscoverView.rankings) _buildRankings(),
          ],
        ),
      ),
    );
  }

  Widget _buildExplore() {
    final rooms = _rooms;
    final creators = _creators;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
            fillColor: const Color(0xFF151018),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(color: Color(0xFF35263D)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(color: Color(0xFF35263D)),
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
        const SizedBox(height: 12),
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
                onTap: () => setState(() => _filter = _DiscoverFilter.creators),
              ),
              _FilterChip(
                label: 'Rising',
                selected: _filter == _DiscoverFilter.rising,
                onTap: () => setState(() => _filter = _DiscoverFilter.rising),
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
        const SizedBox(height: 24),
        if (widget.loading && widget.rooms.isEmpty && widget.creators.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(38),
              child: CircularProgressIndicator(),
            ),
          )
        else ...[
          if (_filter != _DiscoverFilter.creators) ...[
            _SectionHeader(
              eyebrow: _filter == _DiscoverFilter.rising
                  ? 'RISING LIVE'
                  : 'FAME ALGO LIVE',
              title: _query.isEmpty ? 'Streams to discover' : 'Live matches',
              count: rooms.length,
            ),
            const SizedBox(height: 12),
            if (rooms.isEmpty)
              const _EmptyCard(
                icon: Icons.live_tv_outlined,
                title: 'No matching Live rooms',
                body: 'Try another filter or search for a creator instead.',
              )
            else
              ...rooms
                  .take(12)
                  .map(
                    (room) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _LiveRow(
                        room: room,
                        onTap: () => widget.onRoomSelected(room),
                      ),
                    ),
                  ),
            const SizedBox(height: 24),
          ],
          if (_filter != _DiscoverFilter.live) ...[
            _SectionHeader(
              eyebrow: _filter == _DiscoverFilter.rising
                  ? 'RISING CREATORS'
                  : 'FAME ALGO PEOPLE',
              title: _query.isEmpty
                  ? 'Creators to discover'
                  : 'Creator matches',
              count: creators.length,
            ),
            const SizedBox(height: 12),
            if (creators.isEmpty)
              const _EmptyCard(
                icon: Icons.people_outline_rounded,
                title: 'No creators in this filter yet',
                body: 'Try another search or switch back to All.',
              )
            else
              ...creators.take(16).map((creator) {
                final following = _following(creator.profile.id);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 9),
                  child: _CreatorRow(
                    creator: creator,
                    following: following,
                    busy: widget.followBusy,
                    onFollow: () => widget.onToggleFollow(creator.profile.id),
                    onOpen: () => widget.onCreatorSelected(creator.profile),
                  ),
                );
              }),
          ],
        ],
      ],
    );
  }

  Widget _buildRankings() {
    return Column(
      key: const Key('discover-rankings-surface'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Fameverse Rankings',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 5),
        const Text(
          'Server-authoritative rankings. FameTaps use eligible taps, not raw spam.',
          style: TextStyle(color: Color(0xFFA99CAB), fontSize: 12, height: 1.4),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _RankingChip(
                label: 'Top Tappers',
                selected: _rankingKind == _RankingKind.tappers,
                onTap: () => _selectRanking(_RankingKind.tappers),
              ),
            ),
            const SizedBox(width: 7),
            Expanded(
              child: _RankingChip(
                label: 'Top Gifters',
                selected: _rankingKind == _RankingKind.gifters,
                onTap: () => _selectRanking(_RankingKind.gifters),
              ),
            ),
            const SizedBox(width: 7),
            Expanded(
              child: _RankingChip(
                label: 'Creators',
                selected: _rankingKind == _RankingKind.creators,
                onTap: () => _selectRanking(_RankingKind.creators),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        if (_rankingLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(36),
              child: CircularProgressIndicator(),
            ),
          )
        else if (_rankingError != null)
          _EmptyCard(
            icon: Icons.cloud_off_rounded,
            title: 'Rankings unavailable',
            body: _rankingError!,
          )
        else if (_ranking.isEmpty)
          const _EmptyCard(
            icon: Icons.emoji_events_outlined,
            title: 'No ranking activity yet',
            body: 'Eligible FameTaps and gifts will populate this board.',
          )
        else
          ..._ranking.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _RankingRow(
                entry: entry,
                kind: _rankingKind,
                onTap: () => widget.onCreatorSelected(entry.profile),
              ),
            ),
          ),
      ],
    );
  }
}

class _DiscoverIdentityCard extends StatelessWidget {
  const _DiscoverIdentityCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: [Color(0xFF251231), Color(0xFF110C16)],
        ),
        border: Border.all(color: const Color(0xFF493057)),
      ),
      child: const Row(
        children: [
          _FameTapMark(size: 30),
          SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'DISCOVER · FAME ALGO',
                  key: Key('discover-fame-algo-label'),
                  style: TextStyle(
                    color: Color(0xFFD49AFF),
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Explore people, Live and rankings',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ViewPicker extends StatelessWidget {
  const _ViewPicker({required this.view, required this.onChanged});

  final _DiscoverView view;
  final ValueChanged<_DiscoverView> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ViewButton(
            label: 'Explore',
            icon: Icons.explore_outlined,
            selected: view == _DiscoverView.explore,
            onTap: () => onChanged(_DiscoverView.explore),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _ViewButton(
            label: 'Rankings',
            icon: Icons.emoji_events_outlined,
            selected: view == _DiscoverView.rankings,
            onTap: () => onChanged(_DiscoverView.rankings),
          ),
        ),
      ],
    );
  }
}

class _ViewButton extends StatelessWidget {
  const _ViewButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: Key('discover-view-${label.toLowerCase()}'),
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF6B31B5) : const Color(0xFF151018),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? const Color(0xFFB56CFF) : const Color(0xFF35263D),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18),
            const SizedBox(width: 7),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w900)),
          ],
        ),
      ),
    );
  }
}

class _RankingChip extends StatelessWidget {
  const _RankingChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF342046) : const Color(0xFF151018),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? const Color(0xFF9A5BC2) : const Color(0xFF35263D),
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11,
            fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _RankingRow extends StatelessWidget {
  const _RankingRow({
    required this.entry,
    required this.kind,
    required this.onTap,
  });

  final _RankingEntry entry;
  final _RankingKind kind;
  final VoidCallback onTap;

  String get _metric => switch (kind) {
    _RankingKind.tappers => '${_compact(entry.score)} eligible FameTaps',
    _RankingKind.gifters => '${_compact(entry.score)} Fame Coins sent',
    _RankingKind.creators => '${_compact(entry.score)} creator FameTaps',
  };

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: const Color(0xFF151018),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFF35263D)),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 34,
                child: Text(
                  '#${entry.rank}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: entry.rank <= 3
                        ? const Color(0xFFD9A5FF)
                        : const Color(0xFFA99CAB),
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              _Avatar(profile: entry.profile, radius: 22),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.profile.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${entry.profile.handle} · $_metric',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFFA99CAB),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Color(0xFF8F8196)),
            ],
          ),
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
                ),
              ),
            ],
          ),
        ),
        InkWell(
          onTap: onOpenProfile,
          customBorder: const CircleBorder(),
          child: _Avatar(profile: profile, radius: 22),
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
            color: selected ? const Color(0xFF6B31B5) : const Color(0xFF151018),
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

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
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

class _LiveRow extends StatelessWidget {
  const _LiveRow({required this.room, required this.onTap});

  final FvLiveRoom room;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: const Color(0xFF151018),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFF35263D)),
          ),
          child: Row(
            children: [
              _Avatar(profile: room.host, radius: 24),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      room.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${room.host.handle} · ${_compact(room.fameTaps)} FameTaps',
                      style: const TextStyle(
                        color: Color(0xFFA99CAB),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const _FameTapMark(size: 22),
            ],
          ),
        ),
      ),
    );
  }
}

class _CreatorRow extends StatelessWidget {
  const _CreatorRow({
    required this.creator,
    required this.following,
    required this.busy,
    required this.onFollow,
    required this.onOpen,
  });

  final FvCreator creator;
  final bool following;
  final bool busy;
  final VoidCallback onFollow;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF151018),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF35263D)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: onOpen,
            child: _Avatar(profile: creator.profile, radius: 24),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: GestureDetector(
              onTap: onOpen,
              behavior: HitTestBehavior.opaque,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    creator.profile.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${creator.profile.handle} · ${_compact(creator.followerCount)} followers',
                    style: const TextStyle(
                      color: Color(0xFFA99CAB),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
          TextButton(
            onPressed: busy ? null : onFollow,
            child: Text(following ? 'Following' : 'Follow'),
          ),
        ],
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({
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
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF35263D)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFFB879E8)),
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
                    color: Color(0xFFA99CAB),
                    fontSize: 12,
                    height: 1.4,
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

class _FameTapMark extends StatelessWidget {
  const _FameTapMark({this.size = 20});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            Icons.local_fire_department_rounded,
            size: size,
            color: const Color(0xFF9B55FF),
          ),
          Positioned(
            bottom: size * .14,
            child: Text(
              'F',
              style: TextStyle(
                color: Colors.white,
                fontSize: size * .4,
                height: 1,
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.profile, required this.radius});

  final FvProfile profile;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final url = profile.avatarUrl?.trim();
    return CircleAvatar(
      radius: radius,
      backgroundColor: const Color(0xFF3A2148),
      foregroundImage: url == null || url.isEmpty ? null : NetworkImage(url),
      child: Text(
        profile.initial,
        style: const TextStyle(fontWeight: FontWeight.w900),
      ),
    );
  }
}

String _compact(int value) {
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

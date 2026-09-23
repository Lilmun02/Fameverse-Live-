import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

class FvIdentity {
  const FvIdentity({required this.id, required this.email});

  final String id;
  final String email;
}

class FvProfile {
  const FvProfile({
    required this.id,
    required this.displayName,
    required this.username,
    required this.bio,
    required this.avatarUrl,
    required this.createdAt,
  });

  final String id;
  final String displayName;
  final String? username;
  final String bio;
  final String? avatarUrl;
  final DateTime? createdAt;

  String get handle =>
      username == null || username!.isEmpty ? '@newuser' : '@$username';
  String get initial {
    final source = displayName.trim().isNotEmpty
        ? displayName.trim()
        : (username ?? 'F');
    return source.substring(0, 1).toUpperCase();
  }
}

class FvFollowNetwork {
  const FvFollowNetwork({
    required this.followers,
    required this.following,
    required this.followerIds,
    required this.followingIds,
  });

  final List<FvProfile> followers;
  final List<FvProfile> following;
  final Set<String> followerIds;
  final Set<String> followingIds;

  List<FvProfile> get friends {
    final ids = followerIds.intersection(followingIds);
    final byId = <String, FvProfile>{
      for (final profile in followers) profile.id: profile,
      for (final profile in following) profile.id: profile,
    };
    return ids.map((id) => byId[id]).whereType<FvProfile>().toList();
  }
}

class FvCreator {
  const FvCreator({required this.profile, required this.followerCount});

  final FvProfile profile;
  final int followerCount;
}

class FvLiveRoom {
  const FvLiveRoom({
    required this.id,
    required this.hostUserId,
    required this.title,
    required this.fameTaps,
    required this.host,
    this.goal = '',
    this.wishlistGiftIds = const [],
  });

  final String id;
  final String hostUserId;
  final String title;
  final int fameTaps;
  final FvProfile host;
  final String goal;
  final List<String> wishlistGiftIds;
}

class FvAuthResult {
  const FvAuthResult({required this.signedIn, required this.message});

  final bool signedIn;
  final String message;
}

abstract class FameverseBackend {
  FvIdentity? get currentIdentity;
  Stream<FvIdentity?> get authChanges;

  Future<void> signIn({required String email, required String password});
  Future<FvAuthResult> signUp({
    required String email,
    required String password,
    required String displayName,
  });
  Future<void> signOut();
  Future<FvProfile?> loadProfile(String userId);
  Future<String?> loadAccountRole(String userId);
  Future<FvProfile> saveProfile({
    required String userId,
    required String displayName,
    required String username,
    required String bio,
  });
  Future<FvProfile> uploadProfileAvatar({
    required String userId,
    required Uint8List bytes,
    required String extension,
    required String contentType,
  });
  Future<FvFollowNetwork> loadFollowNetwork(String userId);
  Future<List<FvCreator>> listRecommendedCreators({
    required String excludeUserId,
  });
  Future<List<FvLiveRoom>> listActiveLiveRooms({required String excludeUserId});
  Future<void> setFollowing({
    required String userId,
    required String targetId,
    required bool following,
  });
}

class SupabaseFameverseBackend implements FameverseBackend {
  SupabaseFameverseBackend(this._client);

  final SupabaseClient _client;

  static const _profileFields =
      'id, username, display_name, bio, avatar_url, created_at';

  FvIdentity? _identityFromUser(User? user) {
    if (user == null) return null;
    return FvIdentity(id: user.id, email: user.email ?? '');
  }

  @override
  FvIdentity? get currentIdentity => _identityFromUser(_client.auth.currentUser);

  @override
  Stream<FvIdentity?> get authChanges => _client.auth.onAuthStateChange.map(
    (state) => _identityFromUser(state.session?.user),
  );

  @override
  Future<void> signIn({required String email, required String password}) async {
    await _client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  @override
  Future<FvAuthResult> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final response = await _client.auth.signUp(
      email: email.trim(),
      password: password,
      data: {
        'display_name': displayName.trim().isEmpty
            ? 'Fameverse User'
            : displayName.trim(),
      },
    );
    return FvAuthResult(
      signedIn: response.session != null,
      message: response.session != null
          ? 'Account created.'
          : 'Account created. Sign in to continue.',
    );
  }

  @override
  Future<void> signOut() => _client.auth.signOut();

  FvProfile _profileFromMap(Map<String, dynamic> row) {
    final username = row['username'] as String?;
    final displayName = (row['display_name'] as String?)?.trim();
    return FvProfile(
      id: row['id'] as String,
      displayName: displayName == null || displayName.isEmpty
          ? (username?.isNotEmpty == true ? username! : 'Fameverse User')
          : displayName,
      username: username,
      bio: (row['bio'] as String?) ?? '',
      avatarUrl: row['avatar_url'] as String?,
      createdAt: DateTime.tryParse((row['created_at'] as String?) ?? ''),
    );
  }

  @override
  Future<FvProfile?> loadProfile(String userId) async {
    final row = await _client
        .from('profiles')
        .select(_profileFields)
        .eq('id', userId)
        .maybeSingle();
    if (row == null) return null;
    return _profileFromMap(row);
  }

  @override
  Future<String?> loadAccountRole(String userId) async {
    final row = await _client
        .from('account_roles')
        .select('role')
        .eq('user_id', userId)
        .maybeSingle();
    return (row?['role'] as String?)?.trim().toLowerCase();
  }

  String _cleanUsername(String value) {
    final cleaned = value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9_]'), '')
        .replaceAll(RegExp(r'_+'), '_');
    if (cleaned.length <= 24) return cleaned;
    return cleaned.substring(0, 24);
  }

  @override
  Future<FvProfile> saveProfile({
    required String userId,
    required String displayName,
    required String username,
    required String bio,
  }) async {
    final cleanUsername = _cleanUsername(username);
    if (username.trim().isNotEmpty && cleanUsername.length < 3) {
      throw Exception('Username must be at least 3 characters');
    }

    final cleanDisplayName = displayName.trim().isEmpty
        ? 'Fameverse User'
        : displayName.trim();
    final cleanBio = bio.trim();
    final row = await _client
        .from('profiles')
        .update({
          'display_name': cleanDisplayName.substring(
            0,
            cleanDisplayName.length > 40 ? 40 : cleanDisplayName.length,
          ),
          'username': cleanUsername.isEmpty ? null : cleanUsername,
          'bio': cleanBio.substring(0, cleanBio.length > 160 ? 160 : cleanBio.length),
        })
        .eq('id', userId)
        .select(_profileFields)
        .single();
    return _profileFromMap(row);
  }

  @override
  Future<FvProfile> uploadProfileAvatar({
    required String userId,
    required Uint8List bytes,
    required String extension,
    required String contentType,
  }) async {
    if (bytes.isEmpty || bytes.length > 5 * 1024 * 1024) {
      throw Exception('Avatar must be 5 MB or smaller');
    }
    const allowedContentTypes = {'image/jpeg', 'image/png', 'image/webp'};
    if (!allowedContentTypes.contains(contentType)) {
      throw Exception('Avatar must be JPG, PNG, or WEBP');
    }
    final normalizedExtension = switch (extension.toLowerCase()) {
      'png' => 'png',
      'webp' => 'webp',
      _ => 'jpg',
    };
    final path = '$userId/avatar.$normalizedExtension';
    final bucket = _client.storage.from('profile-avatars');
    await bucket.uploadBinary(
      path,
      bytes,
      fileOptions: FileOptions(contentType: contentType, upsert: true),
    );
    final publicUrl = bucket.getPublicUrl(path);
    final cacheBusted = '$publicUrl?v=${DateTime.now().millisecondsSinceEpoch}';
    final row = await _client
        .from('profiles')
        .update({'avatar_url': cacheBusted})
        .eq('id', userId)
        .select(_profileFields)
        .single();
    return _profileFromMap(row);
  }

  Future<List<FvProfile>> _profilesForIds(Set<String> ids) async {
    if (ids.isEmpty) return const [];
    final rows = await _client
        .from('profiles')
        .select(_profileFields)
        .inFilter('id', ids.toList());
    return (rows as List)
        .map((row) => _profileFromMap(Map<String, dynamic>.from(row as Map)))
        .toList();
  }

  @override
  Future<FvFollowNetwork> loadFollowNetwork(String userId) async {
    final incomingRows = await _client
        .from('follows')
        .select('follower_id')
        .eq('following_id', userId);
    final outgoingRows = await _client
        .from('follows')
        .select('following_id')
        .eq('follower_id', userId);

    final followerIds = (incomingRows as List)
        .map((row) => (row as Map)['follower_id'] as String)
        .toSet();
    final followingIds = (outgoingRows as List)
        .map((row) => (row as Map)['following_id'] as String)
        .toSet();
    final profiles = await _profilesForIds({...followerIds, ...followingIds});
    final byId = {for (final profile in profiles) profile.id: profile};

    return FvFollowNetwork(
      followers: followerIds.map((id) => byId[id]).whereType<FvProfile>().toList(),
      following: followingIds.map((id) => byId[id]).whereType<FvProfile>().toList(),
      followerIds: followerIds,
      followingIds: followingIds,
    );
  }

  @override
  Future<void> setFollowing({
    required String userId,
    required String targetId,
    required bool following,
  }) async {
    if (userId == targetId) return;
    if (following) {
      try {
        await _client.from('follows').insert({
          'follower_id': userId,
          'following_id': targetId,
        });
      } on PostgrestException catch (error) {
        if (error.code != '23505') rethrow;
      }
      return;
    }
    await _client
        .from('follows')
        .delete()
        .eq('follower_id', userId)
        .eq('following_id', targetId);
  }

  @override
  Future<List<FvCreator>> listRecommendedCreators({
    required String excludeUserId,
  }) async {
    final profileRows = await _client
        .from('profiles')
        .select(_profileFields)
        .order('created_at', ascending: false)
        .limit(40);
    final followRows = await _client.from('follows').select('following_id');

    final followerCounts = <String, int>{};
    for (final raw in followRows as List) {
      final id = (raw as Map)['following_id'] as String;
      followerCounts[id] = (followerCounts[id] ?? 0) + 1;
    }

    final creators = (profileRows as List)
        .map((row) => _profileFromMap(Map<String, dynamic>.from(row as Map)))
        .where((profile) => profile.id != excludeUserId)
        .map(
          (profile) => FvCreator(
            profile: profile,
            followerCount: followerCounts[profile.id] ?? 0,
          ),
        )
        .toList()
      ..sort((a, b) {
        final count = b.followerCount.compareTo(a.followerCount);
        if (count != 0) return count;
        final aDate = a.profile.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bDate = b.profile.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bDate.compareTo(aDate);
      });

    return creators.take(12).toList();
  }

  @override
  Future<List<FvLiveRoom>> listActiveLiveRooms({
    required String excludeUserId,
  }) async {
    final cutoff = DateTime.now()
        .subtract(const Duration(seconds: 45))
        .toUtc()
        .toIso8601String();
    final roomRows = await _client
        .from('live_rooms')
        .select(
          'id, host_user_id, title, goal, wishlist_gift_ids, heartbeat_at, started_at',
        )
        .eq('status', 'live')
        .gte('heartbeat_at', cutoff)
        .order('started_at', ascending: false);

    final visible = (roomRows as List)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .where((row) => row['host_user_id'] != excludeUserId)
        .toList();
    if (visible.isEmpty) return const [];

    final hostIds = visible.map((row) => row['host_user_id'] as String).toSet();
    final roomIds = visible.map((row) => row['id'] as String).toSet();
    final hosts = await _profilesForIds(hostIds);
    final hostById = {for (final host in hosts) host.id: host};
    final tapRows = await _client
        .from('live_tap_totals')
        .select('room_id, raw_taps')
        .inFilter('room_id', roomIds.toList());
    final tapsByRoom = <String, int>{};
    for (final raw in tapRows as List) {
      final map = raw as Map;
      tapsByRoom[map['room_id'] as String] = (map['raw_taps'] as num?)?.toInt() ?? 0;
    }

    return visible.map((room) {
      final hostUserId = room['host_user_id'] as String;
      final host = hostById[hostUserId] ??
          FvProfile(
            id: hostUserId,
            displayName: 'Fameverse creator',
            username: null,
            bio: '',
            avatarUrl: null,
            createdAt: null,
          );
      final rawWishlist = room['wishlist_gift_ids'];
      return FvLiveRoom(
        id: room['id'] as String,
        hostUserId: hostUserId,
        title: ((room['title'] as String?)?.trim().isNotEmpty ?? false)
            ? room['title'] as String
            : 'Live on Fameverse',
        goal: (room['goal'] as String?) ?? '',
        wishlistGiftIds: rawWishlist is List
            ? rawWishlist.map((item) => item.toString()).toList()
            : const [],
        fameTaps: tapsByRoom[room['id'] as String] ?? 0,
        host: host,
      );
    }).toList();
  }
}

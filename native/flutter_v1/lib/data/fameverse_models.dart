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

  String get hostDisplayName => host.displayName;
}

class FvAuthResult {
  const FvAuthResult({required this.signedIn, required this.message});

  final bool signedIn;
  final String message;
}

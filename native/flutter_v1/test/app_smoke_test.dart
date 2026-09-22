import 'package:fameverse_live/app/fameverse_app.dart';
import 'package:fameverse_live/data/fameverse_backend.dart';
import 'package:fameverse_live/data/fameverse_live_backend.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('signed-out native product opens account entry', (tester) async {
    await tester.pumpWidget(
      FameverseApp(backend: _FakeBackend(), liveBackend: _FakeLiveBackend()),
    );

    expect(find.byKey(FameverseApp.productShellKey), findsOneWidget);
    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Native pipeline probe'), findsNothing);
  });

  testWidgets('signed-in native product exposes primary navigation', (
    tester,
  ) async {
    const identity = FvIdentity(id: 'user-1', email: 'owner@example.com');
    await tester.pumpWidget(
      FameverseApp(
        backend: _FakeBackend(identity: identity),
        liveBackend: _FakeLiveBackend(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('native-product-wordmark')), findsOneWidget);
    expect(find.byKey(const Key('fameverse-bottom-nav')), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Discover'), findsOneWidget);
    expect(find.text('Live'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);

    await tester.tap(find.text('Discover'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('discover-title')), findsOneWidget);
  });
}

class _FakeBackend implements FameverseBackend {
  _FakeBackend({this.identity});

  final FvIdentity? identity;

  @override
  Stream<FvIdentity?> get authChanges => const Stream.empty();

  @override
  FvIdentity? get currentIdentity => identity;

  @override
  Future<FvFollowNetwork> loadFollowNetwork(String userId) async {
    return const FvFollowNetwork(
      followers: [],
      following: [],
      followerIds: {},
      followingIds: {},
    );
  }

  @override
  Future<FvProfile?> loadProfile(String userId) async {
    if (identity == null) return null;
    return const FvProfile(
      id: 'user-1',
      displayName: 'Fameverse Owner',
      username: 'owner',
      bio: 'Native beta',
      avatarUrl: null,
      createdAt: null,
    );
  }

  @override
  Future<List<FvLiveRoom>> listActiveLiveRooms({
    required String excludeUserId,
  }) async {
    return const [];
  }

  @override
  Future<List<FvCreator>> listRecommendedCreators({
    required String excludeUserId,
  }) async {
    return const [];
  }

  @override
  Future<FvProfile> saveProfile({
    required String userId,
    required String displayName,
    required String username,
    required String bio,
  }) async {
    return FvProfile(
      id: userId,
      displayName: displayName,
      username: username,
      bio: bio,
      avatarUrl: null,
      createdAt: null,
    );
  }

  @override
  Future<void> setFollowing({
    required String userId,
    required String targetId,
    required bool following,
  }) async {}

  @override
  Future<void> signIn({
    required String email,
    required String password,
  }) async {}

  @override
  Future<void> signOut() async {}

  @override
  Future<FvAuthResult> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    return const FvAuthResult(signedIn: false, message: 'Account created.');
  }
}

class _FakeLiveBackend implements FameverseLiveBackend {
  @override
  Future<FvLiveRoom> startLiveRoom({
    required FvIdentity identity,
    required FvProfile profile,
    required String title,
  }) async {
    return FvLiveRoom(
      id: 'room-1',
      hostUserId: identity.id,
      title: title.isEmpty ? 'Live on Fameverse' : title,
      fameTaps: 0,
      host: profile,
    );
  }

  @override
  Future<void> heartbeatLiveRoom({
    required String roomId,
    required String hostUserId,
  }) async {}

  @override
  Future<void> endLiveRoom({
    required String roomId,
    required String hostUserId,
  }) async {}

  @override
  Future<FvLiveCredentials> issueLiveCredentials({
    required String roomId,
    required String role,
  }) async {
    return const FvLiveCredentials(
      serverUrl: 'wss://example.invalid',
      participantToken: 'test-token',
      roomName: 'fv_room-1',
    );
  }
}

import 'package:supabase_flutter/supabase_flutter.dart';

int _betaInt(dynamic value) {
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

DateTime? _betaDate(dynamic value) {
  final text = value?.toString();
  if (text == null || text.isEmpty) return null;
  return DateTime.tryParse(text);
}

class FvBetaMissionDefinition {
  const FvBetaMissionDefinition({
    required this.key,
    required this.title,
    required this.detail,
    required this.required,
  });

  final String key;
  final String title;
  final String detail;
  final bool required;
}

const fvFirstVerseMissions = <FvBetaMissionDefinition>[
  FvBetaMissionDefinition(
    key: 'complete_profile',
    title: 'Build your profile',
    detail:
        'Save your name, username, bio or profile photo and confirm the update.',
    required: true,
  ),
  FvBetaMissionDefinition(
    key: 'browse_home',
    title: 'Browse Home',
    detail:
        'Use the streaming-first Home feed and check that browsing stays smooth.',
    required: true,
  ),
  FvBetaMissionDefinition(
    key: 'browse_discover',
    title: 'Explore Discover',
    detail: 'Open Discover and browse or search creators and Live rooms.',
    required: true,
  ),
  FvBetaMissionDefinition(
    key: 'open_public_profile',
    title: 'Open another profile',
    detail:
        'Open a public creator profile and make sure the profile loads correctly.',
    required: true,
  ),
  FvBetaMissionDefinition(
    key: 'follow_creator',
    title: 'Test following',
    detail: 'Follow or unfollow another creator and confirm the state updates.',
    required: true,
  ),
  FvBetaMissionDefinition(
    key: 'join_live',
    title: 'Join a Live',
    detail:
        'Enter a creator Live and confirm the stream connects and exits normally.',
    required: true,
  ),
  FvBetaMissionDefinition(
    key: 'send_comment',
    title: 'Send a Live comment',
    detail: 'Post a normal comment in Live and confirm it appears correctly.',
    required: true,
  ),
  FvBetaMissionDefinition(
    key: 'view_story',
    title: 'View a Story',
    detail:
        'Open a creator Story and test the Story viewer once Stories are enabled.',
    required: true,
  ),
  FvBetaMissionDefinition(
    key: 'send_gift',
    title: 'Gift-path check',
    detail:
        'Optional: send a permitted beta gift and report any visual or playback issue.',
    required: false,
  ),
  FvBetaMissionDefinition(
    key: 'cohost_session',
    title: 'Co-host check',
    detail:
        'Optional: complete a co-host session and verify camera/mic recovery.',
    required: false,
  ),
];

class FvBetaProgramStatus {
  const FvBetaProgramStatus({
    required this.enrolled,
    required this.memberStatus,
    required this.completedRequired,
    required this.requiredTotal,
    required this.completedOptional,
    required this.badgeUnlocked,
    required this.badgeUnlockedAt,
    required this.completedMissionKeys,
    this.privilegedAccess = false,
  });

  final bool enrolled;
  final String? memberStatus;
  final int completedRequired;
  final int requiredTotal;
  final int completedOptional;
  final bool badgeUnlocked;
  final DateTime? badgeUnlockedAt;
  final Set<String> completedMissionKeys;

  /// Owner/admin can inspect every First Verse surface without receiving a
  /// fake badge award or fake mission completion.
  final bool privilegedAccess;

  double get progress {
    if (requiredTotal <= 0) return 0;
    return (completedRequired / requiredTotal).clamp(0.0, 1.0);
  }

  bool completed(String key) => completedMissionKeys.contains(key);

  FvBetaProgramStatus withPrivilegedAccess(bool value) {
    return FvBetaProgramStatus(
      // Privileged access is treated as UI enrollment so owner/admin never
      // disappear behind tester-only navigation. Badge and mission state stay
      // exactly as the backend reported them.
      enrolled: enrolled || value,
      memberStatus: memberStatus ?? (value ? 'privileged_preview' : null),
      completedRequired: completedRequired,
      requiredTotal: requiredTotal,
      completedOptional: completedOptional,
      badgeUnlocked: badgeUnlocked,
      badgeUnlockedAt: badgeUnlockedAt,
      completedMissionKeys: completedMissionKeys,
      privilegedAccess: value,
    );
  }

  factory FvBetaProgramStatus.fromMap(Map<String, dynamic> row) {
    final rawMissions = row['completed_missions'];
    final completed = <String>{};
    if (rawMissions is List) {
      completed.addAll(rawMissions.map((item) => item.toString()));
    }
    return FvBetaProgramStatus(
      enrolled: row['enrolled'] == true,
      memberStatus: row['member_status']?.toString(),
      completedRequired: _betaInt(row['completed_required']),
      requiredTotal: _betaInt(row['required_total']),
      completedOptional: _betaInt(row['completed_optional']),
      badgeUnlocked: row['badge_unlocked'] == true,
      badgeUnlockedAt: _betaDate(row['badge_unlocked_at']),
      completedMissionKeys: completed,
    );
  }

  static const notEnrolled = FvBetaProgramStatus(
    enrolled: false,
    memberStatus: null,
    completedRequired: 0,
    requiredTotal: 8,
    completedOptional: 0,
    badgeUnlocked: false,
    badgeUnlockedAt: null,
    completedMissionKeys: <String>{},
  );
}

abstract class FameverseBetaBackend {
  Future<FvBetaProgramStatus> loadProgramStatus();
  Future<void> recordMission(String missionKey);
}

class SupabaseFameverseBetaBackend implements FameverseBetaBackend {
  SupabaseFameverseBetaBackend(this._client);

  final SupabaseClient _client;

  static SupabaseFameverseBetaBackend get instance =>
      SupabaseFameverseBetaBackend(Supabase.instance.client);

  List<Map<String, dynamic>> _rows(dynamic response) {
    if (response is! List) return const [];
    return response
        .whereType<Map>()
        .map((row) => Map<String, dynamic>.from(row))
        .toList();
  }

  Future<bool> _hasPrivilegedAccess() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return false;
    try {
      final row = await _client
          .from('account_roles')
          .select('role')
          .eq('user_id', userId)
          .maybeSingle();
      final role = row?['role']?.toString().trim().toLowerCase();
      return role == 'owner' || role == 'admin';
    } catch (_) {
      return false;
    }
  }

  @override
  Future<FvBetaProgramStatus> loadProgramStatus() async {
    final results = await Future.wait<dynamic>([
      _client.rpc('get_beta_program_status'),
      _hasPrivilegedAccess(),
    ]);
    final rows = _rows(results[0]);
    final privileged = results[1] == true;
    final status = rows.isEmpty
        ? FvBetaProgramStatus.notEnrolled
        : FvBetaProgramStatus.fromMap(rows.first);
    return status.withPrivilegedAccess(privileged);
  }

  @override
  Future<void> recordMission(String missionKey) async {
    await _client.rpc(
      'record_beta_test_mission',
      params: <String, dynamic>{'p_mission_key': missionKey},
    );
  }
}

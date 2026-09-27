class FvStartupUpdateNotice {
  const FvStartupUpdateNotice({
    required this.updateType,
    required this.title,
    required this.summary,
    required this.changelog,
    required this.requiresAcknowledgement,
    this.versionLabel,
    this.buildNumber,
  });

  final String updateType;
  final String title;
  final String summary;
  final List<String> changelog;
  final bool requiresAcknowledgement;
  final String? versionLabel;
  final int? buildNumber;

  String get badgeLabel => switch (updateType) {
    'app' => 'APP UPDATE',
    'maintenance' => 'SERVICE UPDATE',
    'feature' => 'WHAT’S NEW',
    _ => 'BACKEND UPDATE',
  };
}

class FvBackendManifest {
  const FvBackendManifest(this.data);

  final Map<String, dynamic> data;

  static const empty = FvBackendManifest(<String, dynamic>{});

  Map<String, dynamic> _section(String key) {
    final value = data[key];
    return value is Map ? Map<String, dynamic>.from(value) : const {};
  }

  bool featureEnabled(String key, {bool fallback = true}) {
    final value = _section('features')[key];
    return value is bool ? value : fallback;
  }

  String label(String key, String fallback) {
    final value = _section('labels')[key]?.toString().trim();
    return value == null || value.isEmpty ? fallback : value;
  }

  int integer(String section, String key, int fallback) {
    final value = _section(section)[key];
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  String string(String section, String key, String fallback) {
    final value = _section(section)[key]?.toString().trim();
    return value == null || value.isEmpty ? fallback : value;
  }
}

class FvBackendRuntime {
  FvBackendRuntime._();

  static FvBackendManifest manifest = FvBackendManifest.empty;
  static int backendRevision = 0;
  static String releaseLabel = 'bundled';
  static FvStartupUpdateNotice? pendingNotice;
  static bool backendChangedThisLaunch = false;

  static void install({
    required FvBackendManifest nextManifest,
    required int revision,
    required String label,
    FvStartupUpdateNotice? notice,
    bool changedThisLaunch = false,
  }) {
    manifest = nextManifest;
    backendRevision = revision;
    releaseLabel = label;
    pendingNotice = notice;
    backendChangedThisLaunch = changedThisLaunch;
  }

  static void clearPendingNotice() {
    pendingNotice = null;
    backendChangedThisLaunch = false;
  }
}

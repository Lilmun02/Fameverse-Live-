import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'backend_runtime.dart';

class FvStartupSyncResult {
  const FvStartupSyncResult({
    required this.backendRevision,
    required this.releaseLabel,
    required this.manifest,
    required this.backendChanged,
    required this.usedCachedManifest,
    required this.notice,
  });

  final int backendRevision;
  final String releaseLabel;
  final FvBackendManifest manifest;
  final bool backendChanged;
  final bool usedCachedManifest;
  final FvStartupUpdateNotice? notice;
}

class FvStartupUpdateService {
  FvStartupUpdateService(this._client);

  final SupabaseClient _client;

  String _revisionKey(String channel) => 'fv.backend_revision.$channel';
  String _manifestKey(String channel) => 'fv.backend_manifest.$channel';
  String _labelKey(String channel) => 'fv.backend_label.$channel';

  Map<String, dynamic> _map(dynamic value) {
    return value is Map ? Map<String, dynamic>.from(value) : const {};
  }

  Future<FvStartupSyncResult> sync({required String channel}) async {
    final prefs = await SharedPreferences.getInstance();
    final cachedRevision = prefs.getInt(_revisionKey(channel)) ?? 0;
    final cachedLabel = prefs.getString(_labelKey(channel)) ?? 'bundled';
    final cachedManifest = _decodeManifest(
      prefs.getString(_manifestKey(channel)),
    );

    // Install the last known-good runtime immediately. Network failure must not
    // disable a previously validated Fameverse backend contract.
    FvBackendRuntime.install(
      nextManifest: cachedManifest,
      revision: cachedRevision,
      label: cachedLabel,
    );

    try {
      final releaseRow = await _client
          .from('app_release_state')
          .select('backend_revision, release_label, manifest, updated_at')
          .eq('channel', channel)
          .maybeSingle()
          .timeout(const Duration(milliseconds: 1200));

      if (releaseRow == null) {
        return FvStartupSyncResult(
          backendRevision: cachedRevision,
          releaseLabel: cachedLabel,
          manifest: cachedManifest,
          backendChanged: false,
          usedCachedManifest: cachedRevision > 0,
          notice: null,
        );
      }

      final remoteRevision =
          (releaseRow['backend_revision'] as num?)?.toInt() ?? cachedRevision;
      final remoteLabel =
          (releaseRow['release_label'] as String?)?.trim().isNotEmpty == true
          ? (releaseRow['release_label'] as String).trim()
          : cachedLabel;
      final remoteManifest = FvBackendManifest(_map(releaseRow['manifest']));
      final backendChanged = remoteRevision > cachedRevision;

      final manifest = backendChanged || cachedRevision == 0
          ? remoteManifest
          : cachedManifest.data.isEmpty
          ? remoteManifest
          : cachedManifest;

      FvStartupUpdateNotice? notice;
      if (backendChanged) {
        notice = await loadLatest(
          channel: channel,
        ).timeout(const Duration(milliseconds: 900), onTimeout: () => null);
      }

      if (backendChanged ||
          cachedRevision == 0 ||
          cachedManifest.data.isEmpty) {
        await prefs.setInt(_revisionKey(channel), remoteRevision);
        await prefs.setString(_labelKey(channel), remoteLabel);
        await prefs.setString(_manifestKey(channel), jsonEncode(manifest.data));
      }

      FvBackendRuntime.install(
        nextManifest: manifest,
        revision: remoteRevision,
        label: remoteLabel,
        notice: notice,
        changedThisLaunch: backendChanged,
      );
      return FvStartupSyncResult(
        backendRevision: remoteRevision,
        releaseLabel: remoteLabel,
        manifest: manifest,
        backendChanged: backendChanged,
        usedCachedManifest: false,
        notice: notice,
      );
    } catch (_) {
      return FvStartupSyncResult(
        backendRevision: cachedRevision,
        releaseLabel: cachedLabel,
        manifest: cachedManifest,
        backendChanged: false,
        usedCachedManifest: true,
        notice: null,
      );
    }
  }

  FvBackendManifest _decodeManifest(String? raw) {
    if (raw == null || raw.trim().isEmpty) return FvBackendManifest.empty;
    try {
      final decoded = jsonDecode(raw);
      return FvBackendManifest(_map(decoded));
    } catch (_) {
      return FvBackendManifest.empty;
    }
  }

  Future<FvStartupUpdateNotice?> loadLatest({required String channel}) async {
    final rows = await _client
        .from('app_update_notices')
        .select(
          'update_type, title, summary, version_label, build_number, '
          'changelog, requires_acknowledgement, published_at',
        )
        .eq('active', true)
        .eq('channel', channel)
        .order('published_at', ascending: false)
        .limit(1);

    if (rows.isEmpty) return null;
    final row = Map<String, dynamic>.from(rows.first);
    final rawChangelog = row['changelog'];
    final changelog = rawChangelog is List
        ? rawChangelog.map((item) => item.toString()).toList()
        : const <String>[];

    return FvStartupUpdateNotice(
      updateType: (row['update_type'] as String?) ?? 'backend',
      title: (row['title'] as String?) ?? 'Fameverse update',
      summary: (row['summary'] as String?) ?? '',
      versionLabel: row['version_label'] as String?,
      buildNumber: (row['build_number'] as num?)?.toInt(),
      changelog: changelog,
      requiresAcknowledgement:
          (row['requires_acknowledgement'] as bool?) ?? true,
    );
  }
}

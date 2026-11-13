/// A connected Stream call participant observed by the Live host.
class FvHostViewerIdentity {
  const FvHostViewerIdentity({
    required this.userId,
    required this.displayName,
  });

  final String userId;
  final String displayName;
}

/// Observes real call membership. The first roster is a baseline, not an
/// arrival; quick reconnects must not spam the host's chat overlay.
class FvHostViewerArrivalTracker {
  static const Duration reconnectCooldown = Duration(seconds: 30);

  final Set<String> _present = <String>{};
  final Map<String, DateTime> _lastAnnounced = <String, DateTime>{};
  bool _primed = false;

  List<FvHostViewerIdentity> observe(
    Iterable<FvHostViewerIdentity> participants, {
    required String hostUserId,
    DateTime? now,
  }) {
    final timestamp = now ?? DateTime.now();
    final connected = <String, FvHostViewerIdentity>{};
    for (final participant in participants) {
      final id = participant.userId.trim();
      if (id.isEmpty || id == hostUserId) continue;
      connected.putIfAbsent(id, () => participant);
    }

    if (!_primed) {
      _primed = true;
      _present
        ..clear()
        ..addAll(connected.keys);
      return const <FvHostViewerIdentity>[];
    }

    final arrived = <FvHostViewerIdentity>[];
    for (final entry in connected.entries) {
      if (_present.contains(entry.key)) continue;
      final last = _lastAnnounced[entry.key];
      if (last != null &&
          timestamp.difference(last) < reconnectCooldown) {
        continue;
      }
      arrived.add(entry.value);
      _lastAnnounced[entry.key] = timestamp;
    }

    _present
      ..clear()
      ..addAll(connected.keys);
    _lastAnnounced.removeWhere(
      (_, at) => timestamp.difference(at) > const Duration(minutes: 5),
    );
    return arrived;
  }
}

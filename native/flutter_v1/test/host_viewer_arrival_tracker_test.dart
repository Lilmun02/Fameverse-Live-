import 'package:flutter_test/flutter_test.dart';
import 'package:fameverse_live/features/live/fv_host_viewer_arrival_tracker.dart';

FvHostViewerIdentity viewer(String userId, [String name = 'Viewer']) =>
    FvHostViewerIdentity(userId: userId, displayName: name);

void main() {
  final epoch = DateTime.utc(2026, 11, 13, 20);

  test('first roster is baseline, never announces existing viewers', () {
    final tracker = FvHostViewerArrivalTracker();
    expect(
      tracker.observe(
        [viewer('host'), viewer('v1', 'Soso')],
        hostUserId: 'host',
        now: epoch,
      ),
      isEmpty,
    );
    expect(
      tracker.observe(
        [viewer('host'), viewer('v1', 'Soso')],
        hostUserId: 'host',
        now: epoch.add(const Duration(seconds: 1)),
      ),
      isEmpty,
    );
  });

  test('announces a new viewer exactly once across repeated snapshots', () {
    final tracker = FvHostViewerArrivalTracker();
    tracker.observe([viewer('host')], hostUserId: 'host', now: epoch);
    final first = tracker.observe(
      [viewer('host'), viewer('v1', 'Soso')],
      hostUserId: 'host',
      now: epoch.add(const Duration(seconds: 2)),
    );
    expect(first.map((v) => v.displayName).toList(), ['Soso']);
    expect(
      tracker.observe(
        [viewer('host'), viewer('v1', 'Soso')],
        hostUserId: 'host',
        now: epoch.add(const Duration(seconds: 6)),
      ),
      isEmpty,
    );
  });

  test('brief reconnect is deduped, genuine later reentr
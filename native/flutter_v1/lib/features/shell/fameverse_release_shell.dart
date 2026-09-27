import 'package:flutter/material.dart';

import '../../data/fameverse_backend.dart';
import '../../data/fameverse_live_backend.dart';
import 'fameverse_shell_build16.dart';

/// Sep-27 release wrapper.
///
/// Release-only controls now live on the Profile surface instead of floating
/// over Home. Access policy and beta unlock state are owned by the product shell
/// so owner/admin bypasses and First Verse tester locks are applied in one place.
class FameverseReleaseShell extends StatelessWidget {
  const FameverseReleaseShell({
    required this.backend,
    required this.liveBackend,
    required this.identity,
    super.key,
  });

  final FameverseBackend backend;
  final FameverseLiveBackend liveBackend;
  final FvIdentity identity;

  @override
  Widget build(BuildContext context) {
    return FameverseBuild16Shell(
      backend: backend,
      liveBackend: liveBackend,
      identity: identity,
    );
  }
}

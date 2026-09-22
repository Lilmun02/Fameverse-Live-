from pathlib import Path

path = Path('native/flutter_v1/lib/features/live/livekit_live_screen.dart')
text = path.read_text()


def must_replace(old: str, new: str, label: str, count: int = 1) -> None:
    global text
    if text.count(old) < count:
        raise SystemExit(f'missing expected LiveKit block: {label}')
    text = text.replace(old, new, count)

must_replace(
    '  final Room _mediaRoom = Room();',
    '''  final Room _mediaRoom = Room(
    roomOptions: const RoomOptions(
      adaptiveStream: true,
      dynacast: true,
      defaultCameraCaptureOptions: _fameverseCameraOptions,
    ),
  );''',
    'host room constructor',
)

must_replace(
    '  final Room _mediaRoom = Room();',
    '''  final Room _mediaRoom = Room(
    roomOptions: const RoomOptions(adaptiveStream: true, dynacast: true),
  );''',
    'viewer room constructor',
)

must_replace(
    '''      await _mediaRoom.connect(
        widget.credentials.serverUrl,
        widget.credentials.participantToken,
        roomOptions: const RoomOptions(
          adaptiveStream: true,
          dynacast: true,
          defaultCameraCaptureOptions: _fameverseCameraOptions,
        ),
      );
      await _mediaRoom.localParticipant.setCameraEnabled(
        true,
        cameraCaptureOptions: _fameverseCameraOptions,
      );
      await _mediaRoom.localParticipant.setMicrophoneEnabled(true);''',
    '''      await _mediaRoom.connect(
        widget.credentials.serverUrl,
        widget.credentials.participantToken,
      );
      final localParticipant = _mediaRoom.localParticipant;
      if (localParticipant == null) {
        throw StateError('livekit-local-participant-missing');
      }
      await localParticipant.setCameraEnabled(
        true,
        cameraCaptureOptions: _fameverseCameraOptions,
      );
      await localParticipant.setMicrophoneEnabled(true);''',
    'host connect and publish',
)

must_replace(
    '''  LocalVideoTrack? get _localVideoTrack {
    for (final publication
        in _mediaRoom.localParticipant.videoTrackPublications) {''',
    '''  LocalVideoTrack? get _localVideoTrack {
    final localParticipant = _mediaRoom.localParticipant;
    if (localParticipant == null) return null;
    for (final publication in localParticipant.videoTrackPublications) {''',
    'local video getter',
)

must_replace(
    '''    try {
      await _mediaRoom.localParticipant.setMicrophoneEnabled(next);
      if (mounted) setState(() => _micEnabled = next);''',
    '''    try {
      final localParticipant = _mediaRoom.localParticipant;
      if (localParticipant == null) return;
      await localParticipant.setMicrophoneEnabled(next);
      if (mounted) setState(() => _micEnabled = next);''',
    'microphone toggle',
)

must_replace(
    '''    try {
      await _mediaRoom.localParticipant.setCameraEnabled(
        next,''',
    '''    try {
      final localParticipant = _mediaRoom.localParticipant;
      if (localParticipant == null) return;
      await localParticipant.setCameraEnabled(
        next,''',
    'camera toggle',
)

must_replace(
    '''      await _mediaRoom.connect(
        credentials.serverUrl,
        credentials.participantToken,
        roomOptions: const RoomOptions(adaptiveStream: true, dynacast: true),
      );''',
    '''      await _mediaRoom.connect(
        credentials.serverUrl,
        credentials.participantToken,
      );''',
    'viewer connect',
)

path.write_text(text)

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart';

import '../../data/fameverse_backend.dart';
import '../../data/fameverse_live_backend.dart';

const _fameverseCameraOptions = CameraCaptureOptions(
  cameraPosition: CameraPosition.front,
  params: VideoParametersPresets.h720_169,
);

class NativeHostLiveScreen extends StatefulWidget {
  const NativeHostLiveScreen({
    required this.liveBackend,
    required this.identity,
    required this.room,
    required this.credentials,
    super.key,
  });

  final FameverseLiveBackend liveBackend;
  final FvIdentity identity;
  final FvLiveRoom room;
  final FvLiveCredentials credentials;

  @override
  State<NativeHostLiveScreen> createState() => _NativeHostLiveScreenState();
}

class _NativeHostLiveScreenState extends State<NativeHostLiveScreen> {
  final Room _mediaRoom = Room();
  Timer? _heartbeat;
  bool _connecting = true;
  bool _ending = false;
  bool _ended = false;
  bool _micEnabled = true;
  bool _cameraEnabled = true;
  CameraPosition _cameraPosition = CameraPosition.front;
  String? _error;

  @override
  void initState() {
    super.initState();
    _mediaRoom.addListener(_onRoomChanged);
    unawaited(_connect());
  }

  void _onRoomChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _connect() async {
    try {
      await _mediaRoom.connect(
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
      await _mediaRoom.localParticipant.setMicrophoneEnabled(true);
      _heartbeat = Timer.periodic(const Duration(seconds: 15), (_) {
        unawaited(
          widget.liveBackend.heartbeatLiveRoom(
            roomId: widget.room.id,
            hostUserId: widget.identity.id,
          ),
        );
      });
      if (mounted) setState(() => _connecting = false);
    } catch (error) {
      await _markRoomEnded();
      if (!mounted) return;
      setState(() {
        _connecting = false;
        _error = 'Could not start the live broadcast. ${_friendlyError(error)}';
      });
    }
  }

  LocalVideoTrack? get _localVideoTrack {
    for (final publication
        in _mediaRoom.localParticipant.videoTrackPublications) {
      final track = publication.track;
      if (track != null) return track;
    }
    return null;
  }

  Future<void> _flipCamera() async {
    if (_connecting || _ending || !_cameraEnabled) return;
    final track = _localVideoTrack;
    if (track == null) return;
    final next = _cameraPosition == CameraPosition.front
        ? CameraPosition.back
        : CameraPosition.front;
    try {
      await track.restartTrack(
        CameraCaptureOptions(
          cameraPosition: next,
          params: VideoParametersPresets.h720_169,
        ),
      );
      if (mounted) setState(() => _cameraPosition = next);
    } catch (error) {
      if (mounted) _showMessage('Camera flip failed: ${_friendlyError(error)}');
    }
  }

  Future<void> _toggleMicrophone() async {
    if (_connecting || _ending) return;
    final next = !_micEnabled;
    try {
      await _mediaRoom.localParticipant.setMicrophoneEnabled(next);
      if (mounted) setState(() => _micEnabled = next);
    } catch (error) {
      if (mounted) _showMessage('Microphone change failed.');
    }
  }

  Future<void> _toggleCamera() async {
    if (_connecting || _ending) return;
    final next = !_cameraEnabled;
    try {
      await _mediaRoom.localParticipant.setCameraEnabled(
        next,
        cameraCaptureOptions: CameraCaptureOptions(
          cameraPosition: _cameraPosition,
          params: VideoParametersPresets.h720_169,
        ),
      );
      if (mounted) setState(() => _cameraEnabled = next);
    } catch (error) {
      if (mounted) _showMessage('Camera change failed.');
    }
  }

  Future<void> _markRoomEnded() async {
    if (_ended) return;
    _ended = true;
    _heartbeat?.cancel();
    try {
      await widget.liveBackend.endLiveRoom(
        roomId: widget.room.id,
        hostUserId: widget.identity.id,
      );
    } catch (_) {}
  }

  Future<void> _endLive() async {
    if (_ending) return;
    setState(() => _ending = true);
    await _markRoomEnded();
    try {
      await _mediaRoom.disconnect();
    } catch (_) {}
    if (mounted) Navigator.of(context).pop(true);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    _heartbeat?.cancel();
    _mediaRoom.removeListener(_onRoomChanged);
    if (!_ended) unawaited(_markRoomEnded());
    unawaited(_mediaRoom.disconnect().catchError((_) {}));
    unawaited(_mediaRoom.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final track = _localVideoTrack;
    final viewers = _mediaRoom.remoteParticipants.length;

    return PopScope(
      canPop: _ended,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && !_ending) unawaited(_endLive());
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          fit: StackFit.expand,
          children: [
            if (track != null && _cameraEnabled)
              VideoTrackRenderer(
                track,
                fit: VideoViewFit.cover,
                mirrorMode: VideoViewMirrorMode.auto,
              )
            else
              const _LiveBackground(icon: Icons.videocam_off_rounded),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: .62),
                    Colors.transparent,
                    Colors.black.withValues(alpha: .82),
                  ],
                  stops: const [0, .44, 1],
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF315F),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Text(
                            'LIVE',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              letterSpacing: .8,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.room.host.displayName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              Text(
                                '$viewers watching',
                                style: const TextStyle(
                                  color: Color(0xFFD1C7D7),
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        FilledButton(
                          key: const Key('native-end-live'),
                          onPressed: _ending ? null : _endLive,
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFFD5284D),
                          ),
                          child: Text(_ending ? 'Ending…' : 'End'),
                        ),
                      ],
                    ),
                    const Spacer(),
                    if (_connecting)
                      const _LiveStatusCard(
                        icon: Icons.wifi_tethering_rounded,
                        text: 'Connecting your broadcast…',
                      ),
                    if (_error != null)
                      _LiveStatusCard(
                        icon: Icons.error_outline_rounded,
                        text: _error!,
                      ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        widget.room.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _RoundLiveButton(
                          key: const Key('native-live-flip'),
                          icon: Icons.cameraswitch_rounded,
                          label: 'Flip',
                          onPressed: _connecting || _ending || !_cameraEnabled
                              ? null
                              : _flipCamera,
                        ),
                        const SizedBox(width: 16),
                        _RoundLiveButton(
                          key: const Key('native-live-mic'),
                          icon: _micEnabled
                              ? Icons.mic_rounded
                              : Icons.mic_off_rounded,
                          label: _micEnabled ? 'Mute' : 'Unmute',
                          onPressed: _connecting || _ending
                              ? null
                              : _toggleMicrophone,
                        ),
                        const SizedBox(width: 16),
                        _RoundLiveButton(
                          key: const Key('native-live-camera'),
                          icon: _cameraEnabled
                              ? Icons.videocam_rounded
                              : Icons.videocam_off_rounded,
                          label: _cameraEnabled ? 'Camera' : 'Camera on',
                          onPressed: _connecting || _ending
                              ? null
                              : _toggleCamera,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class NativeViewerLiveScreen extends StatefulWidget {
  const NativeViewerLiveScreen({
    required this.liveBackend,
    required this.room,
    super.key,
  });

  final FameverseLiveBackend liveBackend;
  final FvLiveRoom room;

  @override
  State<NativeViewerLiveScreen> createState() => _NativeViewerLiveScreenState();
}

class _NativeViewerLiveScreenState extends State<NativeViewerLiveScreen> {
  final Room _mediaRoom = Room();
  bool _connecting = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _mediaRoom.addListener(_onRoomChanged);
    unawaited(_connect());
  }

  void _onRoomChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _connect() async {
    try {
      final credentials = await widget.liveBackend.issueLiveCredentials(
        roomId: widget.room.id,
        role: 'viewer',
      );
      await _mediaRoom.connect(
        credentials.serverUrl,
        credentials.participantToken,
        roomOptions: const RoomOptions(adaptiveStream: true, dynacast: true),
      );
      if (mounted) setState(() => _connecting = false);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _connecting = false;
        _error = 'Could not join this live. ${_friendlyError(error)}';
      });
    }
  }

  RemoteVideoTrack? get _remoteVideoTrack {
    for (final participant in _mediaRoom.remoteParticipants.values) {
      for (final publication in participant.videoTrackPublications) {
        final track = publication.track;
        if (track != null) return track;
      }
    }
    return null;
  }

  @override
  void dispose() {
    _mediaRoom.removeListener(_onRoomChanged);
    unawaited(_mediaRoom.disconnect().catchError((_) {}));
    unawaited(_mediaRoom.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final track = _remoteVideoTrack;
    final roomCount = _mediaRoom.remoteParticipants.length + 1;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (track != null)
            VideoTrackRenderer(track, fit: VideoViewFit.cover)
          else
            const _LiveBackground(icon: Icons.wifi_tethering_rounded),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: .62),
                  Colors.transparent,
                  Colors.black.withValues(alpha: .78),
                ],
                stops: const [0, .45, 1],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton.filledTonal(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.arrow_back_rounded),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF315F),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Text(
                          'LIVE',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.room.host.displayName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            Text(
                              '$roomCount in room',
                              style: const TextStyle(
                                color: Color(0xFFD1C7D7),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  if (_connecting)
                    const _LiveStatusCard(
                      icon: Icons.wifi_tethering_rounded,
                      text: 'Joining live…',
                    ),
                  if (!_connecting && track == null && _error == null)
                    const _LiveStatusCard(
                      icon: Icons.hourglass_top_rounded,
                      text: 'Waiting for the host video…',
                    ),
                  if (_error != null)
                    _LiveStatusCard(
                      icon: Icons.error_outline_rounded,
                      text: _error!,
                    ),
                  const SizedBox(height: 12),
                  Text(
                    widget.room.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.room.host.handle,
                    style: const TextStyle(color: Color(0xFFD1C7D7)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundLiveButton extends StatelessWidget {
  const _RoundLiveButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    super.key,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton.filledTonal(
          onPressed: onPressed,
          icon: Icon(icon),
          iconSize: 24,
          padding: const EdgeInsets.all(15),
        ),
        const SizedBox(height: 5),
        Text(label, style: const TextStyle(fontSize: 10)),
      ],
    );
  }
}

class _LiveStatusCard extends StatelessWidget {
  const _LiveStatusCard({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: .55),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: .12)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 12, height: 1.3),
            ),
          ),
        ],
      ),
    );
  }
}

class _LiveBackground extends StatelessWidget {
  const _LiveBackground({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(.65, -.45),
          radius: 1.2,
          colors: [Color(0xFF4A1B70), Color(0xFF120A19), Colors.black],
        ),
      ),
      child: Center(
        child: Icon(icon, size: 74, color: Colors.white.withValues(alpha: .2)),
      ),
    );
  }
}

String _friendlyError(Object error) {
  final text = error.toString();
  if (text.contains('livekit-not-configured')) {
    return 'Live media is waiting on the Fameverse LiveKit server credentials.';
  }
  if (text.contains('permission')) {
    return 'Check camera and microphone permission in iPhone Settings.';
  }
  return 'Please try again.';
}

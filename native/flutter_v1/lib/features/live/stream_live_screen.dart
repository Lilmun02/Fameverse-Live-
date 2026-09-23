import 'dart:async';

import 'package:flutter/material.dart';
import 'package:stream_video_flutter/stream_video_flutter.dart';

import '../../data/fameverse_backend.dart';
import '../../data/fameverse_live_backend.dart';

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
  Call? _call;
  Timer? _heartbeat;
  bool _connecting = true;
  bool _ending = false;
  bool _ended = false;
  bool _micEnabled = true;
  bool _cameraEnabled = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    unawaited(_connect());
  }

  Future<void> _connect() async {
    try {
      await StreamVideo.reset(disconnect: true);
      final client = StreamVideo(
        widget.credentials.apiKey,
        user: User.regular(
          userId: widget.credentials.userId,
          name: widget.room.host.displayName,
        ),
        userToken: widget.credentials.userToken,
        options: StreamVideoOptions(autoConnect: false),
      );

      _requireSuccess(
        await client.connect(registerPushDevice: false),
        'Could not connect to Stream Video',
      );

      final call = client.makeCall(
        callType: StreamCallType.liveStream(),
        id: widget.credentials.callId,
      );
      _call = call;

      _requireSuccess(
        await call.getOrCreate(
          members: [
            MemberRequest(userId: widget.credentials.userId, role: 'host'),
          ],
        ),
        'Could not create the livestream',
      );
      _requireSuccess(
        await call.join(
          connectOptions: CallConnectOptions(
            camera: TrackOption.enabled(),
            microphone: TrackOption.enabled(),
            cameraFacingMode: FacingMode.user,
          ),
          hintHighScaleLivestreamPublisher: true,
        ),
        'Could not join the livestream',
      );
      _requireSuccess(await call.goLive(), 'Could not start the livestream');

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
      await _disposeTransport();
      if (!mounted) return;
      setState(() {
        _connecting = false;
        _error = 'Could not start the live broadcast. ${_friendlyError(error)}';
      });
    }
  }

  Future<void> _flipCamera() async {
    final call = _call;
    if (call == null || _connecting || _ending || !_cameraEnabled) return;
    try {
      _requireSuccess(await call.flipCamera(), 'Camera flip failed');
    } catch (error) {
      if (mounted) _showMessage(_friendlyError(error));
    }
  }

  Future<void> _toggleMicrophone() async {
    final call = _call;
    if (call == null || _connecting || _ending) return;
    final next = !_micEnabled;
    try {
      _requireSuccess(
        await call.setMicrophoneEnabled(enabled: next),
        'Microphone change failed',
      );
      if (mounted) setState(() => _micEnabled = next);
    } catch (_) {
      if (mounted) _showMessage('Microphone change failed.');
    }
  }

  Future<void> _toggleCamera() async {
    final call = _call;
    if (call == null || _connecting || _ending) return;
    final next = !_cameraEnabled;
    try {
      _requireSuccess(
        await call.setCameraEnabled(enabled: next),
        'Camera change failed',
      );
      if (mounted) setState(() => _cameraEnabled = next);
    } catch (_) {
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

  Future<void> _disposeTransport() async {
    final call = _call;
    _call = null;
    if (call != null) {
      try {
        await call.leave();
      } catch (_) {}
    }
    try {
      await StreamVideo.reset(disconnect: true);
    } catch (_) {}
  }

  Future<void> _endLive() async {
    if (_ending) return;
    setState(() => _ending = true);
    final call = _call;
    if (call != null) {
      try {
        await call.stopLive();
      } catch (_) {}
      try {
        await call.end(reason: 'host_ended');
      } catch (_) {}
    }
    await _markRoomEnded();
    await _disposeTransport();
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
    if (!_ended) unawaited(_markRoomEnded());
    unawaited(_disposeTransport());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final call = _call;
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
            if (call != null)
              PartialCallStateBuilder<CallParticipantState?>(
                call: call,
                selector: (state) => state.localParticipant,
                builder: (context, participant) {
                  if (participant == null || !_cameraEnabled) {
                    return const _LiveBackground(
                      icon: Icons.videocam_off_rounded,
                    );
                  }
                  return StreamCallParticipant(
                    call: call,
                    participant: participant,
                    videoFit: VideoFit.cover,
                    showConnectionQualityIndicator: false,
                    showParticipantLabel: false,
                    showSpeakerBorder: false,
                  );
                },
              )
            else
              const _LiveBackground(icon: Icons.videocam_off_rounded),
            const _LiveGradient(),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const _LiveBadge(),
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
                              if (call != null)
                                PartialCallStateBuilder<int>(
                                  call: call,
                                  selector: (state) =>
                                      state.callParticipants.length,
                                  builder: (context, count) {
                                    final viewers = count > 0 ? count - 1 : 0;
                                    return Text(
                                      '$viewers watching',
                                      style: const TextStyle(
                                        color: Color(0xFFD1C7D7),
                                        fontSize: 11,
                                      ),
                                    );
                                  },
                                )
                              else
                                const Text(
                                  '0 watching',
                                  style: TextStyle(
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
  Call? _call;
  bool _connecting = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    unawaited(_connect());
  }

  Future<void> _connect() async {
    try {
      final credentials = await widget.liveBackend.issueLiveCredentials(
        roomId: widget.room.id,
        role: 'viewer',
      );
      await StreamVideo.reset(disconnect: true);
      final client = StreamVideo(
        credentials.apiKey,
        user: User.regular(
          userId: credentials.userId,
          name: 'Fameverse Viewer',
        ),
        userToken: credentials.userToken,
        options: StreamVideoOptions(autoConnect: false),
      );
      _requireSuccess(
        await client.connect(registerPushDevice: false),
        'Could not connect to Stream Video',
      );
      final call = client.makeCall(
        callType: StreamCallType.liveStream(),
        id: credentials.callId,
      );
      _call = call;
      _requireSuccess(
        await call.join(
          connectOptions: CallConnectOptions(
            camera: TrackOption.disabled(),
            microphone: TrackOption.disabled(),
          ),
        ),
        'Could not join the livestream',
      );
      if (mounted) setState(() => _connecting = false);
    } catch (error) {
      await _disposeTransport();
      if (!mounted) return;
      setState(() {
        _connecting = false;
        _error = 'Could not join this live. ${_friendlyError(error)}';
      });
    }
  }

  Future<void> _disposeTransport() async {
    final call = _call;
    _call = null;
    if (call != null) {
      try {
        await call.leave();
      } catch (_) {}
    }
    try {
      await StreamVideo.reset(disconnect: true);
    } catch (_) {}
  }

  @override
  void dispose() {
    unawaited(_disposeTransport());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final call = _call;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (call != null)
            PartialCallStateBuilder<List<CallParticipantState>>(
              call: call,
              selector: (state) => state.callParticipants,
              builder: (context, participants) {
                CallParticipantState? host;
                for (final participant in participants) {
                  if (participant.roles.contains('host') &&
                      participant.isVideoEnabled) {
                    host = participant;
                    break;
                  }
                }
                if (host == null) {
                  for (final participant in participants) {
                    if (!participant.isLocal && participant.isVideoEnabled) {
                      host = participant;
                      break;
                    }
                  }
                }
                if (host == null) {
                  return const _LiveBackground(
                    icon: Icons.wifi_tethering_rounded,
                  );
                }
                return StreamCallParticipant(
                  call: call,
                  participant: host,
                  videoFit: VideoFit.cover,
                  showConnectionQualityIndicator: false,
                  showParticipantLabel: false,
                  showSpeakerBorder: false,
                );
              },
            )
          else
            const _LiveBackground(icon: Icons.wifi_tethering_rounded),
          const _LiveGradient(),
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
                      const _LiveBadge(),
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
                            if (call != null)
                              PartialCallStateBuilder<int>(
                                call: call,
                                selector: (state) =>
                                    state.callParticipants.length,
                                builder: (context, count) => Text(
                                  '$count in room',
                                  style: const TextStyle(
                                    color: Color(0xFFD1C7D7),
                                    fontSize: 11,
                                  ),
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

void _requireSuccess<T>(Result<T> result, String message) {
  if (result.isFailure) {
    throw StateError('$message: ${result.getErrorOrNull()}');
  }
}

String _friendlyError(Object error) {
  final text = error.toString();
  if (text.contains('stream-not-configured')) {
    return 'Stream Video credentials are not configured yet.';
  }
  if (text.toLowerCase().contains('permission')) {
    return 'Check camera and microphone permissions in Settings.';
  }
  return 'Please try again.';
}

class _LiveGradient extends StatelessWidget {
  const _LiveGradient();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
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
    );
  }
}

class _LiveBadge extends StatelessWidget {
  const _LiveBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFF315F),
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Text(
        'LIVE',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: .8,
        ),
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
          center: Alignment(.6, -.4),
          radius: 1.2,
          colors: [Color(0xFF351453), Color(0xFF100914), Colors.black],
        ),
      ),
      child: Center(
        child: Icon(icon, size: 76, color: Colors.white.withValues(alpha: .18)),
      ),
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
        color: Colors.black.withValues(alpha: .54),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 9),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

class _RoundLiveButton extends StatelessWidget {
  const _RoundLiveButton({
    required super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
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
          style: IconButton.styleFrom(minimumSize: const Size(50, 50)),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 11)),
      ],
    );
  }
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart';

import '../../data/fameverse_backend.dart';
import '../../data/fameverse_live_backend.dart';
import 'livekit_live_screen.dart';

class NativeCameraScreen extends StatefulWidget {
  const NativeCameraScreen({
    required this.liveBackend,
    required this.identity,
    required this.profile,
    required this.onLiveEnded,
    super.key,
  });

  final FameverseLiveBackend liveBackend;
  final FvIdentity identity;
  final FvProfile profile;
  final Future<void> Function() onLiveEnded;

  @override
  State<NativeCameraScreen> createState() => _NativeCameraScreenState();
}

class _NativeCameraScreenState extends State<NativeCameraScreen> {
  final TextEditingController _title = TextEditingController();
  LocalVideoTrack? _previewTrack;
  CameraPosition _cameraPosition = CameraPosition.front;
  bool _busy = false;
  bool _liveBusy = false;
  String? _error;

  @override
  void dispose() {
    _title.dispose();
    final track = _previewTrack;
    _previewTrack = null;
    if (track != null) unawaited(track.dispose());
    super.dispose();
  }

  Future<void> _startPreview() async {
    if (_busy || _previewTrack != null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final track = await LocalVideoTrack.createCameraTrack(
        CameraCaptureOptions(
          cameraPosition: _cameraPosition,
          params: VideoParametersPresets.h720_169,
        ),
      );
      if (!mounted) {
        await track.dispose();
        return;
      }
      setState(() => _previewTrack = track);
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = _cameraError(error);
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _stopPreview() async {
    if (_busy) return;
    final track = _previewTrack;
    if (track == null) return;
    setState(() {
      _previewTrack = null;
      _error = null;
    });
    await track.dispose();
  }

  Future<void> _flipCamera() async {
    final track = _previewTrack;
    if (track == null || _busy) return;
    final next = _cameraPosition == CameraPosition.front
        ? CameraPosition.back
        : CameraPosition.front;
    setState(() => _busy = true);
    try {
      await track.restartTrack(
        CameraCaptureOptions(
          cameraPosition: next,
          params: VideoParametersPresets.h720_169,
        ),
      );
      if (mounted) setState(() => _cameraPosition = next);
    } catch (error) {
      if (mounted) setState(() => _error = _cameraError(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _goLive() async {
    if (_liveBusy) return;
    if (_previewTrack == null) {
      await _startPreview();
      if (_previewTrack == null) return;
    }

    setState(() {
      _liveBusy = true;
      _error = null;
    });

    FvLiveRoom? room;
    try {
      await _stopPreview();
      room = await widget.liveBackend.startLiveRoom(
        identity: widget.identity,
        profile: widget.profile,
        title: _title.text,
      );
      final credentials = await widget.liveBackend.issueLiveCredentials(
        roomId: room.id,
        role: 'host',
      );
      if (!mounted) return;
      await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (context) => NativeHostLiveScreen(
            liveBackend: widget.liveBackend,
            identity: widget.identity,
            room: room!,
            credentials: credentials,
            initialCameraPosition: _cameraPosition,
          ),
        ),
      );
      if (!mounted) return;
      await widget.onLiveEnded();
    } catch (error) {
      if (room != null) {
        try {
          await widget.liveBackend.endLiveRoom(
            roomId: room.id,
            hostUserId: widget.identity.id,
          );
        } catch (_) {}
      }
      if (!mounted) return;
      final text = error.toString();
      setState(() {
        _error = text.contains('livekit-not-configured')
            ? 'Live media is wired, but the LiveKit server credentials still need to be connected before testers can broadcast.'
            : 'Could not start your live right now. Please try again.';
      });
    } finally {
      if (mounted) setState(() => _liveBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final track = _previewTrack;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (track != null)
            VideoTrackRenderer(
              track,
              fit: VideoViewFit.cover,
              mirrorMode: VideoViewMirrorMode.auto,
            )
          else
            const _CameraIdleBackground(),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: .58),
                  Colors.transparent,
                  Colors.black.withValues(alpha: .86),
                ],
                stops: const [0, .42, 1],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6D2CFF),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Text(
                          'GO LIVE',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: .8,
                          ),
                        ),
                      ),
                      const Spacer(),
                      if (track != null)
                        IconButton.filledTonal(
                          key: const Key('camera-off'),
                          onPressed: _busy || _liveBusy ? null : _stopPreview,
                          icon: const Icon(Icons.videocam_off_rounded),
                          tooltip: 'Camera off',
                        ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    track == null ? 'Set up your live' : 'Ready to go live',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Native Fameverse camera + microphone. Viewers join the same realtime broadcast room.',
                    style: TextStyle(color: Color(0xFFE0D8E8), height: 1.35),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    key: const Key('native-live-title'),
                    controller: _title,
                    maxLength: 120,
                    decoration: InputDecoration(
                      hintText: 'What are you live about?',
                      filled: true,
                      fillColor: Colors.black.withValues(alpha: .48),
                      counterText: '',
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2D1827),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        _error!,
                        key: const Key('camera-error'),
                        style: const TextStyle(color: Color(0xFFFFCFDF)),
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          key: const Key('camera-primary'),
                          onPressed: _busy || _liveBusy
                              ? null
                              : track == null
                              ? _startPreview
                              : _flipCamera,
                          icon: _busy
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Icon(
                                  track == null
                                      ? Icons.videocam_rounded
                                      : Icons.cameraswitch_rounded,
                                ),
                          label: Text(
                            track == null ? 'Start camera' : 'Flip camera',
                          ),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(52),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  FilledButton.icon(
                    key: const Key('native-go-live'),
                    onPressed: _busy || _liveBusy ? null : _goLive,
                    icon: _liveBusy
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.wifi_tethering_rounded),
                    label: Text(_liveBusy ? 'Starting live…' : 'Go Live'),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFFF315F),
                      minimumSize: const Size.fromHeight(54),
                    ),
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

class _CameraIdleBackground extends StatelessWidget {
  const _CameraIdleBackground();

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
        child: Icon(
          Icons.videocam_rounded,
          size: 74,
          color: Colors.white.withValues(alpha: .2),
        ),
      ),
    );
  }
}

String _cameraError(Object error) {
  final text = error.toString().toLowerCase();
  if (text.contains('permission') || text.contains('denied')) {
    return 'Camera permission is off. Allow camera access in iPhone Settings.';
  }
  return 'Could not start the camera.';
}

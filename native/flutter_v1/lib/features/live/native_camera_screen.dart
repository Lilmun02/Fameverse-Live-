import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../../data/fameverse_backend.dart';
import '../../data/fameverse_live_backend.dart';
import 'stream_live_screen.dart';

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
  CameraController? _controller;
  CameraLensDirection _lensDirection = CameraLensDirection.front;
  bool _busy = false;
  bool _liveBusy = false;
  String? _error;

  @override
  void dispose() {
    _title.dispose();
    final controller = _controller;
    _controller = null;
    if (controller != null) unawaited(controller.dispose());
    super.dispose();
  }

  Future<void> _openCamera(CameraLensDirection direction) async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) throw StateError('no-camera-available');

    CameraDescription selected = cameras.first;
    for (final camera in cameras) {
      if (camera.lensDirection == direction) {
        selected = camera;
        break;
      }
    }

    final controller = CameraController(
      selected,
      ResolutionPreset.high,
      enableAudio: false,
    );
    await controller.initialize();

    if (!mounted) {
      await controller.dispose();
      return;
    }

    final old = _controller;
    setState(() {
      _controller = controller;
      _lensDirection = selected.lensDirection;
    });
    if (old != null) await old.dispose();
  }

  Future<void> _startPreview() async {
    if (_busy || _controller != null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await _openCamera(_lensDirection);
    } catch (error) {
      if (mounted) setState(() => _error = _cameraError(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _stopPreview() async {
    if (_busy) return;
    final controller = _controller;
    if (controller == null) return;
    setState(() {
      _controller = null;
      _error = null;
    });
    await controller.dispose();
  }

  Future<void> _flipCamera() async {
    if (_busy || _controller == null) return;
    final next = _lensDirection == CameraLensDirection.front
        ? CameraLensDirection.back
        : CameraLensDirection.front;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final old = _controller;
      _controller = null;
      if (old != null) await old.dispose();
      await _openCamera(next);
    } catch (error) {
      if (mounted) setState(() => _error = _cameraError(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _goLive() async {
    if (_liveBusy) return;
    if (_controller == null) {
      await _startPreview();
      if (_controller == null) return;
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
        _error = text.contains('stream-not-configured')
            ? 'Stream Video is wired, but the Stream server credentials still need to be connected before testers can broadcast.'
            : 'Could not start your live right now. Please try again.';
      });
    } finally {
      if (mounted) setState(() => _liveBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (controller != null && controller.value.isInitialized)
            _CameraPreviewCover(controller: controller)
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
                      if (controller != null)
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
                    controller == null
                        ? 'Set up your live'
                        : 'Ready to go live',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Fameverse native camera preview. Stream Video carries the broadcast after you go live.',
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
                  FilledButton.icon(
                    key: const Key('camera-primary'),
                    onPressed: _busy || _liveBusy
                        ? null
                        : controller == null
                        ? _startPreview
                        : _flipCamera,
                    icon: _busy
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(
                            controller == null
                                ? Icons.videocam_rounded
                                : Icons.cameraswitch_rounded,
                          ),
                    label: Text(
                      controller == null ? 'Start camera' : 'Flip camera',
                    ),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                    ),
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

class _CameraPreviewCover extends StatelessWidget {
  const _CameraPreviewCover({required this.controller});

  final CameraController controller;

  @override
  Widget build(BuildContext context) {
    final size = controller.value.previewSize;
    if (size == null) return CameraPreview(controller);
    return SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: size.height,
          height: size.width,
          child: CameraPreview(controller),
        ),
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
  if (text.contains('no-camera')) return 'No camera was found on this device.';
  return 'Could not start the camera.';
}

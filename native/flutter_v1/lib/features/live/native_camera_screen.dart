import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class NativeCameraScreen extends StatefulWidget {
  const NativeCameraScreen({super.key});

  @override
  State<NativeCameraScreen> createState() => _NativeCameraScreenState();
}

class _NativeCameraScreenState extends State<NativeCameraScreen> {
  CameraController? _controller;
  List<CameraDescription> _cameras = const [];
  CameraLensDirection _lensDirection = CameraLensDirection.front;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _startCamera([CameraLensDirection? lens]) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      final cameras = _cameras.isEmpty ? await availableCameras() : _cameras;
      if (cameras.isEmpty) {
        throw CameraException(
          'no-camera',
          'No camera is available on this device.',
        );
      }
      final targetDirection = lens ?? _lensDirection;
      final target = cameras.firstWhere(
        (camera) => camera.lensDirection == targetDirection,
        orElse: () => cameras.first,
      );
      final next = CameraController(
        target,
        ResolutionPreset.high,
        enableAudio: false,
      );
      await next.initialize();
      if (!mounted) {
        await next.dispose();
        return;
      }
      final previous = _controller;
      setState(() {
        _cameras = cameras;
        _controller = next;
        _lensDirection = target.lensDirection;
      });
      await previous?.dispose();
    } on CameraException catch (error) {
      if (mounted) {
        setState(() {
          _error = switch (error.code) {
            'CameraAccessDenied' =>
              'Camera permission is off. Allow camera access in iPhone Settings.',
            _ => error.description ?? 'Could not start the camera.',
          };
        });
      }
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not start the camera.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _flipCamera() async {
    if (_controller == null || _busy || _cameras.length < 2) return;
    final nextDirection = _lensDirection == CameraLensDirection.front
        ? CameraLensDirection.back
        : CameraLensDirection.front;
    await _startCamera(nextDirection);
  }

  Future<void> _stopCamera() async {
    if (_busy) return;
    final current = _controller;
    if (current == null) return;
    setState(() {
      _controller = null;
      _error = null;
    });
    await current.dispose();
  }

  Widget _cameraPreview(CameraController controller) {
    final previewSize = controller.value.previewSize;
    if (previewSize == null) return const SizedBox.expand();
    return ClipRect(
      child: SizedBox.expand(
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: previewSize.height,
            height: previewSize.width,
            child: CameraPreview(controller),
          ),
        ),
      ),
    );
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
            _cameraPreview(controller)
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
                  Colors.black.withValues(alpha: .82),
                ],
                stops: const [0, .45, 1],
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
                          'LIVE SETUP',
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
                          onPressed: _busy ? null : _stopCamera,
                          icon: const Icon(Icons.videocam_off_rounded),
                          tooltip: 'Camera off',
                        ),
                    ],
                  ),
                  const Spacer(),
                  const Text(
                    'Native camera',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'This preview uses the iPhone camera stack, not the PWA video compositor.',
                    style: TextStyle(color: Color(0xFFE0D8E8), height: 1.35),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
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
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          key: const Key('camera-primary'),
                          onPressed: _busy
                              ? null
                              : controller == null
                              ? _startCamera
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
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Broadcast transport stays off until native viewer/host media parity is wired, so this build cannot create fake live rooms.',
                    style: TextStyle(
                      color: Color(0xFFAFA3B9),
                      fontSize: 12,
                      height: 1.35,
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

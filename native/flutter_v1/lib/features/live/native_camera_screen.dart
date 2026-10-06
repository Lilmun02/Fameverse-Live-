import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../../data/fameverse_backend.dart';
import '../../data/fameverse_live_backend.dart';
import 'native_live_components.dart';
import 'stream_live_screen.dart';
part 'native_camera_summary.part.dart';


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
  final TextEditingController _goal = TextEditingController();
  CameraController? _permissionProbe;
  bool _loadingDraft = true;
  bool _liveBusy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    unawaited(_loadDraft());
  }

  @override
  void dispose() {
    _title.dispose();
    _goal.dispose();
    final controller = _permissionProbe;
    _permissionProbe = null;
    if (controller != null) unawaited(controller.dispose());
    super.dispose();
  }

  Future<void> _loadDraft() async {
    try {
      final draft = await widget.liveBackend.loadLiveDraft(widget.identity.id);
      if (!mounted) return;
      _title.text = draft.title;
      _goal.text = draft.goal;
    } catch (_) {
      // Draft recovery never blocks Live setup.
    } finally {
      if (mounted) setState(() => _loadingDraft = false);
    }
  }

  Future<void> _resetLiveSetupAfterEnd() async {
    try {
      await widget.liveBackend.saveLiveDraft(
        userId: widget.identity.id,
        draft: FvLiveDraft.empty,
      );
    } catch (_) {
      // The creator must still be able to leave the ended Live cleanly.
    }
    if (!mounted) return;
    _title.clear();
    _goal.clear();
    setState(() => _error = null);
  }

  Future<void> _verifyCameraAccess() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) throw StateError('no-camera-available');

    CameraDescription selected = cameras.first;
    for (final camera in cameras) {
      if (camera.lensDirection == CameraLensDirection.front) {
        selected = camera;
        break;
      }
    }

    final controller = CameraController(
      selected,
      ResolutionPreset.high,
      enableAudio: true,
    );
    _permissionProbe = controller;
    await controller.initialize();
    _permissionProbe = null;
    await controller.dispose();
  }

  Future<bool> _confirmGoLive() async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Go live now?'),
        content: const Text(
          'Fameverse will turn on your camera and microphone and open this room to viewers.',
        ),
        actions: [
          TextButton(
            key: const Key('cancel-go-live-confirmation'),
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Not yet'),
          ),
          FilledButton(
            key: const Key('confirm-go-live'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFFF315F),
            ),
            child: const Text('Go Live'),
          ),
        ],
      ),
    );
    return confirmed == true;
  }

  Future<void> _goLive() async {
    if (_liveBusy) return;
    if (_title.text.trim().isEmpty) {
      setState(() => _error = 'Add a live title before you go live.');
      return;
    }

    final confirmed = await _confirmGoLive();
    if (!confirmed || !mounted) return;

    setState(() {
      _liveBusy = true;
      _error = null;
    });

    FvLiveRoom? room;
    try {
      final draft = FvLiveDraft(
        title: _title.text,
        goal: _goal.text,
        wishlistGiftIds: const [],
      );
      await widget.liveBackend.saveLiveDraft(
        userId: widget.identity.id,
        draft: draft,
      );

      // Request/check both camera and microphone before any Live room is opened.
      await _verifyCameraAccess();

      room = await widget.liveBackend.startLiveRoom(
        identity: widget.identity,
        profile: widget.profile,
        title: _title.text,
        goal: _goal.text,
        wishlistGiftIds: const [],
      );
      final credentials = await widget.liveBackend.issueLiveCredentials(
        roomId: room.id,
        role: 'host',
      );
      if (!mounted) return;

      final ended = await Navigator.of(context).push<bool>(
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

      if (ended == true) {
        await _resetLiveSetupAfterEnd();
      }
      await widget.onLiveEnded();
      if (ended == true && mounted) {
        await _showLastLiveSummary();
      }
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

      final text = error.toString().toLowerCase();
      setState(() {
        if (text.contains('stream-not-configured')) {
          _error = 'Stream Video server credentials are not configured.';
        } else if (text.contains('permission') || text.contains('denied')) {
          _error =
              'Camera or microphone permission is off. Allow access in iPhone Settings.';
        } else if (text.contains('no-camera')) {
          _error = 'No camera was found on this device.';
        } else {
          _error = 'Could not start your live right now. Please try again.';
        }
      });
    } finally {
      if (mounted) setState(() => _liveBusy = false);
    }
  }

  Future<void> _showLastLiveSummary() async {
    try {
      final history = await widget.liveBackend.loadCreatorLiveHistory(limit: 1);
      if (!mounted || history.isEmpty) return;
      await Navigator.of(context).push<void>(
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (context) => _NativeLiveSummaryScreen(live: history.first),
        ),
      );
    } catch (_) {
      // A summary failure never traps the creator after ending Live.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF23102E), Color(0xFF0D0911)],
          ),
        ),
        child: SafeArea(
          child: _loadingDraft
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 120),
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'LIVE',
                                style: TextStyle(
                                  color: Color(0xFFFF315F),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.4,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Set up your live',
                                style: TextStyle(
                                  fontSize: 30,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              SizedBox(height: 5),
                              Text(
                                'Give people a reason to join before the room opens.',
                                style: TextStyle(color: Color(0xFFBFB3C8)),
                              ),
                            ],
                          ),
                        ),
                        NativeProfileAvatar(
                          profile: widget.profile,
                          radius: 28,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF17101F),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Row(
                        children: [
                          NativeProfileAvatar(
                            profile: widget.profile,
                            radius: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.profile.displayName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                Text(
                                  widget.profile.handle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Color(0xFFAEA2B8),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      key: const Key('native-live-title'),
                      controller: _title,
                      maxLength: 80,
                      decoration: const InputDecoration(
                        labelText: 'Live title · Required',
                        hintText: 'What is this live about?',
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      key: const Key('native-live-goal'),
                      controller: _goal,
                      maxLength: 60,
                      decoration: const InputDecoration(
                        labelText: 'Live goal · Optional',
                        hintText: 'Example: 1,000 likes or 20 gifts',
                      ),
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
                    const Text(
                      'Camera and microphone permission is checked before your room opens. You will also confirm before Fameverse starts the broadcast.',
                      style: TextStyle(color: Color(0xFF9D92A6), fontSize: 11),
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      key: const Key('native-go-live'),
                      onPressed: _liveBusy ? null : _goLive,
                      icon: _liveBusy
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.wifi_tethering_rounded),
                      label: Text(_liveBusy ? 'Starting…' : 'Go Live'),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFFF315F),
                        minimumSize: const Size.fromHeight(54),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

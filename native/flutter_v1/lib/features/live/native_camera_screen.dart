import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../../data/fameverse_backend.dart';
import '../../data/fameverse_live_backend.dart';
import 'native_live_components.dart';
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
  final TextEditingController _goal = TextEditingController();
  final Set<String> _wishlist = <String>{};
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
      _wishlist
        ..clear()
        ..addAll(draft.wishlistGiftIds);
    } catch (_) {
      // Draft recovery never blocks Live setup.
    } finally {
      if (mounted) setState(() => _loadingDraft = false);
    }
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
      enableAudio: false,
    );
    _permissionProbe = controller;
    await controller.initialize();
    _permissionProbe = null;
    await controller.dispose();
  }

  Future<void> _goLive() async {
    if (_liveBusy) return;
    if (_title.text.trim().isEmpty) {
      setState(() => _error = 'Add a live title before you go live.');
      return;
    }

    setState(() {
      _liveBusy = true;
      _error = null;
    });

    FvLiveRoom? room;
    try {
      final draft = FvLiveDraft(
        title: _title.text,
        goal: _goal.text,
        wishlistGiftIds: _wishlist.toList(),
      );
      await widget.liveBackend.saveLiveDraft(
        userId: widget.identity.id,
        draft: draft,
      );
      await _verifyCameraAccess();
      room = await widget.liveBackend.startLiveRoom(
        identity: widget.identity,
        profile: widget.profile,
        title: _title.text,
        goal: _goal.text,
        wishlistGiftIds: _wishlist.toList(),
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
      await widget.onLiveEnded();
      if (ended == true && mounted) await _showLastLiveSummary();
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
          _error = 'Camera permission is off. Allow camera access in iPhone Settings.';
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
      final live = history.first;
      await showModalBottomSheet<void>(
        context: context,
        backgroundColor: const Color(0xFF17101F),
        builder: (context) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'LIVE ENDED',
                  style: TextStyle(
                    color: Color(0xFFFF4D77),
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  live.title,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    _SummaryStat(label: 'FameTaps', value: '${live.rawTaps}'),
                    const SizedBox(width: 10),
                    _SummaryStat(label: 'Gifts', value: '${live.giftCount}'),
                    const SizedBox(width: 10),
                    _SummaryStat(label: 'Test coins', value: '${live.giftCoins}'),
                  ],
                ),
                const SizedBox(height: 18),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
                  child: const Text('Done'),
                ),
              ],
            ),
          ),
        ),
      );
    } catch (_) {}
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
                        NativeProfileAvatar(profile: widget.profile, radius: 28),
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
                          NativeProfileAvatar(profile: widget.profile, radius: 20),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.profile.displayName,
                                style: const TextStyle(fontWeight: FontWeight.w900),
                              ),
                              Text(
                                widget.profile.handle,
                                style: const TextStyle(
                                  color: Color(0xFFAEA2B8),
                                  fontSize: 12,
                                ),
                              ),
                            ],
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
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        const Text(
                          'Wishlist gifts',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                        ),
                        const Spacer(),
                        Text(
                          'Optional · ${_wishlist.length} selected',
                          style: const TextStyle(
                            color: Color(0xFFBBA9C6),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Pick only gifts that actually exist in Fameverse.',
                      style: TextStyle(color: Color(0xFF958A9E), fontSize: 12),
                    ),
                    const SizedBox(height: 12),
                    ...fvGiftCatalog.map((gift) {
                      final selected = _wishlist.contains(gift.id);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => setState(() {
                            if (selected) {
                              _wishlist.remove(gift.id);
                            } else {
                              _wishlist.add(gift.id);
                            }
                          }),
                          child: Container(
                            padding: const EdgeInsets.all(13),
                            decoration: BoxDecoration(
                              color: selected
                                  ? const Color(0xFF322047)
                                  : const Color(0xFF17101F),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: selected
                                    ? const Color(0xFF9D55FF)
                                    : Colors.white10,
                              ),
                            ),
                            child: Row(
                              children: [
                                Text(gift.symbol, style: const TextStyle(fontSize: 26)),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        gift.label,
                                        style: const TextStyle(fontWeight: FontWeight.w800),
                                      ),
                                      Text(
                                        '${gift.cost} coin${gift.cost == 1 ? '' : 's'}',
                                        style: const TextStyle(
                                          color: Color(0xFFACA1B4),
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(selected ? Icons.check_circle : Icons.add_circle_outline),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
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
                      'Camera and microphone permission is requested only after you tap Go Live.',
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

class _SummaryStat extends StatelessWidget {
  const _SummaryStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF21172A),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(color: Color(0xFFA99EB0), fontSize: 10)),
          ],
        ),
      ),
    );
  }
}

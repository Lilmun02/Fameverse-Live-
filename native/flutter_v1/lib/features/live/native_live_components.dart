import 'dart:async';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../data/fameverse_backend.dart';
import '../../data/fameverse_live_backend.dart';
import 'native_gift_visual.dart';
import 'native_pocket_comet_gift.dart';

class FvLiveChatMessage {
  const FvLiveChatMessage({
    required this.id,
    required this.user,
    required this.text,
    this.userId,
    this.gifterLevel = 1,
    this.kind = 'comment',
    this.giftId,
    this.quantity = 1,
  });

  final String id;
  final String user;
  final String? userId;
  final int gifterLevel;
  final String text;
  final String kind;
  final String? giftId;
  final int quantity;
}

class FvGiftPlayback {
  const FvGiftPlayback({
    required this.gift,
    required this.quantity,
    required this.sender,
  });

  final FvGiftDefinition gift;
  final int quantity;
  final String sender;
}

class NativeGiftOverlay extends StatefulWidget {
  const NativeGiftOverlay({required this.playback, super.key});

  final FvGiftPlayback playback;

  @override
  State<NativeGiftOverlay> createState() => _NativeGiftOverlayState();
}

class _NativeGiftOverlayState extends State<NativeGiftOverlay> {
  VideoPlayerController? _controller;
  String? _loadedUrl;

  @override
  void initState() {
    super.initState();
    unawaited(_syncVideo());
  }

  @override
  void didUpdateWidget(covariant NativeGiftOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.playback.gift.videoUrl != widget.playback.gift.videoUrl ||
        oldWidget.playback.gift.id != widget.playback.gift.id) {
      unawaited(_syncVideo());
    }
  }

  Future<void> _syncVideo() async {
    final url = widget.playback.gift.videoUrl;
    if (url == null || url.isEmpty) {
      final previous = _controller;
      _controller = null;
      _loadedUrl = null;
      if (previous != null) await previous.dispose();
      if (mounted) setState(() {});
      return;
    }
    if (_loadedUrl == url && _controller != null) {
      await _controller!.seekTo(Duration.zero);
      await _controller!.play();
      return;
    }
    final next = VideoPlayerController.networkUrl(Uri.parse(url));
    try {
      await next.initialize();
      await next.setLooping(false);
      await next.setVolume(1);
      await next.play();
      final previous = _controller;
      _controller = next;
      _loadedUrl = url;
      if (previous != null) await previous.dispose();
      if (mounted) setState(() {});
    } catch (_) {
      await next.dispose();
    }
  }

  @override
  void dispose() {
    final controller = _controller;
    _controller = null;
    if (controller != null) unawaited(controller.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final playback = widget.playback;

    if (playback.gift.id == 'pocket-comet') {
      return Stack(
        fit: StackFit.expand,
        children: [
          NativePocketCometGift(sender: playback.sender),
          if (playback.quantity > 1)
            Positioned(
              left: 20,
              right: 20,
              bottom: 92,
              child: Text(
                '×${playback.quantity}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFFFFE7A2),
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  shadows: [Shadow(blurRadius: 10, color: Colors.black)],
                ),
              ),
            ),
        ],
      );
    }

    final controller = _controller;
    if (playback.gift.cinematic &&
        controller != null &&
        controller.value.isInitialized) {
      return IgnorePointer(
        child: Stack(
          fit: StackFit.expand,
          children: [
            Container(color: Colors.black.withValues(alpha: .28)),
            Center(
              child: AspectRatio(
                aspectRatio: controller.value.aspectRatio == 0
                    ? 1
                    : controller.value.aspectRatio,
                child: VideoPlayer(controller),
              ),
            ),
            Positioned(
              left: 20,
              right: 20,
              bottom: 110,
              child: Text(
                '${playback.sender} sent ${playback.gift.label}${playback.quantity > 1 ? ' ×${playback.quantity}' : ''}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  shadows: [Shadow(blurRadius: 8, color: Colors.black)],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return IgnorePointer(
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
          decoration: BoxDecoration(
            color: const Color(0xDD1C1227),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0x669D55FF)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(playback.gift.symbol, style: const TextStyle(fontSize: 54)),
              const SizedBox(height: 8),
              Text(
                '${playback.sender} sent ${playback.gift.label}',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              if (playback.quantity > 1)
                Text(
                  '×${playback.quantity}',
                  style: const TextStyle(
                    color: Color(0xFFCEB9FF),
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class NativeGiftTray extends StatefulWidget {
  const NativeGiftTray({
    required this.coins,
    required this.canRefill,
    required this.onSend,
    required this.onRefill,
    super.key,
  });

  final int coins;
  final bool canRefill;
  final Future<bool> Function(FvGiftDefinition gift, int quantity) onSend;
  final Future<void> Function() onRefill;

  @override
  State<NativeGiftTray> createState() => _NativeGiftTrayState();
}

class _NativeGiftTrayState extends State<NativeGiftTray> {
  String _category = 'all';
  String _selectedId = fvGiftCatalog.first.id;
  bool _sending = false;

  List<FvGiftDefinition> get _visible => _category == 'all'
      ? fvGiftCatalog
      : fvGiftCatalog.where((gift) => gift.category == _category).toList();

  FvGiftDefinition get _selected =>
      fvGiftById(_selectedId) ?? fvGiftCatalog.first;

  Future<void> _send(int quantity) async {
    if (_sending) return;
    setState(() => _sending = true);
    try {
      final accepted = await widget.onSend(_selected, quantity);
      if (accepted && mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _customAmount() async {
    var quantity = 1;
    final accepted = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF17101F),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            void setQuantity(int value) {
              setModalState(() => quantity = value.clamp(1, 100000));
            }

            return SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  20,
                  16,
                  20,
                  20 + MediaQuery.viewInsetsOf(context).bottom,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        NativeGiftTrayVisual(gift: _selected, size: 50),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Text(
                            _selected.label,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        IconButton.filledTonal(
                          onPressed: () => setQuantity(quantity - 1),
                          icon: const Icon(Icons.remove),
                        ),
                        Expanded(
                          child: TextFormField(
                            initialValue: '$quantity',
                            textAlign: TextAlign.center,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Quantity',
                            ),
                            onChanged: (value) {
                              final parsed = int.tryParse(value);
                              if (parsed != null) setQuantity(parsed);
                            },
                          ),
                        ),
                        IconButton.filledTonal(
                          onPressed: () => setQuantity(quantity + 1),
                          icon: const Icon(Icons.add),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      children: [5, 10, 25, 50]
                          .map(
                            (value) => ActionChip(
                              label: Text('×$value'),
                              onPressed: () => setQuantity(value),
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        const Text('Total cost'),
                        const Spacer(),
                        Text(
                          '🪙 ${_selected.cost * quantity}',
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () => Navigator.of(context).pop(quantity),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                      ),
                      child: Text('Send ×$quantity'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
    if (accepted != null && mounted) await _send(accepted);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'GIFTS',
                      style: TextStyle(
                        color: Color(0xFFB98CFF),
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                    Text(
                      'Send a Gift',
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Chip(label: Text('🪙 ${widget.coins}')),
              ],
            ),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'all', label: Text('All')),
                ButtonSegment(value: 'classic', label: Text('Classic')),
                ButtonSegment(value: 'fameverse', label: Text('Fameverse')),
              ],
              selected: {_category},
              onSelectionChanged: (value) =>
                  setState(() => _category = value.first),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 210,
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: .9,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: _visible.length,
                itemBuilder: (context, index) {
                  final gift = _visible[index];
                  final selected = gift.id == _selectedId;
                  return InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => setState(() => _selectedId = gift.id),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: selected
                            ? const Color(0xFF352148)
                            : const Color(0xFF21182A),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: selected
                              ? const Color(0xFFAD73FF)
                              : Colors.white10,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          NativeGiftTrayVisual(gift: gift, size: 44),
                          const SizedBox(height: 5),
                          Text(
                            gift.label,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            '🪙 ${gift.cost}',
                            style: const TextStyle(
                              fontSize: 10,
                              color: Color(0xFFCFC4D5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Row(
              children: [
                NativeGiftTrayVisual(gift: _selected, size: 38),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _selected.label,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
                TextButton(
                  onPressed: _sending ? null : _customAmount,
                  child: const Text('Custom'),
                ),
                FilledButton(
                  onPressed: _sending ? null : () => _send(1),
                  child: Text(
                    _sending ? 'Sending…' : 'Send · 🪙 ${_selected.cost}',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text(
                  'Beta tester balance',
                  style: TextStyle(color: Color(0xFFAFA4B6), fontSize: 12),
                ),
                const Spacer(),
                if (widget.canRefill)
                  TextButton(
                    onPressed: _sending ? null : widget.onRefill,
                    child: const Text('+10K'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class NativeProfileAvatar extends StatelessWidget {
  const NativeProfileAvatar({
    required this.profile,
    this.radius = 18,
    super.key,
  });

  final FvProfile profile;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final avatar = profile.avatarUrl;
    return CircleAvatar(
      radius: radius,
      foregroundImage: avatar != null && avatar.isNotEmpty
          ? NetworkImage(avatar)
          : null,
      child: Text(profile.initial),
    );
  }
}

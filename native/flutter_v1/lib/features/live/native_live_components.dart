import 'dart:async';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../data/fameverse_backend.dart';
import '../../data/fameverse_live_backend.dart';

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

class _GiftComboState {
  const _GiftComboState({
    required this.giftId,
    required this.at,
    required this.count,
  });

  final String giftId;
  final DateTime at;
  final int count;
}

final Map<String, _GiftComboState> _giftComboBySender =
    <String, _GiftComboState>{};

int _nextGiftCombo({
  required String sender,
  required String giftId,
  required DateTime acceptedAt,
}) {
  const window = Duration(milliseconds: 2200);
  final key = sender.trim().toLowerCase();
  final previous = _giftComboBySender[key];
  final sameCombo = previous != null &&
      previous.giftId == giftId &&
      acceptedAt.difference(previous.at).abs() <= window;
  final nextCount = sameCombo ? (previous.count + 1).clamp(1, 10) : 1;
  _giftComboBySender[key] = _GiftComboState(
    giftId: giftId,
    at: acceptedAt,
    count: nextCount,
  );
  return nextCount;
}

class FvGiftPlayback {
  factory FvGiftPlayback({
    required FvGiftDefinition gift,
    required int quantity,
    required String sender,
    DateTime? acceptedAt,
  }) {
    final at = acceptedAt ?? DateTime.now();
    return FvGiftPlayback._(
      gift: gift,
      quantity: quantity,
      sender: sender,
      acceptedAt: at,
      comboCount: _nextGiftCombo(
        sender: sender,
        giftId: gift.id,
        acceptedAt: at,
      ),
    );
  }

  const FvGiftPlayback._({
    required this.gift,
    required this.quantity,
    required this.sender,
    required this.acceptedAt,
    required this.comboCount,
  });

  final FvGiftDefinition gift;
  final int quantity;
  final String sender;
  final DateTime acceptedAt;
  final int comboCount;
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
    if (oldWidget.playback.gift.videoUrl != widget.playback.gift.videoUrl) {
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
    final controller = _controller;
    final combo = playback.comboCount.clamp(1, 10);
    if (playback.gift.cinematic &&
        controller != null &&
        controller.value.isInitialized) {
      return IgnorePointer(
        child: Stack(
          fit: StackFit.expand,
          children: [
            Container(color: Colors.black.withValues(alpha: .24)),
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
              bottom: 118,
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: .86, end: 1),
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutBack,
                builder: (context, scale, child) => Transform.scale(
                  scale: scale,
                  child: child,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${playback.sender} sent ${playback.gift.label}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        shadows: [Shadow(blurRadius: 10, color: Colors.black)],
                      ),
                    ),
                    if (combo > 1)
                      Text(
                        '×$combo COMBO',
                        style: const TextStyle(
                          color: Color(0xFFF4D4FF),
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          fontStyle: FontStyle.italic,
                          shadows: [Shadow(blurRadius: 12, color: Colors.black)],
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

    return IgnorePointer(
      child: SafeArea(
        child: Align(
          alignment: Alignment.bottomLeft,
          child: Padding(
            padding: const EdgeInsets.only(left: 12, right: 74, bottom: 205),
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: .68, end: 1),
              duration: const Duration(milliseconds: 240),
              curve: Curves.easeOutBack,
              builder: (context, scale, child) => Transform.scale(
                alignment: Alignment.bottomLeft,
                scale: scale,
                child: child,
              ),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 330),
                padding: const EdgeInsets.fromLTRB(12, 9, 14, 9),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xE8231532), Color(0xD94A2464)],
                  ),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: const Color(0x889D55FF)),
                  boxShadow: const [
                    BoxShadow(
                      blurRadius: 22,
                      spreadRadius: 1,
                      color: Color(0x552D0B45),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 78,
                      height: 78,
                      child: Center(
                        child: Text(
                          playback.gift.symbol,
                          style: const TextStyle(fontSize: 64, height: 1),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            playback.sender,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFFF5EFFF),
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            'sent ${playback.gift.label}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          if (playback.quantity > 1)
                            Text(
                              '${playback.quantity} gifts in this send',
                              style: const TextStyle(
                                color: Color(0xFFD6C9DE),
                                fontSize: 11,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '×$combo',
                      style: TextStyle(
                        color: combo > 1
                            ? const Color(0xFFFFD86B)
                            : const Color(0xFFF5EFFF),
                        fontSize: combo > 1 ? 31 : 24,
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.italic,
                        shadows: const [
                          Shadow(blurRadius: 10, color: Colors.black54),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
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
    if (_selected.singleSendOnly) return;
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
                    const SizedBox(height: 18),
                    Text(
                      '${_selected.symbol} ${_selected.label}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
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
                            decoration: const InputDecoration(labelText: 'Quantity'),
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
                      style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900),
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
              onSelectionChanged: (value) => setState(() => _category = value.first),
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
                          Text(gift.symbol, style: const TextStyle(fontSize: 28)),
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
                Expanded(
                  child: Text(
                    '${_selected.symbol} ${_selected.label}',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
                if (!_selected.singleSendOnly)
                  TextButton(
                    onPressed: _sending ? null : _customAmount,
                    child: const Text('Custom'),
                  ),
                FilledButton(
                  onPressed: _sending ? null : () => _send(1),
                  child: Text(_sending ? 'Sending…' : 'Send · 🪙 ${_selected.cost}'),
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
  const NativeProfileAvatar({required this.profile, this.radius = 18, super.key});

  final FvProfile profile;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final avatar = profile.avatarUrl;
    return CircleAvatar(
      radius: radius,
      foregroundImage: avatar != null && avatar.isNotEmpty ? NetworkImage(avatar) : null,
      child: Text(profile.initial),
    );
  }
}

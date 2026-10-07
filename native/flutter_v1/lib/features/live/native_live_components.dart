import 'dart:async';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../data/fameverse_backend.dart';
import '../../data/fameverse_live_backend.dart';
import 'native_gift_visual.dart';

class FvLiveChatMessage {
  const FvLiveChatMessage({
    required this.id,
    required this.user,
    required this.text,
    this.userId,
    this.avatarUrl,
    this.gifterLevel = 1,
    this.kind = 'comment',
    this.giftId,
    this.quantity = 1,
  });

  final String id;
  final String user;
  final String? userId;
  final String? avatarUrl;
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
    this.senderAvatarUrl,
    this.comboIndex = 1,
    this.comboTotal = 1,
  });

  final FvGiftDefinition gift;
  final int quantity;
  final String sender;
  final String? senderAvatarUrl;
  final int comboIndex;
  final int comboTotal;

  String get visualCountLabel {
    if (comboTotal > 1) return ' · Combo ×$comboIndex';
    if (quantity > 1) return ' · ×$quantity';
    return '';
  }
}

const int fvMaxSequentialGiftCombo = 50;

List<FvGiftPlayback> fvExpandGiftVisualCombo(FvGiftPlayback playback) {
  if (playback.quantity <= 1 || playback.quantity > fvMaxSequentialGiftCombo) {
    return <FvGiftPlayback>[playback];
  }

  return List<FvGiftPlayback>.generate(
    playback.quantity,
    (index) => FvGiftPlayback(
      gift: playback.gift,
      quantity: 1,
      sender: playback.sender,
      senderAvatarUrl: playback.senderAvatarUrl,
      comboIndex: index + 1,
      comboTotal: playback.quantity,
    ),
    growable: false,
  );
}

class NativeGiftOverlay extends StatefulWidget {
  const NativeGiftOverlay({required this.playback, this.onFinished, super.key});

  final FvGiftPlayback playback;
  final VoidCallback? onFinished;

  @override
  State<NativeGiftOverlay> createState() => _NativeGiftOverlayState();
}

class _NativeGiftOverlayState extends State<NativeGiftOverlay> {
  static const _introDuration = Duration(milliseconds: 850);
  static const _outroDuration = Duration(milliseconds: 220);

  VideoPlayerController? _controller;
  Timer? _introTimer;
  Timer? _finishTimer;
  bool _introComplete = false;
  bool _playing = false;
  bool _closing = false;
  bool _reportedFinished = false;
  bool _videoFailed = false;
  int _videoLoadEpoch = 0;

  @override
  void initState() {
    super.initState();
    _startIntro();
    unawaited(_syncVideo());
  }

  @override
  void didUpdateWidget(covariant NativeGiftOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.playback.gift.id != widget.playback.gift.id ||
        oldWidget.playback.gift.videoUrl != widget.playback.gift.videoUrl ||
        oldWidget.playback.quantity != widget.playback.quantity ||
        oldWidget.playback.comboIndex != widget.playback.comboIndex) {
      _introTimer?.cancel();
      _finishTimer?.cancel();
      _introComplete = false;
      _playing = false;
      _closing = false;
      _reportedFinished = false;
      _startIntro();
      unawaited(_syncVideo());
    }
  }

  void _startIntro() {
    _introTimer?.cancel();
    _introTimer = Timer(_introDuration, () {
      if (!mounted || _reportedFinished) return;
      setState(() => _introComplete = true);
      unawaited(_beginPlayback());
    });
  }

  void _scheduleFinish(Duration duration) {
    _finishTimer?.cancel();
    _finishTimer = Timer(duration, _beginOutro);
  }

  void _watchVideoPlayback() {
    final player = _controller;
    if (!mounted || !_playing || _closing || player == null) return;
    final value = player.value;
    if (!value.isInitialized) return;
    if (value.hasError) {
      _beginOutro();
      return;
    }
    if (value.duration > Duration.zero &&
        (value.position >=
                value.duration - const Duration(milliseconds: 180) ||
            value.isCompleted)) {
      _beginOutro();
    }
  }

  void _beginOutro() {
    if (!mounted || _closing || _reportedFinished) return;
    _closing = true;
    _finishTimer?.cancel();
    setState(() {});
    _finishTimer = Timer(
      _outroDuration,
      () => unawaited(_finishPlayback()),
    );
  }

  Future<void> _finishPlayback() async {
    if (_reportedFinished) return;
    _reportedFinished = true;
    _introTimer?.cancel();
    _finishTimer?.cancel();
    final player = _controller;
    if (player != null) {
      try {
        await player.setVolume(0);
        await player.pause();
      } catch (_) {
        // A media teardown must never trap the next gift in the queue.
      }
    }
    if (mounted) widget.onFinished?.call();
  }

  Future<void> _beginPlayback() async {
    if (!mounted ||
        !_introComplete ||
        _playing ||
        _closing ||
        _reportedFinished) {
      return;
    }
    final gift = widget.playback.gift;
    if (!gift.cinematic) {
      setState(() => _playing = true);
      _scheduleFinish(const Duration(milliseconds: 1600));
      return;
    }
    final player = _controller;
    if (player == null || !player.value.isInitialized) {
      if (_videoFailed) {
        setState(() => _playing = true);
        _scheduleFinish(const Duration(milliseconds: 1200));
      }
      return;
    }

    setState(() => _playing = true);
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted || _controller != player || _closing) return;
    try {
      await player.seekTo(Duration.zero);
      await player.setVolume(1);
      await player.play();
      final safeMs = (player.value.duration.inMilliseconds + 1000)
          .clamp(1500, 60000)
          .toInt();
      _scheduleFinish(Duration(milliseconds: safeMs));
    } catch (_) {
      if (!mounted) return;
      setState(() => _videoFailed = true);
      _scheduleFinish(const Duration(milliseconds: 1200));
    }
  }

  Future<void> _syncVideo() async {
    final epoch = ++_videoLoadEpoch;
    final gift = widget.playback.gift;
    final url = gift.videoUrl?.trim() ?? '';
    final previous = _controller;
    _controller = null;
    _videoFailed = gift.cinematic && url.isEmpty;
    if (previous != null) {
      previous.removeListener(_watchVideoPlayback);
      try {
        await previous.setVolume(0);
        await previous.pause();
        await previous.dispose();
      } catch (_) {}
    }
    if (!mounted || epoch != _videoLoadEpoch) return;

    if (!gift.cinematic || url.isEmpty) {
      setState(() {});
      unawaited(_beginPlayback());
      return;
    }

    setState(() {});
    for (var attempt = 0; attempt < 2; attempt++) {
      final next = VideoPlayerController.networkUrl(
        Uri.parse(url),
        videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
      );
      try {
        await next.initialize().timeout(const Duration(seconds: 10));
        if (!mounted || epoch != _videoLoadEpoch) {
          await next.dispose();
          return;
        }
        await next.setLooping(false);
        await next.setVolume(0);
        await next.pause();
        await next.seekTo(Duration.zero);
        if (!mounted || epoch != _videoLoadEpoch) {
          await next.dispose();
          return;
        }
        _controller = next;
        next.addListener(_watchVideoPlayback);
        _videoFailed = false;
        setState(() {});
        unawaited(_beginPlayback());
        return;
      } catch (_) {
        try {
          await next.dispose();
        } catch (_) {}
        if (!mounted || epoch != _videoLoadEpoch) return;
        if (attempt == 0) {
          await Future<void>.delayed(const Duration(milliseconds: 350));
        }
      }
    }

    if (!mounted || epoch != _videoLoadEpoch) return;
    _videoFailed = true;
    setState(() {});
    unawaited(_beginPlayback());
  }

  @override
  void dispose() {
    _videoLoadEpoch++;
    _introTimer?.cancel();
    _finishTimer?.cancel();
    final player = _controller;
    _controller = null;
    if (player != null) {
      player.removeListener(_watchVideoPlayback);
      unawaited(_muteAndDispose(player));
    }
    super.dispose();
  }

  Future<void> _muteAndDispose(VideoPlayerController player) async {
    try {
      await player.setVolume(0);
      await player.pause();
      await player.dispose();
    } catch (_) {}
  }

  Widget _senderIntro(BuildContext context) {
    final gift = widget.playback.gift;
    final width = MediaQuery.sizeOf(context).width;
    return Align(
      alignment: const Alignment(-1, -0.02),
      child: TweenAnimationBuilder<double>(
        key: Key('gift-sender-entrance-${gift.id}'),
        tween: Tween<double>(begin: -1, end: 0),
        duration: const Duration(milliseconds: 330),
        curve: Curves.easeOutCubic,
        builder: (context, slide, child) => Transform.translate(
          offset: Offset(slide * width, 0),
          child: child,
        ),
        child: Container(
          margin: const EdgeInsets.only(left: 14, right: 36),
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
          constraints: BoxConstraints(maxWidth: width * .76),
          decoration: BoxDecoration(
            color: const Color(0xE91D1026),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFB878E7)),
            boxShadow: const [
              BoxShadow(color: Color(0x99000000), blurRadius: 16),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: const Color(0xFF6F35A1),
                foregroundImage:
                    widget.playback.senderAvatarUrl?.trim().isNotEmpty == true
                    ? NetworkImage(widget.playback.senderAvatarUrl!.trim())
                    : null,
                child:
                    widget.playback.senderAvatarUrl?.trim().isNotEmpty == true
                    ? null
                    : Text(
                        widget.playback.sender.isEmpty
                            ? 'F'
                            : widget.playback.sender.characters.first
                                  .toUpperCase(),
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                          color: Colors.white,
                        ),
                      ),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.playback.sender,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'sent ${gift.label}${widget.playback.visualCountLabel}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFFE6C5F8),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _smallGiftPresentation(BuildContext context) {
    final gift = widget.playback.gift;
    final size = MediaQuery.sizeOf(context);
    return Align(
      alignment: const Alignment(0, .02),
      child: SizedBox(
        key: Key('native-gift-presentation-${gift.id}'),
        width: size.width * .76,
        height: size.height * .34,
        child: Center(
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: .8, end: 1),
            duration: const Duration(milliseconds: 480),
            curve: Curves.easeOutBack,
            builder: (context, scale, child) =>
                Transform.scale(scale: scale, child: child),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 22,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(26),
                gradient: const RadialGradient(
                  colors: [Color(0xFF713A99), Color(0xFF211329)],
                ),
                border: Border.all(color: const Color(0xFFB974EF)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.card_giftcard_rounded,
                    size: 58,
                    color: Color(0xFFF3D7FF),
                  ),
                  const SizedBox(height: 9),
                  Text(
                    gift.label,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _activePresentation(BuildContext context) {
    final gift = widget.playback.gift;
    if (!gift.cinematic) {
      return _smallGiftPresentation(context);
    }

    final player = _controller;
    final size = MediaQuery.sizeOf(context);
    if (player != null && player.value.isInitialized && !_videoFailed) {
      return Center(
        child: SizedBox(
          key: Key('cinematic-gift-presentation-${gift.id}'),
          width: size.width,
          height: size.height * .76,
          child: FittedBox(
            fit: BoxFit.contain,
            clipBehavior: Clip.none,
            child: SizedBox(
              width: player.value.size.width <= 0
                  ? size.width
                  : player.value.size.width,
              height: player.value.size.height <= 0
                  ? size.height * .76
                  : player.value.size.height,
              child: VideoPlayer(player),
            ),
          ),
        ),
      );
    }
    return Align(
      alignment: Alignment.center,
      child: Container(
        key: Key('cinematic-gift-media-failed-${gift.id}'),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xE617101F),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          '${gift.label} animation unavailable',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            color: Color(0xFFE8D4F5),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (_playing)
            AnimatedOpacity(
              opacity: _closing ? 0 : 1,
              duration: _outroDuration,
              curve: Curves.easeOut,
              child: _activePresentation(context),
            ),
          if (!_playing) _senderIntro(context),
        ],
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
    this.onBuyCoins,
    this.onExchange,
    super.key,
  });

  final int coins;
  final bool canRefill;
  final Future<bool> Function(FvGiftDefinition gift, int quantity) onSend;
  final Future<int> Function() onRefill;
  final VoidCallback? onBuyCoins;
  final VoidCallback? onExchange;

  @override
  State<NativeGiftTray> createState() => _NativeGiftTrayState();
}

class _NativeGiftTrayState extends State<NativeGiftTray> {
  static const _categories = <(String, String)>[
    ('trending', 'Trending'),
    ('support', 'Support'),
    ('fun', 'Fun'),
    ('luxury', 'Luxury'),
    ('fameverse', 'Fameverse'),
  ];

  static const _trendingIds = <String>{
    'rose',
    'heart',
    'fire',
    'star',
    'planet',
    'galaxy',
    'welcome-to-fameverse',
    'fame-burst',
  };

  String _category = 'trending';
  String _selectedId = 'rose';
  bool _sending = false;
  bool _refilling = false;
  late int _coins;

  bool _matchesCategory(FvGiftDefinition gift, String category) {
    switch (category) {
      case 'trending':
        return _trendingIds.contains(gift.id);
      case 'support':
        return gift.cost <= 10;
      case 'fun':
        return const <String>{
          'reactions',
          'snacks',
          'flowers',
          'celebrate',
          'creator',
          'sports',
          'animals',
        }.contains(gift.category);
      case 'luxury':
        return gift.cost >= 40 && gift.cost < 1000;
      case 'fameverse':
        return gift.category == 'fameverse';
      default:
        return false;
    }
  }

  List<FvGiftDefinition> get _visible =>
      fvGiftCatalog.where((gift) => _matchesCategory(gift, _category)).toList();

  FvGiftDefinition get _selected {
    final selected = fvGiftById(_selectedId);
    if (selected != null) return selected;
    final visible = _visible;
    return visible.isNotEmpty ? visible.first : fvGiftCatalog.first;
  }

  @override
  void initState() {
    super.initState();
    _coins = widget.coins;
  }

  @override
  void didUpdateWidget(covariant NativeGiftTray oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.coins != widget.coins && widget.coins != _coins) {
      _coins = widget.coins;
    }
  }

  Future<void> _send(int quantity) async {
    if (_sending) return;
    final gift = _selected;
    setState(() => _sending = true);
    final sent = await widget.onSend(gift, quantity);
    if (!mounted) return;
    if (sent) {
      Navigator.of(context).pop();
      return;
    }
    setState(() => _sending = false);
  }

  Future<void> _refill() async {
    if (_refilling) return;
    setState(() => _refilling = true);
    try {
      final balance = await widget.onRefill();
      if (mounted) setState(() => _coins = balance);
    } finally {
      if (mounted) setState(() => _refilling = false);
    }
  }

  Future<void> _customAmount() async {
    var quantity = 1;
    final quantityController = TextEditingController(text: '1');
    final accepted = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF17101F),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            void setQuantity(int value, {bool syncField = true}) {
              final next = value.clamp(1, 100000);
              setModalState(() => quantity = next);
              if (!syncField) return;
              quantityController.value = TextEditingValue(
                text: '$next',
                selection: TextSelection.collapsed(
                  offset: '$next'.length,
                ),
              );
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
                            key: const Key('gift-custom-quantity-field'),
                            controller: quantityController,
                            textAlign: TextAlign.center,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Quantity',
                            ),
                            onChanged: (value) {
                              final parsed = int.tryParse(value);
                              if (parsed != null) {
                                setQuantity(parsed, syncField: false);
                              }
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
    quantityController.dispose();
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
                Chip(label: Text('🪙 $_coins')),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 38,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 7),
                itemBuilder: (context, index) {
                  final item = _categories[index];
                  return ChoiceChip(
                    key: Key('gift-category-${item.$1}'),
                    label: Text(item.$2),
                    selected: _category == item.$1,
                    onSelected: (_) {
                      final visible = fvGiftCatalog
                          .where((gift) => _matchesCategory(gift, item.$1))
                          .toList();
                      setState(() {
                        _category = item.$1;
                        if (visible.isNotEmpty &&
                            !visible.any((gift) => gift.id == _selectedId)) {
                          _selectedId = visible.first.id;
                        }
                      });
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 220,
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
                    key: Key('gift-tile-${gift.id}'),
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
            const SizedBox(height: 6),
            Row(
              children: [
                const Text(
                  'Fame Coin balance',
                  style: TextStyle(color: Color(0xFFAFA4B6), fontSize: 12),
                ),
                const Spacer(),
                if (widget.onBuyCoins != null)
                  TextButton(
                    key: const Key('gift-tray-buy-coins'),
                    onPressed: _sending ? null : widget.onBuyCoins,
                    child: const Text('Buy coins'),
                  ),
                if (widget.onExchange != null)
                  TextButton(
                    key: const Key('gift-tray-coin-exchange'),
                    onPressed: _sending ? null : widget.onExchange,
                    child: const Text('Exchange earnings'),
                  ),
                if (widget.canRefill)
                  TextButton(
                    onPressed: _sending || _refilling ? null : _refill,
                    child: Text(_refilling ? 'Adding…' : '+10K QA'),
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

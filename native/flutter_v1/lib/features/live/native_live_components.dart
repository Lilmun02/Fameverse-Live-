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
    this.comboIndex = 1,
    this.comboTotal = 1,
  });

  final FvGiftDefinition gift;
  final int quantity;
  final String sender;
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
  VideoPlayerController? _controller;
  String? _loadedUrl;
  Timer? _finishTimer;
  bool _reportedFinished = false;
  bool _videoLoading = false;
  bool _videoFailed = false;
  int _videoLoadEpoch = 0;

  @override
  void initState() {
    super.initState();
    unawaited(_syncVideo());
  }

  @override
  void didUpdateWidget(covariant NativeGiftOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.playback.gift.id != widget.playback.gift.id ||
        oldWidget.playback.gift.videoUrl != widget.playback.gift.videoUrl ||
        oldWidget.playback.quantity != widget.playback.quantity) {
      _reportedFinished = false;
      _finishTimer?.cancel();
      unawaited(_syncVideo());
    }
  }

  void _scheduleFinish(Duration duration) {
    _finishTimer?.cancel();
    _finishTimer = Timer(duration, _reportFinished);
  }

  void _reportFinished() {
    if (_reportedFinished) return;
    _reportedFinished = true;
    widget.onFinished?.call();
  }

  Duration _staticDuration(FvGiftDefinition gift) {
    if (gift.cinematic) return const Duration(milliseconds: 3200);
    if (gift.cost >= 100) return const Duration(milliseconds: 3000);
    return const Duration(milliseconds: 1900);
  }

  Future<void> _syncVideo() async {
    final epoch = ++_videoLoadEpoch;
    final gift = widget.playback.gift;
    final url = gift.videoUrl?.trim() ?? '';

    if (!gift.cinematic || url.isEmpty) {
      final previous = _controller;
      _controller = null;
      _loadedUrl = null;
      _videoLoading = false;
      _videoFailed = gift.cinematic;
      if (previous != null) await previous.dispose();
      _scheduleFinish(_staticDuration(gift));
      if (mounted) setState(() {});
      return;
    }

    if (_loadedUrl == url &&
        _controller != null &&
        _controller!.value.isInitialized) {
      _videoLoading = false;
      _videoFailed = false;
      await _controller!.seekTo(Duration.zero);
      await _controller!.setVolume(1);
      await _controller!.play();
      final rawMs = _controller!.value.duration.inMilliseconds + 350;
      final safeMs = rawMs.clamp(1500, 60000).toInt();
      _scheduleFinish(Duration(milliseconds: safeMs));
      if (mounted) setState(() {});
      return;
    }

    _videoLoading = true;
    _videoFailed = false;
    if (mounted) setState(() {});

    final previous = _controller;
    _controller = null;
    _loadedUrl = null;
    if (previous != null) await previous.dispose();

    Object? lastError;
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
        await next.setVolume(1);
        await next.seekTo(Duration.zero);
        await next.play();
        _controller = next;
        _loadedUrl = url;
        _videoLoading = false;
        _videoFailed = false;
        final rawMs = next.value.duration.inMilliseconds + 350;
        final safeMs = rawMs.clamp(1500, 60000).toInt();
        _scheduleFinish(Duration(milliseconds: safeMs));
        setState(() {});
        return;
      } catch (error) {
        lastError = error;
        await next.dispose();
        if (!mounted || epoch != _videoLoadEpoch) return;
        if (attempt == 0) {
          await Future<void>.delayed(const Duration(milliseconds: 350));
        }
      }
    }

    if (!mounted || epoch != _videoLoadEpoch) return;
    _videoLoading = false;
    _videoFailed = true;
    _controller = null;
    _loadedUrl = null;
    _scheduleFinish(const Duration(milliseconds: 4500));
    setState(() {});
    assert(() {
      debugPrint('Premium gift video failed for ${gift.id}: $lastError');
      return true;
    }());
  }

  @override
  void dispose() {
    _videoLoadEpoch++;
    _finishTimer?.cancel();
    final controller = _controller;
    _controller = null;
    if (controller != null) unawaited(controller.dispose());
    super.dispose();
  }

  Widget _largeNativeGift(BuildContext context, FvGiftPlayback playback) {
    final size = MediaQuery.sizeOf(context);
    final premium = playback.gift.cost >= 100;
    final presentationWidth = size.width * (premium ? .90 : .76);
    final presentationHeight = size.height * (premium ? .52 : .34);
    final glowSize = size.width * (premium ? .74 : .48);
    final symbolSize = premium ? 132.0 : 82.0;

    return IgnorePointer(
      child: Align(
        alignment: const Alignment(0, .02),
        child: SizedBox(
          key: Key('native-gift-presentation-${playback.gift.id}'),
          width: presentationWidth,
          height: presentationHeight,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: glowSize,
                height: glowSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(
                        0xFF9D55FF,
                      ).withValues(alpha: premium ? .44 : .30),
                      const Color(0xFF5C22A7).withValues(alpha: .16),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: .72, end: 1),
                duration: const Duration(milliseconds: 560),
                curve: Curves.easeOutBack,
                builder: (context, value, child) =>
                    Transform.scale(scale: value, child: child),
                child: Text(
                  playback.gift.symbol,
                  style: TextStyle(
                    fontSize: symbolSize,
                    shadows: const [
                      Shadow(color: Color(0xAA8F46E8), blurRadius: 28),
                      Shadow(color: Colors.black87, blurRadius: 8),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final playback = widget.playback;

    if (!playback.gift.cinematic) {
      return _largeNativeGift(context, playback);
    }

    final controller = _controller;
    if (controller != null && controller.value.isInitialized) {
      final size = MediaQuery.sizeOf(context);
      return IgnorePointer(
        child: Center(
          child: SizedBox(
            key: Key('cinematic-gift-presentation-${playback.gift.id}'),
            width: size.width,
            height: size.height * .76,
            child: FittedBox(
              fit: BoxFit.contain,
              clipBehavior: Clip.none,
              child: SizedBox(
                width: controller.value.size.width <= 0
                    ? size.width
                    : controller.value.size.width,
                height: controller.value.size.height <= 0
                    ? size.height * .76
                    : controller.value.size.height,
                child: VideoPlayer(controller),
              ),
            ),
          ),
        ),
      );
    }

    final size = MediaQuery.sizeOf(context);
    return IgnorePointer(
      child: Center(
        child: Container(
          key: Key(
            _videoFailed
                ? 'cinematic-gift-media-failed-${playback.gift.id}'
                : 'cinematic-gift-media-loading-${playback.gift.id}',
          ),
          width: size.width * .90,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          decoration: BoxDecoration(
            color: const Color(0xE617101F),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: const Color(0x665F37A1)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_videoLoading)
                const SizedBox.square(
                  dimension: 30,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                )
              else
                const Icon(
                  Icons.movie_filter_outlined,
                  color: Color(0xFFB98CFF),
                  size: 34,
                ),
              const SizedBox(height: 12),
              Text(
                _videoFailed
                    ? 'Premium gift media could not load'
                    : 'Loading premium gift…',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _videoFailed
                    ? 'The premium gift was recorded, but Fameverse will not replace its animation with an emoji.'
                    : 'Preparing the original premium gift animation.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFFB9ACBE),
                  fontSize: 11,
                  height: 1.35,
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

part of 'native_live_components.dart';

class NativeGiftTray extends StatefulWidget {
  const NativeGiftTray({
    required this.coins,
    required this.realCoins,
    required this.testCoins,
    required this.canRefill,
    required this.onSend,
    required this.onRefill,
    this.onBuyCoins,
    this.onExchange,
    super.key,
  });

  final int coins;
  final int realCoins;
  final int testCoins;
  final bool canRefill;
  final Future<bool> Function(FvGiftDefinition gift, int quantity) onSend;
  final Future<FvCoinFundingBreakdown> Function() onRefill;
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
  late int _realCoins;
  late int _testCoins;

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
    _realCoins = widget.realCoins;
    _testCoins = widget.testCoins;
  }

  @override
  void didUpdateWidget(covariant NativeGiftTray oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.coins != widget.coins && widget.coins != _coins) {
      _coins = widget.coins;
    }
    if (oldWidget.realCoins != widget.realCoins) {
      _realCoins = widget.realCoins;
    }
    if (oldWidget.testCoins != widget.testCoins) {
      _testCoins = widget.testCoins;
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
      if (mounted) {
        setState(() {
          _coins = balance.totalCoins;
          _realCoins = balance.realCoins;
          _testCoins = balance.testCoins;
        });
      }
    } finally {
      if (mounted) setState(() => _refilling = false);
    }
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
                Flexible(
                  child: _GiftFundingBalance(
                    realCoins: _realCoins,
                    testCoins: _testCoins,
                    totalCoins: _coins,
                  ),
                ),
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
                  onPressed: _sending ? null : _GiftCustomAmount(this).customAmount,
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
                  'Real Coins can create creator earnings · Test Coins cannot',
                  style: TextStyle(color: Color(0xFFAFA4B6), fontSize: 10),
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

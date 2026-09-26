import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class NativeRechargeScreen extends StatefulWidget {
  const NativeRechargeScreen({super.key});

  @override
  State<NativeRechargeScreen> createState() => _NativeRechargeScreenState();
}

class _NativeRechargeScreenState extends State<NativeRechargeScreen> {
  bool _loading = true;
  bool _busy = false;
  bool _customEnabled = false;
  String? _error;
  String? _sessionToken;
  String? _environment;
  List<_RechargePack> _packs = const [];
  String _customPackId = 'owner-qa-custom';
  int _customMinCoins = 100;
  int _customMaxCoins = 10000;
  int _customCentsPerCoin = 1;
  String? _pendingOrderId;
  String? _pendingPackLabel;

  SupabaseClient get _client => Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<Map<String, dynamic>> _invoke(
    String functionName, {
    Map<String, dynamic>? body,
  }) async {
    final response = await _client.functions.invoke(functionName, body: body);
    final data = response.data;
    if (data is! Map) {
      throw StateError('$functionName returned an invalid response.');
    }
    final map = Map<String, dynamic>.from(data);
    if (map['error'] != null) {
      throw StateError(map['error'].toString());
    }
    return map;
  }

  Future<Map<String, dynamic>> _rechargeApi(
    String action, [
    Map<String, dynamic> extra = const {},
  ]) async {
    final session = _sessionToken;
    if (session == null || session.isEmpty) {
      throw StateError('recharge-session-unavailable');
    }
    return _invoke(
      'recharge',
      body: <String, dynamic>{'session': session, 'action': action, ...extra},
    );
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final session = await _invoke('recharge-session');
      final token = session['session']?.toString() ?? '';
      if (token.isEmpty) throw StateError('recharge-session-unavailable');
      _sessionToken = token;

      final config = await _rechargeApi('config');
      final rows = config['packs'];
      final packs = rows is List
          ? rows
                .whereType<Map>()
                .map(
                  (row) =>
                      _RechargePack.fromMap(Map<String, dynamic>.from(row)),
                )
                .where((pack) => pack.id.isNotEmpty && pack.priceCents > 0)
                .toList()
          : <_RechargePack>[];
      final customRaw = config['custom'];
      final custom = customRaw is Map
          ? Map<String, dynamic>.from(customRaw)
          : const <String, dynamic>{};

      if (!mounted) return;
      setState(() {
        _packs = packs;
        _environment = config['environment']?.toString() ?? 'sandbox';
        _customEnabled = custom['enabled'] == true;
        _customPackId = custom['pack_id']?.toString() ?? 'owner-qa-custom';
        _customMinCoins = (custom['min_coins'] as num?)?.toInt() ?? 100;
        _customMaxCoins = (custom['max_coins'] as num?)?.toInt() ?? 10000;
        _customCentsPerCoin =
            (custom['cents_per_coin'] as num?)?.toInt() ?? 1;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      final text = error.toString().toLowerCase();
      setState(() {
        _loading = false;
        _error = text.contains('owner')
            ? 'This PayPal sandbox recharge tool is limited to the Fameverse owner account.'
            : text.contains('paypal-not-configured')
            ? 'PayPal sandbox credentials are not configured.'
            : 'Fameverse could not open PayPal sandbox recharge right now.';
      });
    }
  }

  Future<void> _startPurchase(_RechargePack pack) => _startOrder(
    packLabel: pack.label,
    payload: <String, dynamic>{'pack_id': pack.id},
  );

  Future<void> _startCustomPurchase(int coins) => _startOrder(
    packLabel: '$coins Fame Coins',
    payload: <String, dynamic>{
      'pack_id': _customPackId,
      'custom_coins': coins,
    },
  );

  Future<void> _startOrder({
    required String packLabel,
    required Map<String, dynamic> payload,
  }) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final created = await _rechargeApi('create', payload);
      final orderId = created['order_id']?.toString() ?? '';
      final approval = created['approval_url']?.toString() ?? '';
      if (orderId.isEmpty || approval.isEmpty) {
        throw StateError('paypal-approval-url-missing');
      }

      final uri = Uri.tryParse(approval);
      if (uri == null || uri.scheme != 'https') {
        throw StateError('paypal-approval-url-invalid');
      }

      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) throw StateError('paypal-approval-open-failed');

      if (!mounted) return;
      setState(() {
        _pendingOrderId = orderId;
        _pendingPackLabel = packLabel;
      });
    } catch (error) {
      if (!mounted) return;
      final text = error.toString().toLowerCase();
      setState(() {
        _error = text.contains('custom')
            ? 'Choose a custom amount between $_customMinCoins and $_customMaxCoins Fame Coins.'
            : text.contains('paypal')
            ? 'PayPal sandbox could not start this test purchase.'
            : 'Could not start the sandbox recharge.';
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openCustomAmount() async {
    if (!_customEnabled || _busy) return;
    final controller = TextEditingController(text: '1000');
    var coins = 1000.clamp(_customMinCoins, _customMaxCoins);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF120C18),
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) {
          final priceCents = coins * _customCentsPerCoin;
          return SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                18,
                20,
                22 + MediaQuery.viewInsetsOf(context).bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Custom Fame Coins',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(sheetContext).pop(),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Choose $_customMinCoins–$_customMaxCoins coins. Sandbox rate: about 100 Fame Coins per \$1.',
                    style: const TextStyle(
                      color: Color(0xFFB9AEC1),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    key: const Key('custom-fame-coins-input'),
                    controller: controller,
                    autofocus: true,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: 'Fame Coins',
                      prefixIcon: Icon(Icons.toll_rounded),
                    ),
                    onChanged: (value) {
                      final parsed = int.tryParse(value) ?? _customMinCoins;
                      setSheetState(() {
                        coins = parsed.clamp(_customMinCoins, _customMaxCoins);
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: <int>[100, 500, 1000, 2500, 5000, 10000]
                        .where(
                          (value) =>
                              value >= _customMinCoins &&
                              value <= _customMaxCoins,
                        )
                        .map(
                          (value) => ActionChip(
                            label: Text(value.toString()),
                            onPressed: () {
                              controller.text = value.toString();
                              setSheetState(() => coins = value);
                            },
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF20132C),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFF8047BF)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.toll_rounded,
                          color: Color(0xFFD3A2FF),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '$coins Fame Coins',
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        Text(
                          '\$${(priceCents / 100).toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    key: const Key('custom-fame-coins-continue'),
                    onPressed:
                        coins < _customMinCoins || coins > _customMaxCoins
                        ? null
                        : () {
                            Navigator.of(sheetContext).pop();
                            unawaited(_startCustomPurchase(coins));
                          },
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(54),
                      backgroundColor: const Color(0xFF8A46DE),
                    ),
                    child: Text(
                      'Continue · \$${(priceCents / 100).toStringAsFixed(2)}',
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    controller.dispose();
  }

  Future<void> _capturePurchase() async {
    final orderId = _pendingOrderId;
    if (_busy || orderId == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final result = await _rechargeApi('capture', {'order_id': orderId});
      if (result['status']?.toString() != 'completed') {
        throw StateError('paypal-capture-not-completed');
      }
      final coins = result['credited_coins']?.toString() ?? '0';
      final balance = result['wallet_balance']?.toString();
      if (!mounted) return;
      setState(() {
        _pendingOrderId = null;
        _pendingPackLabel = null;
      });
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              balance == null
                  ? 'PayPal sandbox completed. $coins Fame Coins credited.'
                  : 'PayPal sandbox completed. $coins Fame Coins credited · balance $balance.',
            ),
          ),
        );
      await _load();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error =
            'PayPal has not completed this sandbox order yet. Finish approval in PayPal, return to Fameverse, then tap Complete sandbox purchase.';
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sandbox = (_environment ?? 'sandbox').toLowerCase() != 'live';
    return Scaffold(
      key: const Key('native-paypal-recharge-screen'),
      backgroundColor: const Color(0xFF0C0810),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0C0810),
        title: const Text('Recharge Fame Coins'),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 40),
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFF18111F),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF49305A)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'PAYPAL SANDBOX',
                      style: TextStyle(
                        color: Color(0xFFC89BFF),
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      sandbox
                          ? 'Test Fame Coin recharge'
                          : 'Live PayPal environment',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 7),
                    const Text(
                      'Choose a pack or enter a custom amount. PayPal handles approval and Fameverse credits the wallet only after Supabase verifies the captured amount.',
                      style: TextStyle(color: Color(0xFFB9AEC1), height: 1.4),
                    ),
                  ],
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF32131F),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(_error!),
                ),
              ],
              const SizedBox(height: 22),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 50),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_packs.isEmpty && !_customEnabled)
                const Text('No owner QA recharge packs are active.')
              else ...[
                const Text(
                  'Get Fame Coins',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Sandbox pricing · about 100 coins per \$1',
                  style: TextStyle(color: Color(0xFFA99CAF), fontSize: 12),
                ),
                const SizedBox(height: 12),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _packs.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 1.65,
                  ),
                  itemBuilder: (context, index) {
                    final pack = _packs[index];
                    return _RechargePackCard(
                      pack: pack,
                      enabled: !_busy,
                      onTap: () => _startPurchase(pack),
                    );
                  },
                ),
                if (_customEnabled) ...[
                  const SizedBox(height: 10),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      key: const Key('custom-fame-coins-card'),
                      onTap: _busy ? null : _openCustomAmount,
                      borderRadius: BorderRadius.circular(18),
                      child: Ink(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 15,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF28153A), Color(0xFF17101F)],
                          ),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: const Color(0xFF8A46DE),
                            width: 1.2,
                          ),
                        ),
                        child: Row(
                          children: [
                            const CircleAvatar(
                              backgroundColor: Color(0xFF4B246A),
                              child: Icon(Icons.tune_rounded),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Custom amount',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  Text(
                                    '$_customMinCoins–$_customMaxCoins Fame Coins',
                                    style: const TextStyle(
                                      color: Color(0xFFB8ACBF),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right_rounded,
                              color: Color(0xFFC99BFF),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ],
              if (_pendingOrderId != null) ...[
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(17),
                  decoration: BoxDecoration(
                    color: const Color(0xFF20142B),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFF6F42A3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        '${_pendingPackLabel ?? 'Sandbox order'} opened in PayPal',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Finish approval with your PayPal sandbox buyer, return to Fameverse, then complete the order here.',
                        style: TextStyle(color: Color(0xFFB9AEC1), height: 1.4),
                      ),
                      const SizedBox(height: 14),
                      FilledButton(
                        key: const Key('complete-paypal-sandbox-purchase'),
                        onPressed: _busy ? null : _capturePurchase,
                        child: Text(
                          _busy
                              ? 'Checking PayPal…'
                              : 'Complete sandbox purchase',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _RechargePackCard extends StatelessWidget {
  const _RechargePackCard({
    required this.pack,
    required this.enabled,
    required this.onTap,
  });

  final _RechargePack pack;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF17111D),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFF392A44)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.toll_rounded, color: Color(0xFFD3A2FF)),
              const SizedBox(height: 7),
              Text(
                '${pack.coins}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                '\$${(pack.priceCents / 100).toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Color(0xFFB8ACBF),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RechargePack {
  const _RechargePack({
    required this.id,
    required this.label,
    required this.coins,
    required this.priceCents,
  });

  final String id;
  final String label;
  final int coins;
  final int priceCents;

  factory _RechargePack.fromMap(Map<String, dynamic> map) {
    return _RechargePack(
      id: map['id']?.toString() ?? '',
      label: map['label']?.toString() ?? 'Fame Coin Pack',
      coins: (map['coins'] as num?)?.toInt() ?? 0,
      priceCents: (map['price_cents'] as num?)?.toInt() ?? 0,
    );
  }
}

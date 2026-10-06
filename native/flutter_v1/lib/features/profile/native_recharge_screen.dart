import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

part 'native_recharge_view.part.dart';

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
  bool get _sandbox => (_environment ?? 'sandbox').toLowerCase() != 'live';
  String get _paypalMode => _sandbox ? 'sandbox' : 'live';

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
        _customCentsPerCoin = (custom['cents_per_coin'] as num?)?.toInt() ?? 1;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      final text = error.toString().toLowerCase();
      setState(() {
        _loading = false;
        _error = text.contains('owner')
            ? 'This PayPal $_paypalMode recharge tool is limited to the Fameverse owner account.'
            : text.contains('paypal-not-configured')
            ? 'PayPal $_paypalMode credentials are not configured.'
            : 'Fameverse could not open PayPal $_paypalMode recharge right now.';
      });
    }
  }

  Future<void> _startPurchase(_RechargePack pack) => _startOrder(
    packLabel: pack.label,
    payload: <String, dynamic>{'pack_id': pack.id},
  );

  Future<void> _startCustomPurchase(int coins) => _startOrder(
    packLabel: '$coins Fame Coins',
    payload: <String, dynamic>{'pack_id': _customPackId, 'custom_coins': coins},
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
            ? 'PayPal $_paypalMode could not start this purchase.'
            : 'Could not start the $_paypalMode recharge.';
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
                    'Choose $_customMinCoins–$_customMaxCoins coins. ${_sandbox ? 'Sandbox' : 'Live'} rate: about 100 Fame Coins per \$1.',
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
                  ? 'PayPal $_paypalMode completed. $coins Fame Coins credited.'
                  : 'PayPal $_paypalMode completed. $coins Fame Coins credited · balance $balance.',
            ),
          ),
        );
      await _load();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error =
            'PayPal has not completed this $_paypalMode order yet. Finish approval in PayPal, return to Fameverse, then tap Complete purchase.';
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _NativeRechargeViewExtension(this).buildView(context);
  }
}

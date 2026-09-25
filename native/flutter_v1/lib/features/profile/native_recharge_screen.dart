import 'dart:async';

import 'package:flutter/material.dart';
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
  String? _error;
  String? _sessionToken;
  String? _environment;
  List<_RechargePack> _packs = const [];
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
      body: <String, dynamic>{
        'session': session,
        'action': action,
        ...extra,
      },
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
                  (row) => _RechargePack.fromMap(
                    Map<String, dynamic>.from(row),
                  ),
                )
                .where((pack) => pack.id.isNotEmpty && pack.priceCents > 0)
                .toList()
          : <_RechargePack>[];

      if (!mounted) return;
      setState(() {
        _packs = packs;
        _environment = config['environment']?.toString() ?? 'sandbox';
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

  Future<void> _startPurchase(_RechargePack pack) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final created = await _rechargeApi('create', {'pack_id': pack.id});
      final orderId = created['order_id']?.toString() ?? '';
      final approval = created['approval_url']?.toString() ?? '';
      if (orderId.isEmpty || approval.isEmpty) {
        throw StateError('paypal-approval-url-missing');
      }

      final uri = Uri.tryParse(approval);
      if (uri == null || uri.scheme != 'https') {
        throw StateError('paypal-approval-url-invalid');
      }

      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched) throw StateError('paypal-approval-open-failed');

      if (!mounted) return;
      setState(() {
        _pendingOrderId = orderId;
        _pendingPackLabel = pack.label;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString().toLowerCase().contains('paypal')
            ? 'PayPal sandbox could not start this test purchase.'
            : 'Could not start the sandbox recharge.';
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
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
                          ? 'Owner QA · no real money'
                          : 'Live PayPal environment',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 7),
                    const Text(
                      'The recharge UI is native Fameverse. PayPal handles approval; Supabase verifies the order and credits the wallet. No Vercel checkout page is used.',
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
              else if (_packs.isEmpty)
                const Text('No owner QA recharge packs are active.')
              else ...[
                const Text(
                  'Choose a QA pack',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 10),
                ..._packs.map(
                  (pack) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _busy ? null : () => _startPurchase(pack),
                        borderRadius: BorderRadius.circular(18),
                        child: Ink(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF17111D),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: const Color(0xFF392A44)),
                          ),
                          child: Row(
                            children: [
                              const CircleAvatar(
                                backgroundColor: Color(0xFF3A2050),
                                child: Icon(Icons.toll_rounded),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      pack.label,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${pack.coins} Fame Coins',
                                      style: const TextStyle(
                                        color: Color(0xFFB8ACBF),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '\$${(pack.priceCents / 100).toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
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
                        child: Text(_busy ? 'Checking PayPal…' : 'Complete sandbox purchase'),
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

part of 'native_recharge_screen.dart';

extension _NativeRechargeViewExtension on _NativeRechargeScreenState {
  Widget buildView(BuildContext context) {
    final sandbox = _sandbox;
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
                    Text(
                      sandbox ? 'PAYPAL SANDBOX' : 'PAYPAL LIVE',
                      style: const TextStyle(
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
                Text(
                  '${sandbox ? 'Sandbox' : 'Live'} pricing · about 100 coins per \$1',
                  style: const TextStyle(
                    color: Color(0xFFA99CAF),
                    fontSize: 12,
                  ),
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
                        '${_pendingPackLabel ?? 'PayPal order'} opened in PayPal',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        sandbox
                            ? 'Finish approval with your PayPal sandbox buyer, return to Fameverse, then complete the order here.'
                            : 'Finish approval in PayPal, return to Fameverse, then complete the order here.',
                        style: const TextStyle(
                          color: Color(0xFFB9AEC1),
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 14),
                      FilledButton(
                        key: const Key('complete-paypal-sandbox-purchase'),
                        onPressed: _busy ? null : _capturePurchase,
                        child: Text(
                          _busy ? 'Checking PayPal…' : 'Complete purchase',
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

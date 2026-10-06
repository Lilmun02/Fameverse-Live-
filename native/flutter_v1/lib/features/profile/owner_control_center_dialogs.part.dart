part of 'owner_control_center_build23.dart';

extension _OwnerControlDialogs on _Build23OwnerControlCenterScreenState {
Future<int?> askDollars({
    required String title,
    required String body,
    required String action,
  }) async {
    final controller = TextEditingController();
    final text = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(body),
            const SizedBox(height: 14),
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Amount (USD)',
                prefixText: r'$ ',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: Text(action),
          ),
        ],
      ),
    );
    controller.dispose();
    if (text == null) return null;
    final dollars = double.tryParse(text);
    final cents = dollars == null ? 0 : (dollars * 100).round();
    if (cents <= 0) {
      _message(r'Enter an amount greater than $0.');
      return null;
    }
    return cents;
  }

  Future<({String note, String reference})?> askPayoutReview({
    required String title,
    required String body,
    required String action,
    bool requireReference = false,
  }) async {
    final noteController = TextEditingController();
    final referenceController = TextEditingController();
    final result = await showDialog<({String note, String reference})>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(body),
              const SizedBox(height: 14),
              TextField(
                controller: noteController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Moderation note (optional)',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: referenceController,
                decoration: InputDecoration(
                  labelText: requireReference
                      ? 'Provider reference / transaction ID'
                      : 'Provider reference (optional)',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final reference = referenceController.text.trim();
              if (requireReference && reference.isEmpty) return;
              Navigator.of(
                context,
              ).pop((note: noteController.text.trim(), reference: reference));
            },
            child: Text(action),
          ),
        ],
      ),
    );
    noteController.dispose();
    referenceController.dispose();
    return result;
  }

  Future<void> grantTesterCoins() async {
    if (_busy) return;
    final usernameController = TextEditingController();
    final amountController = TextEditingController(text: '10000');
    final result = await showDialog<(String, int)>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Grant Tester Test Coins'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Test Coins can test gifts, levels and badges but create no real creator payout liability.',
            ),
            const SizedBox(height: 14),
            TextField(
              key: const Key('owner-test-coin-username'),
              controller: usernameController,
              autocorrect: false,
              decoration: const InputDecoration(
                labelText: 'Tester username',
                prefixText: '@',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              key: const Key('owner-test-coin-amount'),
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Test Coins',
                helperText: 'Default: 10,000 Test Coins',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final username = usernameController.text.trim();
              final amount = int.tryParse(amountController.text.trim()) ?? 0;
              Navigator.of(context).pop((username, amount));
            },
            child: const Text('Grant'),
          ),
        ],
      ),
    );
    usernameController.dispose();
    amountController.dispose();
    if (result == null) return;
    final username = result.$1.replaceFirst(RegExp(r'^@'), '').trim();
    final amount = result.$2;
    if (username.length < 3 || amount < 1 || amount > 1000000) {
      _message('Enter a valid tester username and Test Coin amount.');
      return;
    }

    setState(() => _busy = true);
    try {
      final raw = await _client.rpc(
        'owner_grant_test_coins',
        params: {'p_username': username, 'p_amount': amount},
      );
      final row = _firstRow(raw);
      final total = _int(row['total_balance']);
      final test = _int(row['test_coins']);
      _message('@$username now has $test Test Coins · $total total.');
      await _refresh();
    } catch (error) {
      final value = error.toString().toLowerCase();
      _message(
        value.contains('tester profile not found')
            ? 'Tester username was not found.'
            : 'Could not grant Test Coins.',
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }


  Future<void> grantTesterQaPayoutBalance() async {
    if (_busy) return;
    final usernameController = TextEditingController();
    final amountController = TextEditingController(text: '25.00');
    final result = await showDialog<(String, int)>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Grant QA Payout Balance'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'This creates sandbox-only test earnings. It never adds real creator earnings or withdrawable live cash.',
            ),
            const SizedBox(height: 14),
            TextField(
              key: const Key('owner-qa-payout-username'),
              controller: usernameController,
              autocorrect: false,
              decoration: const InputDecoration(
                labelText: 'Tester username',
                prefixText: '@',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              key: const Key('owner-qa-payout-dollars'),
              controller: amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'QA payout balance',
                prefixText: r'$ ',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final username = usernameController.text.trim();
              final dollars = double.tryParse(amountController.text.trim());
              final cents = dollars == null ? 0 : (dollars * 100).round();
              Navigator.of(context).pop((username, cents));
            },
            child: const Text('Grant QA balance'),
          ),
        ],
      ),
    );
    usernameController.dispose();
    amountController.dispose();
    if (result == null) return;

    final username = result.$1.replaceFirst(RegExp(r'^@'), '').trim();
    final cents = result.$2;
    if (username.length < 3 || cents < 100 || cents > 100000) {
      _message('Enter a valid tester username and QA amount.');
      return;
    }

    setState(() => _busy = true);
    try {
      final raw = await _client.rpc(
        'owner_grant_creator_qa_earnings',
        params: {'p_username': username, 'p_amount_cents': cents},
      );
      final row = _firstRow(raw);
      final available = _int(row['qa_available_cents']);
      _message(
        '@$username now has ${_money(available)} of sandbox QA payout balance.',
      );
      await _refresh();
    } catch (error) {
      final value = error.toString().toLowerCase();
      _message(
        value.contains('tester profile not found')
            ? 'Tester username was not found.'
            : 'Could not grant QA payout balance.',
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

}

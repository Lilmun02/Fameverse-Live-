part of 'creator_studio_build23.dart';

extension _CreatorStudioPayoutActions on _Build23CreatorStudioScreenState {
Future<void> _editPayoutMethod() async {
    if (_busy) return;
    final controller = TextEditingController(
      text: _payoutMethod?.recipientEmail ?? '',
    );
    final email = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('PayPal payout email'),
        content: TextField(
          key: const Key('build23-paypal-payout-email'),
          controller: controller,
          keyboardType: TextInputType.emailAddress,
          autocorrect: false,
          textCapitalization: TextCapitalization.none,
          decoration: const InputDecoration(
            labelText: 'PayPal email',
            prefixIcon: Icon(Icons.paypal_outlined),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (email == null) return;
    final at = email.indexOf('@');
    if (at <= 0 || !email.substring(at + 1).contains('.')) {
      _message('Enter a valid PayPal email address.');
      return;
    }
    setState(() => _busy = true);
    try {
      await widget.backend.setPayoutMethod(recipientEmail: email);
      _message('PayPal payout method saved.');
      await _refresh();
    } catch (_) {
      _message('Could not save that payout method.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _requestPayout() async {
    if (!_summary.canRequestPayout || _busy) return;
    final controller = TextEditingController(
      text: (_summary.withdrawableCents / 100).toStringAsFixed(2),
    );
    final text = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Request payout'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Available: ${_money(_summary.withdrawableCents)}',
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            TextField(
              key: const Key('build23-payout-amount'),
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
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('Submit'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (text == null) return;
    final dollars = double.tryParse(text.trim());
    final cents = dollars == null ? 0 : (dollars * 100).round();
    if (cents < _summary.minimumPayoutCents) {
      _message('Minimum payout is ${_money(_summary.minimumPayoutCents)}.');
      return;
    }
    if (cents > _summary.withdrawableCents) {
      _message('That amount is higher than your available balance.');
      return;
    }
    setState(() => _busy = true);
    try {
      await widget.backend.requestPayout(cents);
      _message('Payout request submitted for review.');
      await _refresh();
    } catch (error) {
      final value = error.toString().toLowerCase();
      _message(
        value.contains('verification')
            ? 'Complete creator verification first.'
            : value.contains('payout method')
            ? 'Add a payout method first.'
            : 'Could not submit payout request.',
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

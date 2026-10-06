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
}

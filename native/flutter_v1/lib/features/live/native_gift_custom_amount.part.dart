part of 'native_live_components.dart';

extension _GiftCustomAmount on _NativeGiftTrayState {
Future<void> customAmount() async {
    var quantity = 1;
    final accepted = await showModalBottomSheet<int>(
      state.context: state.context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF17101F),
      builder: (state.context) {
        return StatefulBuilder(
          builder: (state.context, setModalState) {
            void setQuantity(int value) {
              setModalState(() => quantity = value.clamp(1, 100000));
            }

            return SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  20,
                  16,
                  20,
                  20 + MediaQuery.viewInsetsOf(state.context).bottom,
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
                        NativeGiftTrayVisual(gift: state._selected, size: 50),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Text(
                            state._selected.label,
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
                            initialValue: '$quantity',
                            textAlign: TextAlign.center,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Quantity',
                            ),
                            onChanged: (value) {
                              final parsed = int.tryParse(value);
                              if (parsed != null) setQuantity(parsed);
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
                          '🪙 ${state._selected.cost * quantity}',
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () => Navigator.of(state.context).pop(quantity),
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
    if (accepted != null && state.mounted) await state._send(accepted);
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fameverse_live/data/fameverse_live_backend.dart';
import 'package:fameverse_live/features/live/native_live_components.dart';

void main() {
  testWidgets('custom gift quantity stays synchronized through submission', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 1700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final unitCost = fvGiftById('rose')!.cost;
    int? sentQuantity;
    var sendCalls = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NativeGiftTray(
            coins: 100000,
            canRefill: false,
            onSend: (gift, quantity) async {
              expect(gift.id, 'rose');
              expect(gift.cost, unitCost);
              sentQuantity = quantity;
              sendCalls++;
              return false;
            },
            onRefill: () async => 100000,
          ),
        ),
      ),
    );

    await tester.tap(find.text('Custom'));
    await tester.pumpAndSettle();

    final input = find.byType(TextFormField);
    final sheet = find.byType(BottomSheet);
    String visibleQuantity() => tester
        .widget<TextField>(
          find.descendant(of: input, matching: find.byType(TextField)),
        )
        .controller!
        .text;

    void expectQuantity(int quantity) {
      expect(visibleQuantity(), '$quantity');
      expect(
        find.descendant(of: sheet, matching: find.text('Send ×$quantity')),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: sheet,
          matching: find.text('🪙 ${unitCost * quantity}'),
        ),
        findsOneWidget,
      );
      expect(sendCalls, 0);
    }

    expectQuantity(1);
    await tester.tap(find.byKey(const Key('gift-quantity-decrease')));
    await tester.pump();
    expectQuantity(1);

    await tester.tap(find.byKey(const Key('gift-quantity-increase')));
    await tester.pump();
    expectQuantity(2);
    await tester.tap(find.byKey(const Key('gift-quantity-decrease')));
    await tester.pump();
    expectQuantity(1);

    for (final quantity in [5, 10, 25, 50]) {
      await tester.tap(find.text('×$quantity'));
      await tester.pump();
      expectQuantity(quantity);
    }

    for (final value in ['', 'invalid', '1.5']) {
      await tester.enterText(input, value);
      await tester.pump();
      final submit = find.descendant(
        of: sheet,
        matching: find.byType(FilledButton),
      );
      expect(tester.widget<FilledButton>(submit).onPressed, isNull);
      expect(sendCalls, 0);
    }

    // Manually entered out-of-range values must also update the visible
    // quantity and total to the same bounded value.
    for (final value in ['0', '-1']) {
      await tester.enterText(input, value);
      await tester.pump();
      expectQuantity(1);
    }
    await tester.enterText(input, '100001');
    await tester.pump();
    expectQuantity(100000);

    await tester.enterText(input, '100000');
    await tester.pump();
    expectQuantity(100000);
    await tester.tap(find.byKey(const Key('gift-quantity-increase')));
    await tester.pump();
    expectQuantity(100000);

    await tester.enterText(input, '3');
    await tester.pump();
    expectQuantity(3);
    await tester.tap(find.text('Send ×3'));
    await tester.pumpAndSettle();
    expect(sentQuantity, 3);
    expect(sendCalls, 1);
  });
}

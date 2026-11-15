import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fameverse_live/features/live/native_live_components.dart';

void main() {
  testWidgets('custom quantity +/- and presets update visible field and send count', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 1700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    int? sentQuantity;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NativeGiftTray(
            coins: 100000,
            canRefill: false,
            onSend: (gift, quantity) async {
              expect(gift.id, 'rose');
              sentQuantity = quantity;
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
    String visibleQuantity() => tester
        .widget<TextField>(
          find.descendant(of: input, matching: find.byType(TextField)),
        )
        .controller!
        .text;

    expect(visibleQuantity(), '1');

    await tester.tap(find.byKey(const Key('gift-quantity-increase')));
    await tester.pump();
    expect(visibleQuantity(), '2');
    expect(find.text('Send ×2'), findsOneWidget);

    await tester.tap(find.byKey(const Key('gift-quantity-decrease')));
    await tester.pump();
    expect(visibleQuantity(), '1');
    expect(find.text('Send ×1'), findsOneWidget);

    await tester.tap(find.text('×10'));
    await tester.pump();
    expect(visibleQuantity(), '10');
    expect(find.text('Send ×10'), findsOneWidget);

    await tester.enterText(input, '');
    await tester.pump();
    expect(
      tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Send ×10')).onPressed,
      isNull,
    );

    await tester.enterText(input, '3');
    await tester.pump();
    expect(visibleQuantity(), '3');
    expect(find.text('Send ×3'), findsOneWidget);

    await tester.tap(find.text('Send ×3'));
    await tester.pumpAndSettle();
    expect(sentQuantity, 3);
  });
}

import 'package:fameverse_live/app/fameverse_app.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('native pipeline probe boots', (tester) async {
    await tester.pumpWidget(const FameverseApp());

    expect(find.byKey(FameverseApp.nativeProbeKey), findsOneWidget);
    expect(find.text('Native pipeline probe'), findsOneWidget);
  });
}

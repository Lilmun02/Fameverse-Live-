import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fameverse_live/data/fameverse_creator_backend.dart';
import 'package:fameverse_live/features/profile/creator_withdrawal_progress_card.dart';

FvCreatorPayoutSummary _summary(int availableCents) {
  return FvCreatorPayoutSummary(
    verificationStatus: 'unverified',
    pendingCents: 2000,
    availableCents: availableCents,
    reservedCents: 0,
    withdrawableCents: availableCents,
    paidCents: 0,
    minimumPayoutCents: 2500,
  );
}

void main() {
  testWidgets('shows $25 minimum and accurate cleared earnings progress', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FvWithdrawalProgressCard(summary: _summary(1000)),
        ),
      ),
    );

    expect(find.text('Minimum withdrawal'), findsOneWidget);
    expect(find.text(r'$25.00'), findsOneWidget);
    expect(find.text(r'$10.00 / $25.00 available'), findsOneWidget);
    expect(
      find.text(r'$15.00 more in cleared earnings to reach the minimum.'),
      findsOneWidget,
    );
    final bar = tester.widget<LinearProgressIndicator>(
      find.byKey(const Key('creator-withdrawal-progress-bar')),
    );
    expect(bar.value, 0.4);
    expect(
      find.textContaining('promotional/test gifts do not count'),
      findsOneWidget,
    );
  });

  testWidgets('caps progress at 100 percent, with no negative remainder', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FvWithdrawalProgressCard(summary: _summary(3100)),
        ),
      ),
    );

    final bar = tester.widget<LinearProgressIndicator>(
      find.byKey(const Key('creator-withdrawal-progress-bar')),
    );
    expect(bar.value, 1.0);
    expect(
      find.textContaining('Withdrawal minimum reached'),
      findsOneWidget,
    );
  });
}

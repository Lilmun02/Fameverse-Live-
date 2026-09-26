import 'package:fameverse_live/data/fameverse_backend.dart';
import 'package:fameverse_live/features/auth/auth_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('existing account sign in is the default auth mode', (
    tester,
  ) async {
    final backend = _AuthBackend();
    await tester.pumpWidget(MaterialApp(home: AuthScreen(backend: backend)));

    expect(find.byKey(const Key('auth-sign-in-title')), findsOneWidget);
    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.byKey(const Key('auth-display-name')), findsNothing);
    expect(find.widgetWithText(FilledButton, 'Sign in'), findsOneWidget);
  });

  testWidgets('sign in submits to signIn and never signUp', (tester) async {
    final backend = _AuthBackend();
    await tester.pumpWidget(MaterialApp(home: AuthScreen(backend: backend)));

    await tester.enterText(
      find.byKey(const Key('auth-email')),
      'existing@example.com',
    );
    await tester.enterText(find.byKey(const Key('auth-password')), 'secret123');
    final primary = find.byKey(const Key('auth-primary'));
    await tester.ensureVisible(primary);
    await tester.tap(primary);
    await tester.pumpAndSettle();

    expect(backend.signInCalls, 1);
    expect(backend.signUpCalls, 0);
    expect(backend.lastEmail, 'existing@example.com');
  });

  testWidgets('registered email in create mode returns user to sign in', (
    tester,
  ) async {
    final backend = _AuthBackend(rejectSignUpAsRegistered: true);
    await tester.pumpWidget(MaterialApp(home: AuthScreen(backend: backend)));

    await tester.tap(find.byKey(const Key('auth-mode-sign-up')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('auth-sign-up-title')), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('auth-display-name')),
      'Existing User',
    );
    await tester.enterText(
      find.byKey(const Key('auth-email')),
      'existing@example.com',
    );
    await tester.enterText(find.byKey(const Key('auth-password')), 'secret123');
    final primary = find.byKey(const Key('auth-primary'));
    await tester.ensureVisible(primary);
    await tester.tap(primary);
    await tester.pumpAndSettle();

    expect(backend.signUpCalls, 1);
    expect(find.byKey(const Key('auth-sign-in-title')), findsOneWidget);
    expect(
      find.text('That email already has a Fameverse account. Sign in instead.'),
      findsOneWidget,
    );
  });
}

class _AuthBackend implements FameverseBackend {
  _AuthBackend({this.rejectSignUpAsRegistered = false});

  final bool rejectSignUpAsRegistered;
  FvIdentity? _identity;
  int signInCalls = 0;
  int signUpCalls = 0;
  String? lastEmail;

  @override
  FvIdentity? get currentIdentity => _identity;

  @override
  Stream<FvIdentity?> get authChanges => const Stream.empty();

  @override
  Future<void> signIn({required String email, required String password}) async {
    signInCalls += 1;
    lastEmail = email;
    _identity = FvIdentity(id: 'existing-user', email: email);
  }

  @override
  Future<FvAuthResult> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    signUpCalls += 1;
    if (rejectSignUpAsRegistered) {
      throw Exception('User already registered');
    }
    return const FvAuthResult(
      signedIn: false,
      message: 'Account created. Sign in to continue.',
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/pump_app.dart';

void main() {
  testWidgets('wrong password is refused, right one lands on the dashboard', (
    tester,
  ) async {
    useDesktopSurface(tester);
    await pumpApp(tester);

    expect(find.text('Welcome back'), findsOneWidget);

    await signIn(tester, password: 'nope-nope');
    expect(find.text('Wrong email or password'), findsOneWidget);
    expect(find.text('Welcome back'), findsOneWidget);

    await signIn(tester);
    expect(find.text('Dashboard'), findsWidgets);
    expect(find.text('Recent releases'), findsOneWidget);
  });

  testWidgets('a new account can register and sees an empty dashboard', (
    tester,
  ) async {
    useDesktopSurface(tester);
    await pumpApp(tester);

    await tester.tap(find.text('No account yet? Create one'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), 'Ada Lovelace');
    await tester.enterText(find.byType(TextFormField).at(1), 'ada@example.com');
    await tester.enterText(find.byType(TextFormField).at(2), 'engine-1843');
    await tester.tap(find.widgetWithText(FilledButton, 'Create account'));
    await tester.pumpAndSettle();

    // The address has to be confirmed with the mailed code first.
    expect(find.text('Enter the code'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, '000000');
    await tester.tap(find.widgetWithText(FilledButton, 'Verify'));
    await tester.pumpAndSettle();
    expect(find.text('That code is not right'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, '123456');
    await tester.tap(find.widgetWithText(FilledButton, 'Verify'));
    await tester.pumpAndSettle();

    // A new account lands on the checklist, then on an empty dashboard.
    expect(find.text('Set up your first release'), findsOneWidget);
    expect(find.text('0 of 4 done'), findsOneWidget);
    await tester.tap(find.text('Skip for now'));
    await tester.pumpAndSettle();
    expect(find.text('Getting started'), findsOneWidget);
    expect(find.text('No releases yet'), findsOneWidget);
  });

  testWidgets('phone layout uses the bottom bar', (tester) async {
    usePhoneSurface(tester);
    await pumpApp(tester);
    await signIn(tester);

    expect(find.byType(NavigationBar), findsOneWidget);
    await tester.tap(find.text('Applications'));
    await tester.pumpAndSettle();
    expect(find.text('Acme Shop'), findsOneWidget);
  });
}

import 'package:apprelease/src/routing/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/pump_app.dart';

void main() {
  testWidgets('a release cannot start while something is missing', (
    tester,
  ) async {
    useDesktopSurface(tester);
    await pumpApp(tester);
    await signIn(tester);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(Scaffold).first),
    );
    container.read(goRouterProvider).go('/apps/app-demo');
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Start release').first);
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsOneWidget);

    // Android: the demo has a keystore and Google Play, so it may start.
    FilledButton start() => tester.widget<FilledButton>(
      find.descendant(
        of: find.byType(Dialog),
        matching: find.widgetWithText(FilledButton, 'Start release'),
      ),
    );
    expect(start().onPressed, isNotNull);

    // iOS: no App Store Connect key yet. Listed, with a fix, and blocked.
    await tester.tap(
      find.descendant(of: find.byType(Dialog), matching: find.text('iOS')),
    );
    await tester.pumpAndSettle();
    expect(find.text('App Store Connect key'), findsWidgets);
    expect(find.textContaining('1 thing to fix'), findsOneWidget);
    expect(start().onPressed, isNull);
  });
}

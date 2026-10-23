import 'package:apprelease/src/features/apps/data/apps_repository.dart';
import 'package:apprelease/src/routing/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/pump_app.dart';

void main() {
  testWidgets('a second push rule is saved', (tester) async {
    useDesktopSurface(tester);
    await pumpApp(tester);
    await signIn(tester);
    await tester.pumpAndSettle();
    final container = ProviderScope.containerOf(
      tester.element(find.byType(Scaffold).first),
    );
    container.read(goRouterProvider).go('/apps/app-demo?tab=settings');
    await tester.pumpAndSettle();
    final list = find.byType(SingleChildScrollView).last;

    await tester.dragUntilVisible(
      find.text('Release automatically on push'),
      list,
      const Offset(0, -200),
    );
    await tester.tap(find.text('Release automatically on push'));
    await tester.pumpAndSettle();
    await tester.dragUntilVisible(
      find.text('Add a branch'),
      list,
      const Offset(0, -200),
    );
    await tester.tap(find.text('Add a branch'));
    await tester.pumpAndSettle();
    await tester.dragUntilVisible(
      find.widgetWithText(FilledButton, 'Save'),
      list,
      const Offset(0, -200),
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();

    final app = container
        .read(appsStreamProvider)
        .value!
        .firstWhere((a) => a.id == 'app-demo');
    expect([for (final r in app.pushRules) r.branch], ['main', 'develop']);
  });
}

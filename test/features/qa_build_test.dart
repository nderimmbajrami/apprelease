import 'package:apprelease/src/features/credentials/data/credentials_repository.dart';
import 'package:apprelease/src/features/credentials/domain/credential.dart';
import 'package:apprelease/src/routing/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/pump_app.dart';

void main() {
  testWidgets('a QA build waits for a Slack connection; adding one through '
      'the form unblocks it', (tester) async {
    useDesktopSurface(tester);
    await pumpApp(tester);
    await signIn(tester);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(Scaffold).first),
    );
    final router = container.read(goRouterProvider);

    Future<void> openQaDialog() async {
      router.go('/apps/app-demo');
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Publish').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('QA build (APK to Slack)'));
      await tester.pumpAndSettle();
    }

    FilledButton start() => tester.widget<FilledButton>(
      find.descendant(
        of: find.byType(Dialog),
        matching: find.widgetWithText(FilledButton, 'Publish'),
      ),
    );

    // The demo app has a keystore and Google Play, but no Slack: a store
    // release may start, a QA build may not, and Google Play is not asked
    // of it.
    await openQaDialog();
    expect(find.text('Slack channel for QA'), findsOneWidget);
    expect(find.text('Google Play access'), findsNothing);
    expect(find.textContaining('Nothing goes to Google Play'), findsOneWidget);
    expect(start().onPressed, isNull);
    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();

    // Add the Slack connection through the form.
    router.go('/credentials');
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Add credential').first);
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(Dialog),
        matching: find.text('Slack (QA builds)'),
      ),
    );
    await tester.pumpAndSettle();
    final form = find.descendant(
      of: find.byType(Dialog),
      matching: find.byType(SingleChildScrollView),
    );
    final save = find.descendant(
      of: find.byType(Dialog),
      matching: find.widgetWithText(FilledButton, 'Add credential'),
    );

    // A #name is not a channel ID, and a user token is not a bot token.
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Bot User OAuth Token'),
      'xoxp-user-token',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Channel ID'),
      '#qa-builds',
    );
    await tester.dragUntilVisible(save, form, const Offset(0, -200));
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(find.text('A bot token starts with xoxb-.'), findsOneWidget);
    expect(find.textContaining('looks like C0123ABCDEF'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Bot User OAuth Token'),
      'xoxb-123-abc',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Channel ID'),
      'C0123ABCDEF',
    );
    await tester.dragUntilVisible(save, form, const Offset(0, -200));
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsNothing);

    final slack = container
        .read(credentialsStreamProvider)
        .value!
        .singleWhere((c) => c.kind == CredentialKind.slack);
    expect(slack.name, 'slack_qa');
    expect(slack.meta, {'channel': 'C0123ABCDEF'});
    expect(find.textContaining('channel C0123ABCDEF'), findsOneWidget);

    // Now the QA build may start.
    await openQaDialog();
    expect(start().onPressed, isNotNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the Jira form keeps the site, the status and the projects', (
    tester,
  ) async {
    useDesktopSurface(tester);
    await pumpApp(tester);
    await signIn(tester);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(Scaffold).first),
    );
    container.read(goRouterProvider).go('/credentials');
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Add credential').first);
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(Dialog),
        matching: find.text('Jira (QA tickets)'),
      ),
    );
    await tester.pumpAndSettle();
    final form = find.descendant(
      of: find.byType(Dialog),
      matching: find.byType(SingleChildScrollView),
    );
    Future<void> type(String label, String text) async {
      final field = find.widgetWithText(TextFormField, label);
      await tester.dragUntilVisible(field, form, const Offset(0, -150));
      await tester.enterText(field, text);
    }

    await type('Jira site', 'acme.atlassian.net');
    await type('Atlassian account email', 'qa@acme.test');
    await type('API token', 'secret-token');
    await type('Project keys (optional)', 'dama, app');
    final save = find.descendant(
      of: find.byType(Dialog),
      matching: find.widgetWithText(FilledButton, 'Add credential'),
    );
    await tester.dragUntilVisible(save, form, const Offset(0, -200));
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsNothing);

    final jira = container
        .read(credentialsStreamProvider)
        .value!
        .singleWhere((c) => c.kind == CredentialKind.jira);
    expect(jira.meta, {
      'site': 'acme.atlassian.net',
      'email': 'qa@acme.test',
      'status': 'Ready for QA',
      'projects': 'DAMA, APP',
    });
    // The token is the secret: it is nowhere in what the console keeps.
    expect(jira.meta.values.join(), isNot(contains('secret-token')));
    expect(tester.takeException(), isNull);
  });
}

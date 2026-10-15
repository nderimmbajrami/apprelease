import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/pump_app.dart';

void main() {
  testWidgets('adding an app and releasing it walks every step to Published', (
    tester,
  ) async {
    useDesktopSurface(tester);
    await pumpApp(tester);
    await signIn(tester);

    // Add an application through the wizard.
    await tester.tap(find.widgetWithText(OutlinedButton, 'Add application'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextFormField).at(0),
      'https://github.com/acme/weather-app.git',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Next'));
    await tester.pumpAndSettle();
    // The name was guessed from the repository.
    expect(find.widgetWithText(TextFormField, 'Weather App'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Next'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextFormField).at(0),
      'com.acme.weather',
    );
    await tester.enterText(
      find.byType(TextFormField).at(1),
      'com.acme.weather',
    );
    await tester.tap(
      find.widgetWithText(FilledButton, 'Finish: Add application'),
    );
    await tester.pumpAndSettle();

    expect(find.text('Weather App'), findsWidgets);
    expect(
      find.text('This application has not been released yet.'),
      findsOneWidget,
    );

    // Start a release from the header button.
    await tester.tap(find.widgetWithText(FilledButton, 'Start release').first);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, '1.0.0'),
      '1.4.0',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Start release').last);
    // No pumpAndSettle here: the running badge pulses until the release
    // ends, so settle would mean "wait for the whole pipeline".
    await pumpFrames(tester, const Duration(seconds: 1));

    // On the release page: the runner has claimed it and the timeline is up.
    expect(find.text('Running'), findsOneWidget);
    expect(find.text('Cancel release'), findsOneWidget);
    expect(find.text('Check out repository'), findsOneWidget);
    expect(find.text('Upload to Google Play'), findsOneWidget);

    await pumpFrames(tester, const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(find.text('Published'), findsOneWidget);
    expect(find.textContaining('1.4.0 (57)'), findsWidgets);
    expect(
      find.textContaining('Released 1.4.0 (57) to Google Play'),
      findsOneWidget,
    );
    expect(find.text('app-release.aab'), findsOneWidget);
  });

  testWidgets('a running release can be cancelled', (tester) async {
    useDesktopSurface(tester);
    await pumpApp(tester, stepDuration: const Duration(seconds: 2));
    await signIn(tester);

    await tester.tap(find.text('Applications'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Acme Shop'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Start release').first);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Start release').last);
    await pumpFrames(tester, const Duration(milliseconds: 1500));
    expect(find.text('Running'), findsOneWidget);

    await tester.tap(find.text('Cancel release'));
    await tester.pumpAndSettle();
    expect(find.text('Cancelled'), findsOneWidget);
    expect(find.text('Cancelled by user'), findsOneWidget);

    // The simulation stopped: nothing changes any more.
    await pumpFrames(tester, const Duration(seconds: 20));
    await tester.pumpAndSettle();
    expect(find.text('Cancelled'), findsOneWidget);
    expect(find.text('Published'), findsNothing);
  });

  testWidgets('demo releases are listed newest first with their state', (
    tester,
  ) async {
    useDesktopSurface(tester);
    await pumpApp(tester);
    await signIn(tester);

    expect(find.text('Published'), findsNWidgets(2));
    expect(find.text('Failed'), findsOneWidget);

    await tester.tap(find.text('Failed'));
    await tester.pumpAndSettle();
    expect(find.textContaining('No profiles for'), findsWidgets);
    expect(find.text('Run again'), findsOneWidget);
  });
}

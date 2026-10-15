import 'package:apprelease/src/app/app.dart';
import 'package:apprelease/src/core/data/backend.dart';
import 'package:apprelease/src/core/preferences/preferences_service.dart';
import 'package:apprelease/src/features/auth/data/auth_repository.dart';
import 'package:apprelease/src/features/auth/data/local_auth_repository.dart';
import 'package:apprelease/src/features/releases/data/local_releases_repository.dart';
import 'package:apprelease/src/features/releases/data/releases_repository.dart';
import 'package:apprelease/src/routing/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Renders at desk width so the rail (not the bottom bar) is built.
void useDesktopSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(1440, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

/// Renders at phone width.
void usePhoneSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

/// The simulated runner the current test is driving.
late LocalReleasesRepository testReleases;

/// Boots the real app against in-memory data with empty device preferences.
Future<void> pumpApp(
  WidgetTester tester, {
  List<Override> overrides = const [],
  String? initialLocation,
  Duration stepDuration = const Duration(milliseconds: 200),
}) async {
  await initializeDateFormatting();
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();

  final auth = LocalAuthRepository();
  testReleases = LocalReleasesRepository(stepDuration: stepDuration);
  addTearDown(auth.dispose);
  addTearDown(testReleases.dispose);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        // Tests run on the in-memory backend; the Supabase client is never
        // constructed, so nothing reaches the network.
        backendProvider.overrideWithValue(Backend.local),
        authRepositoryProvider.overrideWith((ref) => auth),
        releasesRepositoryProvider.overrideWith((ref) => testReleases),
        if (initialLocation != null)
          initialLocationProvider.overrideWithValue(initialLocation),
        ...overrides,
      ],
      child: const AppReleaseApp(),
    ),
  );
  await tester.pumpAndSettle();
}

/// Signs in through the real form so redirects are exercised too.
Future<void> signIn(
  WidgetTester tester, {
  String email = LocalAuthRepository.demoEmail,
  String password = LocalAuthRepository.demoPassword,
}) async {
  await tester.enterText(find.byType(TextFormField).at(0), email);
  await tester.enterText(find.byType(TextFormField).at(1), password);
  await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
  await tester.pumpAndSettle();
}

/// Advances [duration] in 100 ms frames. `pumpAndSettle` cannot be used
/// while a release runs — the pulsing badge never settles — and a single
/// long pump renders only one frame, which may skip the route transition.
Future<void> pumpFrames(WidgetTester tester, Duration duration) async {
  const frame = Duration(milliseconds: 100);
  var elapsed = Duration.zero;
  while (elapsed < duration) {
    await tester.pump(frame);
    elapsed += frame;
  }
}

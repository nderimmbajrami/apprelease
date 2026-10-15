import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../core/widgets/app_shell.dart';
import '../features/apps/presentation/add_app_screen.dart';
import '../features/apps/presentation/app_detail_screen.dart';
import '../features/apps/presentation/apps_screen.dart';
import '../features/auth/data/auth_repository.dart';
import '../features/auth/presentation/auth_controller.dart';
import '../features/auth/presentation/sign_in_screen.dart';
import '../features/auth/presentation/sign_up_screen.dart';
import '../features/credentials/presentation/credentials_screen.dart';
import '../features/home/presentation/dashboard_screen.dart';
import '../features/onboarding/presentation/setup_screen.dart';
import '../features/releases/presentation/release_detail_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import 'app_routes.dart';
import 'not_found_screen.dart';

part 'app_router.g.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

/// Where the app opens. A test can start anywhere.
@Riverpod(keepAlive: true)
String initialLocation(Ref ref) => AppRoute.home.path;

/// The app's single [GoRouter].
///
/// Kept alive for the whole app lifetime — rebuilding it would reset the
/// navigation stack. Auth changes reach it through [refreshListenable], so
/// signing in or out re-runs the redirect only.
@Riverpod(keepAlive: true)
GoRouter goRouter(Ref ref) {
  final refresh = ValueNotifier<int>(0);
  ref
    ..onDispose(refresh.dispose)
    ..listen(
      authStateChangesProvider,
      (_, _) => refresh.value++,
      fireImmediately: true,
    );

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: ref.watch(initialLocationProvider),
    refreshListenable: refresh,
    errorBuilder: (context, state) => const NotFoundScreen(),
    redirect: (context, state) {
      final auth = ref.read(authStateChangesProvider);
      // Wait for the first auth event before deciding anything.
      if (auth.isLoading && !auth.hasValue) return null;

      final user = auth.value;
      final location = state.matchedLocation;
      final isOnAuthScreen =
          location == AppRoute.signIn.path || location == AppRoute.signUp.path;

      if (user == null) return isOnAuthScreen ? null : AppRoute.signIn.path;
      if (isOnAuthScreen) {
        // A brand new account is asked for what a release needs first.
        return ref.read(freshSignUpProvider)
            ? AppRoute.setup.path
            : AppRoute.home.path;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoute.signIn.path,
        name: AppRoute.signIn.name,
        builder: (context, state) => const SignInScreen(),
      ),
      GoRoute(
        path: AppRoute.signUp.path,
        name: AppRoute.signUp.name,
        builder: (context, state) => const SignUpScreen(),
      ),
      // Everything behind the login shares one frame.
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: AppRoute.home.path,
            name: AppRoute.home.name,
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: AppRoute.setup.path,
            name: AppRoute.setup.name,
            builder: (context, state) => const SetupScreen(),
          ),
          GoRoute(
            path: AppRoute.apps.path,
            name: AppRoute.apps.name,
            builder: (context, state) => const AppsScreen(),
            routes: [
              GoRoute(
                path: AppRoute.appNew.path,
                name: AppRoute.appNew.name,
                builder: (context, state) => const AddAppScreen(),
              ),
              GoRoute(
                path: AppRoute.appDetail.path,
                name: AppRoute.appDetail.name,
                builder: (context, state) => AppDetailScreen(
                  appId: state.pathParameters['appId']!,
                  tab: state.uri.queryParameters['tab'],
                ),
                routes: [
                  GoRoute(
                    path: AppRoute.release.path,
                    name: AppRoute.release.name,
                    builder: (context, state) => ReleaseDetailScreen(
                      appId: state.pathParameters['appId']!,
                      releaseId: state.pathParameters['releaseId']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: AppRoute.credentials.path,
            name: AppRoute.credentials.name,
            builder: (context, state) => const CredentialsScreen(),
          ),
          GoRoute(
            path: AppRoute.settings.path,
            name: AppRoute.settings.name,
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),
    ],
  );
}

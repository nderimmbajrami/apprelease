/// Every route in the console, declared once.
enum AppRoute {
  /// Shown until the session is known, so nothing else flashes first.
  starting('/starting'),
  signIn('/sign-in'),
  signUp('/sign-up'),

  home('/'),
  setup('/setup'),
  apps('/apps'),
  appNew('new'),
  appDetail(':appId'),
  release('releases/:releaseId'),
  credentials('/credentials'),
  settings('/settings');

  const AppRoute(this.path);

  final String path;
}

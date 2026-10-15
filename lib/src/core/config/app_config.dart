/// Build-time configuration.
///
/// The Supabase URL and publishable key are meant to ship with the client; the
/// service role key never leaves the runner and the Edge Functions.
/// Override per build with:
///
///   flutter run --dart-define=SUPABASE_URL=...
///               --dart-define=SUPABASE_PUBLISHABLE_KEY=...
abstract final class AppConfig {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');

  static const supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
  );

  /// Set `--dart-define=USE_SUPABASE=false` to run the console on in-memory
  /// demo data instead of the real backend. That is also what the tests use,
  /// and what runs until a Supabase project is configured.
  static const useSupabase = bool.fromEnvironment(
    'USE_SUPABASE',
    defaultValue: true,
  );

  /// `--dart-define=DEMO_AUTO_SIGN_IN=true` opens the in-memory demo already
  /// signed in, for a public demo build or a screenshot run. Ignored when
  /// Supabase is enabled.
  static const demoAutoSignIn = bool.fromEnvironment(
    'DEMO_AUTO_SIGN_IN',
    defaultValue: false,
  );

  /// Where the marketing site and the docs live.
  static const siteUrl = 'https://apprelease.store';
  static const docsUrl = '$siteUrl/docs/';

  /// Where GitHub posts push events for an app.
  static String webhookUrl(String appId) =>
      '$supabaseUrl/functions/v1/github-webhook?app=$appId';

  static bool get isSupabaseEnabled =>
      useSupabase && supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}

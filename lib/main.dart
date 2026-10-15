import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'src/app/app.dart';
import 'src/core/config/app_config.dart';
import 'src/core/observers/provider_logger.dart';
import 'src/core/preferences/preferences_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Everything that must be ready before the first frame is loaded here and
  // injected through `overrides` — providers stay synchronous as a result.
  await initializeDateFormatting();
  final prefs = await SharedPreferences.getInstance();

  if (AppConfig.isSupabaseEnabled) {
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      publishableKey: AppConfig.supabaseAnonKey,
    );
  }

  runApp(
    ProviderScope(
      observers: const [ProviderLogger()],
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const AppReleaseApp(),
    ),
  );
}

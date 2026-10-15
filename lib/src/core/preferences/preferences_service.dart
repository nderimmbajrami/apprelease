import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'preferences_service.g.dart';

/// Device-local settings. Everything else in the app is shared team data.
class PreferencesService {
  const PreferencesService(this._prefs);

  static const _themeKey = 'theme_mode';

  final SharedPreferences _prefs;

  ThemeMode readThemeMode() {
    final name = _prefs.getString(_themeKey);
    return ThemeMode.values.firstWhere(
      (mode) => mode.name == name,
      orElse: () => ThemeMode.system,
    );
  }

  Future<void> writeThemeMode(ThemeMode mode) =>
      _prefs.setString(_themeKey, mode.name);
}

/// Overridden in `main()` once [SharedPreferences] has loaded.
@Riverpod(keepAlive: true)
SharedPreferences sharedPreferences(Ref ref) =>
    throw UnimplementedError('sharedPreferencesProvider must be overridden');

@Riverpod(keepAlive: true)
PreferencesService preferencesService(Ref ref) =>
    PreferencesService(ref.watch(sharedPreferencesProvider));

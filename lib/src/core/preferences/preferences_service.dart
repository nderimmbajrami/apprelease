import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'preferences_service.g.dart';

/// Device-local settings. Everything else in the app is shared team data.
class PreferencesService {
  const PreferencesService(this._prefs);

  static const _themeKey = 'theme_mode';
  static const _setupKey = 'setup_dismissed';
  static const _tourKey = 'tour_seen';

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

  /// Whether the setup checklist was put away on this device.
  bool readSetupDismissed() => _prefs.getBool(_setupKey) ?? false;

  Future<void> writeSetupDismissed(bool value) =>
      _prefs.setBool(_setupKey, value);

  /// Whether the guided tour ran (or was skipped) on this device.
  bool readTourSeen() => _prefs.getBool(_tourKey) ?? false;

  Future<void> writeTourSeen(bool value) => _prefs.setBool(_tourKey, value);
}

/// Overridden in `main()` once [SharedPreferences] has loaded.
@Riverpod(keepAlive: true)
SharedPreferences sharedPreferences(Ref ref) =>
    throw UnimplementedError('sharedPreferencesProvider must be overridden');

@Riverpod(keepAlive: true)
PreferencesService preferencesService(Ref ref) =>
    PreferencesService(ref.watch(sharedPreferencesProvider));

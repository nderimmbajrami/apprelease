import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'preferences_service.g.dart';

/// Device-local settings. Everything else in the app is shared team data.
class PreferencesService {
  const PreferencesService(this._prefs);

  static const _themeKey = 'theme_mode';
  static const _setupKey = 'setup_dismissed';
  // v2: the first key was burnt by a tour that fired on the sign-in page.
  static const _tourKey = 'tour_seen_v2';
  static const _storesKey = 'setup_stores';

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

  /// The stores a new team said it publishes to, as platform names, before
  /// it has an app. Both by default.
  Set<String> readStores() =>
      (_prefs.getStringList(_storesKey) ?? const ['android', 'ios']).toSet();

  Future<void> writeStores(Set<String> names) =>
      _prefs.setStringList(_storesKey, names.toList());

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

import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../preferences/preferences_service.dart';

part 'theme_mode_controller.g.dart';

/// App-wide light/dark selection, stored per device.
@Riverpod(keepAlive: true)
class ThemeModeController extends _$ThemeModeController {
  @override
  ThemeMode build() => ref.watch(preferencesServiceProvider).readThemeMode();

  Future<void> set(ThemeMode mode) async {
    state = mode;
    await ref.read(preferencesServiceProvider).writeThemeMode(mode);
  }
}

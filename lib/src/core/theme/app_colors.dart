import 'package:flutter/material.dart';

/// The console's palette, the same as the website: warm off-white paper,
/// near-black ink, one green for "done" and "live". Flat; no gradients.
/// Only [AppTheme] reads these; widgets go through `Theme.of(context)`.
abstract final class AppColors {
  // ------------------------------------------------------------------ light
  static const paper = Color(0xFFFAFAF7);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceMuted = Color(0xFFF1F1EC);
  static const ink = Color(0xFF111111);
  static const muted = Color(0xFF4A4A46);
  static const line = Color(0xFFE3E3DE);

  /// The one colour that acts: buttons, the selected entry.
  static const indigo = Color(0xFF111111);
  static const indigoDeep = Color(0xFF000000);
  static const indigoSoft = Color(0xFFF1F1EC);

  static const mint = Color(0xFF1D6B3F);
  static const amber = Color(0xFF9A5B00);
  static const danger = Color(0xFFB3261E);

  // ------------------------------------------------------------------- dark
  static const paperDark = Color(0xFF121210);
  static const surfaceDark = Color(0xFF1A1A17);
  static const surfaceMutedDark = Color(0xFF24241F);
  static const inkDark = Color(0xFFECECE7);
  static const mutedDark = Color(0xFFA3A39C);
  static const lineDark = Color(0xFF2E2E29);
  static const indigoDark = Color(0xFFECECE7);
  static const indigoSoftDark = Color(0xFF2E2E29);
  static const mintDark = Color(0xFF4CAF7D);
  static const amberDark = Color(0xFFE0A24A);
  static const dangerDark = Color(0xFFF07167);

  static const running = indigo;
  static const runningDark = indigoDark;

  /// Card shadow: none. Borders do the work.
  static const cardShadow = <BoxShadow>[];
}

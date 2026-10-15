import 'package:flutter/material.dart';

/// The console's palette: the landing page's deep navy and indigo accent by
/// night, white sheets on a cool grey ground by day. Only [AppTheme] reads
/// these; widgets go through `Theme.of(context).colorScheme`.
abstract final class AppColors {
  // ------------------------------------------------------------------ light
  static const paper = Color(0xFFF5F7FB);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceMuted = Color(0xFFEEF2F8);
  static const ink = Color(0xFF0F1B2D);
  static const muted = Color(0xFF55657F);
  static const line = Color(0xFFE1E7F0);

  /// The one colour that acts.
  static const indigo = Color(0xFF4F6DF5);
  static const indigoDeep = Color(0xFF3651C9);
  static const indigoSoft = Color(0xFFE7ECFE);

  static const mint = Color(0xFF0E9F6E);
  static const amber = Color(0xFFB45309);
  static const danger = Color(0xFFC0392B);

  // ------------------------------------------------------------------- dark
  static const paperDark = Color(0xFF070B14);
  static const surfaceDark = Color(0xFF0F172A);
  static const surfaceMutedDark = Color(0xFF162036);
  static const inkDark = Color(0xFFE9EEF8);
  static const mutedDark = Color(0xFF93A0B8);
  static const lineDark = Color(0xFF1F2A40);
  static const indigoDark = Color(0xFF7B93FF);
  static const indigoSoftDark = Color(0xFF1C2747);
  static const mintDark = Color(0xFF34D399);
  static const amberDark = Color(0xFFFBBF24);
  static const dangerDark = Color(0xFFF07167);

  /// Step and release states, both brightnesses.
  static const running = indigo;
  static const runningDark = indigoDark;

  /// Card shadow — barely there, but it lifts the cards off the page.
  static const cardShadow = [
    BoxShadow(color: Color(0x0A0F1B2D), blurRadius: 2, offset: Offset(0, 1)),
    BoxShadow(color: Color(0x120F1B2D), blurRadius: 20, offset: Offset(0, 8)),
  ];
}

import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_spacing.dart';

/// Single source of truth for the console's look.
abstract final class AppTheme {
  static const sansFamily = 'Inter';

  /// Logs, version numbers, commit hashes and durations are set in a mono
  /// face so they line up.
  static const monoFamily = 'JetBrainsMono';

  /// Below this the UI switches from the desk layout to the phone layout.
  static const compactWidth = 760.0;

  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isLight = brightness == Brightness.light;
    final accent = isLight ? AppColors.indigo : AppColors.indigoDark;

    final scheme = ColorScheme(
      brightness: brightness,
      primary: accent,
      onPrimary: isLight ? Colors.white : const Color(0xFF07101C),
      primaryContainer: isLight
          ? AppColors.indigoSoft
          : AppColors.indigoSoftDark,
      onPrimaryContainer: isLight ? AppColors.indigoDeep : AppColors.indigoDark,
      secondary: accent,
      onSecondary: isLight ? Colors.white : const Color(0xFF07101C),
      secondaryContainer: isLight
          ? AppColors.indigoSoft
          : AppColors.indigoSoftDark,
      onSecondaryContainer: isLight
          ? AppColors.indigoDeep
          : AppColors.indigoDark,
      tertiary: isLight ? AppColors.mint : AppColors.mintDark,
      onTertiary: isLight ? Colors.white : const Color(0xFF07101C),
      tertiaryContainer: isLight
          ? const Color(0xFFDDF5EB)
          : const Color(0xFF0F2A22),
      onTertiaryContainer: isLight ? AppColors.mint : AppColors.mintDark,
      error: isLight ? AppColors.danger : AppColors.dangerDark,
      onError: Colors.white,
      errorContainer: isLight
          ? const Color(0xFFFBE6E3)
          : const Color(0xFF331916),
      onErrorContainer: isLight ? AppColors.danger : AppColors.dangerDark,
      surface: isLight ? AppColors.paper : AppColors.paperDark,
      onSurface: isLight ? AppColors.ink : AppColors.inkDark,
      surfaceContainerLowest: isLight
          ? AppColors.surface
          : AppColors.surfaceDark,
      surfaceContainerLow: isLight ? AppColors.surface : AppColors.surfaceDark,
      surfaceContainer: isLight
          ? AppColors.surfaceMuted
          : AppColors.surfaceMutedDark,
      surfaceContainerHigh: isLight
          ? AppColors.surfaceMuted
          : AppColors.surfaceMutedDark,
      surfaceContainerHighest: isLight
          ? const Color(0xFFE4EAF3)
          : const Color(0xFF1C2740),
      onSurfaceVariant: isLight ? AppColors.muted : AppColors.mutedDark,
      outline: isLight ? AppColors.line : AppColors.lineDark,
      outlineVariant: isLight ? AppColors.line : AppColors.lineDark,
      shadow: Colors.black,
      scrim: Colors.black54,
      inverseSurface: isLight ? AppColors.ink : AppColors.inkDark,
      onInverseSurface: isLight ? Colors.white : AppColors.ink,
      inversePrimary: isLight ? AppColors.indigoDark : AppColors.indigo,
      surfaceTint: Colors.transparent,
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      fontFamily: sansFamily,
    );

    return base.copyWith(
      scaffoldBackgroundColor: scheme.surface,
      canvasColor: scheme.surface,
      textTheme: _textTheme(base.textTheme, scheme),
      dividerTheme: DividerThemeData(
        color: scheme.outline,
        thickness: 1,
        space: 1,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: sansFamily,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: scheme.onSurface,
        ),
      ),
      cardTheme: CardThemeData(
        color: scheme.surfaceContainerLowest,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.lg),
          side: BorderSide(color: scheme.outline),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.xl),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(Radii.xl)),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          minimumSize: const Size(0, 46),
          textStyle: const TextStyle(
            fontFamily: sansFamily,
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Radii.md),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.onSurface,
          backgroundColor: scheme.surfaceContainerLowest,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          minimumSize: const Size(0, 46),
          side: BorderSide(color: scheme.outline),
          textStyle: const TextStyle(
            fontFamily: sansFamily,
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Radii.md),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(0, 46),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          foregroundColor: scheme.secondary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Radii.md),
          ),
          textStyle: const TextStyle(
            fontFamily: sansFamily,
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          backgroundColor: scheme.surfaceContainerLowest,
          foregroundColor: scheme.onSurfaceVariant,
          selectedBackgroundColor: scheme.secondaryContainer,
          selectedForegroundColor: scheme.onSecondaryContainer,
          side: BorderSide(color: scheme.outline),
          textStyle: const TextStyle(
            fontFamily: sansFamily,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Radii.md),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isLight ? AppColors.surface : scheme.surfaceContainerHigh,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        labelStyle: TextStyle(
          color: scheme.onSurfaceVariant,
          fontWeight: FontWeight.w500,
        ),
        hintStyle: TextStyle(color: scheme.onSurfaceVariant),
        border: _border(scheme.outline),
        enabledBorder: _border(scheme.outline),
        focusedBorder: _border(accent, width: 1.8),
        errorBorder: _border(scheme.error),
        focusedErrorBorder: _border(scheme.error, width: 1.8),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: scheme.surfaceContainerHigh,
        side: BorderSide(color: scheme.outline),
        labelStyle: TextStyle(
          fontFamily: sansFamily,
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: scheme.onSurface,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.sm),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isLight ? AppColors.ink : AppColors.surfaceMutedDark,
        contentTextStyle: TextStyle(
          fontFamily: sansFamily,
          fontSize: 14,
          color: isLight ? Colors.white : AppColors.inkDark,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.md),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: scheme.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.md),
          side: BorderSide(color: scheme.outline),
        ),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: scheme.onSurface,
        unselectedLabelColor: scheme.onSurfaceVariant,
        indicatorColor: scheme.primary,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: scheme.outline,
        labelStyle: const TextStyle(
          fontFamily: sansFamily,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
        unselectedLabelStyle: const TextStyle(
          fontFamily: sansFamily,
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
      ),
    );
  }

  static TextTheme _textTheme(TextTheme base, ColorScheme scheme) {
    TextStyle sans(double size, FontWeight weight, {double tracking = 0}) =>
        TextStyle(
          fontFamily: sansFamily,
          fontSize: size,
          fontWeight: weight,
          letterSpacing: tracking,
          color: scheme.onSurface,
          height: 1.35,
        );

    return base.copyWith(
      displaySmall: sans(32, FontWeight.w700, tracking: -.8),
      headlineMedium: sans(26, FontWeight.w700, tracking: -.6),
      headlineSmall: sans(22, FontWeight.w700, tracking: -.4),
      titleLarge: sans(18, FontWeight.w700, tracking: -.2),
      titleMedium: sans(16, FontWeight.w600, tracking: -.1),
      titleSmall: sans(14.5, FontWeight.w600),
      bodyLarge: sans(15.5, FontWeight.w400),
      bodyMedium: sans(14.5, FontWeight.w400),
      bodySmall: sans(
        13,
        FontWeight.w400,
      ).copyWith(color: scheme.onSurfaceVariant, height: 1.4),
      labelLarge: sans(14, FontWeight.w600),
      labelMedium: sans(12.5, FontWeight.w600, tracking: .2),
      labelSmall: sans(11.5, FontWeight.w600, tracking: .4),
    );
  }

  static OutlineInputBorder _border(Color color, {double width = 1.2}) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(Radii.md),
        borderSide: BorderSide(color: color, width: width),
      );
}

/// Monospace styling for versions, hashes, durations and log lines.
extension MonoTextStyle on TextTheme {
  TextStyle get mono => TextStyle(
    fontFamily: AppTheme.monoFamily,
    fontSize: 13.5,
    fontWeight: FontWeight.w400,
    color: bodyMedium?.color,
    height: 1.4,
  );

  TextStyle get monoStrong => mono.copyWith(fontWeight: FontWeight.w600);
}

/// `context.isCompact` — true on phone-width layouts.
extension ResponsiveContext on BuildContext {
  bool get isCompact => MediaQuery.sizeOf(this).width < AppTheme.compactWidth;
}

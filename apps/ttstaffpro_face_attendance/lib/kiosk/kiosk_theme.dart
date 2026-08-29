import 'package:flutter/material.dart';

/// Bundled Poppins family (declared in pubspec) — matches the employee app
/// typography WITHOUT any runtime font fetch, so the kiosk never hangs on a
/// restricted network waiting for Google Fonts.
const String kKioskFontFamily = 'Poppins';

/// A complete palette for ONE theme (dark or light). Surfaces, text, borders,
/// page gradient and shadows switch between themes; brand + semantic colors
/// (see [KioskColors]) are shared so the TTStaffPro identity stays consistent.
class KioskPalette {
  const KioskPalette({
    required this.background,
    required this.backgroundAlt,
    required this.surface,
    required this.surfaceAlt,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.backgroundGradient,
    required this.cardShadow,
    required this.softGlow,
  });

  final Color background;
  final Color backgroundAlt;
  final Color surface;
  final Color surfaceAlt;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final LinearGradient backgroundGradient;
  final List<BoxShadow> cardShadow;
  final List<BoxShadow> softGlow;
}

/// Theme palettes + Material theme builder for the kiosk. Supports full
/// user-selectable dark / light / system mode.
class KioskTheme {
  KioskTheme._();

  /// Dark palette — deep navy surfaces (premium kiosk look, the default).
  static const KioskPalette dark = KioskPalette(
    background: Color(0xFF0D1020),
    backgroundAlt: Color(0xFF12162B),
    surface: Color(0xFF1A1F35),
    surfaceAlt: Color(0xFF222844),
    border: Color(0xFF2A3050),
    textPrimary: Color(0xFFF1F3FF),
    textSecondary: Color(0xFF9AA1BE),
    textMuted: Color(0xFF6B7293),
    backgroundGradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF131834), Color(0xFF0D1020)],
    ),
    cardShadow: [
      BoxShadow(
        color: Color(0x59000000),
        offset: Offset(0, 10),
        blurRadius: 28,
        spreadRadius: -8,
      ),
    ],
    softGlow: [
      BoxShadow(
        color: Color(0x59696CFF),
        offset: Offset(0, 0),
        blurRadius: 60,
      ),
    ],
  );

  /// Light palette — clean white/lavender surfaces, same indigo brand.
  static const KioskPalette light = KioskPalette(
    background: Color(0xFFF3F4FA),
    backgroundAlt: Color(0xFFE9EBF6),
    surface: Color(0xFFFFFFFF),
    surfaceAlt: Color(0xFFF7F8FE),
    border: Color(0xFFDDE1F0),
    textPrimary: Color(0xFF181C2E),
    textSecondary: Color(0xFF565E7E),
    textMuted: Color(0xFF8B91AC),
    backgroundGradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFFFDFDFF), Color(0xFFEEF0FA)],
    ),
    cardShadow: [
      BoxShadow(
        color: Color(0x1A1B2140),
        offset: Offset(0, 8),
        blurRadius: 24,
        spreadRadius: -6,
      ),
    ],
    softGlow: [
      BoxShadow(
        color: Color(0x40696CFF),
        offset: Offset(0, 0),
        blurRadius: 50,
      ),
    ],
  );

  /// The active palette for [context]'s current brightness.
  static KioskPalette of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? dark : light;

  /// Builds the full Material 3 [ThemeData] for the requested [brightness].
  static ThemeData themeFor(Brightness brightness) {
    final p = brightness == Brightness.dark ? dark : light;
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: p.background,
      primaryColor: KioskColors.primary,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: KioskColors.primary,
        onPrimary: Colors.white,
        secondary: KioskColors.primaryLight,
        onSecondary: Colors.white,
        surface: p.surface,
        onSurface: p.textPrimary,
        error: KioskColors.error,
        onError: Colors.white,
      ),
      fontFamily: kKioskFontFamily,
      appBarTheme: AppBarTheme(
        backgroundColor: p.background,
        elevation: 0,
        centerTitle: true,
        foregroundColor: p.textPrimary,
        iconTheme: IconThemeData(color: p.textPrimary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: KioskColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: KioskColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      cardTheme: CardThemeData(
        color: p.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
      ),
      dividerTheme: DividerThemeData(color: p.border),
    );
  }
}

/// Runtime theme-mode notifier. The root [MaterialApp] listens to this so the
/// whole UI rebuilds instantly when the user toggles light/dark/system.
final ValueNotifier<ThemeMode> kioskThemeMode =
    ValueNotifier<ThemeMode>(ThemeMode.system);

/// Brand + semantic colors shared by both themes. The TTStaffPro identity
/// (#696CFF indigo) stays consistent regardless of light/dark mode.
class KioskColors {
  KioskColors._();

  // Brand
  static const Color primary = Color(0xFF696CFF); // indigo
  static const Color primaryLight = Color(0xFF8B7EFF); // violet

  // Semantic
  static const Color success = Color(0xFF22D97A);
  static const Color successLight = Color(0xFF5FE39A);
  static const Color warning = Color(0xFFFB923C);
  static const Color error = Color(0xFFF87171);

  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryLight],
  );
}

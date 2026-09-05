import 'package:flutter/material.dart';

abstract final class EnergyCoreTheme {
  static const emerald = Color(0xFF22C55E);
  static const emeraldStrong = Color(0xFF15803D);
  static const amber = Color(0xFFF59E0B);
  static const charcoal = Color(0xFF0A0F0B);

  static ThemeData get dark => _build(
    brightness: Brightness.dark,
    background: charcoal,
    surface: const Color(0xFF121A14),
    onSurface: const Color(0xFFF4F7F5),
    outline: const Color(0xFF34463A),
  );

  static ThemeData get light => _build(
    brightness: Brightness.light,
    background: const Color(0xFFF3F6F2),
    surface: Colors.white,
    onSurface: const Color(0xFF17211A),
    outline: const Color(0xFFC8D5CB),
  );

  static ThemeData _build({
    required Brightness brightness,
    required Color background,
    required Color surface,
    required Color onSurface,
    required Color outline,
  }) {
    final scheme = ColorScheme(
      brightness: brightness,
      primary: brightness == Brightness.dark ? emerald : emeraldStrong,
      onPrimary: const Color(0xFF031208),
      secondary: amber,
      onSecondary: const Color(0xFF241400),
      error: brightness == Brightness.dark
          ? const Color(0xFFFFB4AB)
          : const Color(0xFFBA1A1A),
      onError: brightness == Brightness.dark
          ? const Color(0xFF690005)
          : Colors.white,
      surface: surface,
      onSurface: onSurface,
      outline: outline,
      surfaceContainerHighest: brightness == Brightness.dark
          ? const Color(0xFF1A261D)
          : const Color(0xFFE5EDE5),
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      fontFamily: 'Roboto',
      visualDensity: VisualDensity.standard,
    );

    return base.copyWith(
      textTheme: base.textTheme.copyWith(
        displaySmall: base.textTheme.displaySmall?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: -1.4,
        ),
        headlineMedium: base.textTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: -0.7,
        ),
        titleLarge: base.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
        ),
        labelLarge: base.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: Colors.transparent,
        foregroundColor: onSurface,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: surface,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: outline.withValues(alpha: 0.65)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 17,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        backgroundColor: surface,
        indicatorColor: scheme.primary.withValues(alpha: 0.18),
        labelTextStyle: WidgetStatePropertyAll(
          base.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: surface,
        indicatorColor: scheme.primary.withValues(alpha: 0.18),
        selectedIconTheme: IconThemeData(color: scheme.primary),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}

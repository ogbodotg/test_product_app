import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  AppTheme._();

  static const Color _amazonNavy = Color(0xFF131921);
  static const Color _amazonBlue = Color(0xFF232F3E);
  static const Color _amazonOrange = Color(0xFFFF9900);
  static const Color _amazonAmber = Color(0xFFF3A847);

  static ThemeData get light {
    final base = ColorScheme.fromSeed(
      seedColor: _amazonBlue,
      brightness: Brightness.light,
      surface: const Color(0xFFF7F8FA),
    );
    final scheme = base.copyWith(
      primary: _amazonBlue,
      onPrimary: Colors.white,
      secondary: _amazonOrange,
      onSecondary: const Color(0xFF1F1300),
      secondaryContainer: const Color(0xFFFFE0B2),
      onSecondaryContainer: const Color(0xFF2A1800),
      tertiary: _amazonAmber,
      surface: const Color(0xFFF7F8FA),
      surfaceContainer: Colors.white,
      surfaceContainerHigh: const Color(0xFFF1F3F6),
      outlineVariant: const Color(0xFFD8DFE8),
    );

    return _baseTheme(scheme);
  }

  static ThemeData get dark {
    final base = ColorScheme.fromSeed(
      seedColor: _amazonBlue,
      brightness: Brightness.dark,
      surface: const Color(0xFF0E131A),
    );
    final scheme = base.copyWith(
      primary: const Color(0xFF9FB3CC),
      onPrimary: const Color(0xFF0B1118),
      secondary: const Color(0xFFFFB84D),
      onSecondary: const Color(0xFF2B1B00),
      secondaryContainer: const Color(0xFF4C3200),
      onSecondaryContainer: const Color(0xFFFFDEA7),
      tertiary: const Color(0xFFFFC766),
      surface: const Color(0xFF0E131A),
      surfaceContainer: const Color(0xFF161C25),
      surfaceContainerHigh: const Color(0xFF202734),
      outlineVariant: const Color(0xFF323E4F),
    );

    return _baseTheme(scheme);
  }

  static ThemeData _baseTheme(ColorScheme scheme) {
    final textTheme = GoogleFonts.manropeTextTheme();
    final isLight = scheme.brightness == Brightness.light;

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: isLight ? _amazonNavy : const Color(0xFF0A1017),
        foregroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
      ),
      chipTheme: ChipThemeData(
        selectedColor: scheme.secondaryContainer,
        backgroundColor: scheme.surfaceContainer,
        disabledColor: scheme.surfaceContainerHighest,
        labelStyle: textTheme.labelLarge,
      ),
      cardTheme: CardThemeData(
        color: scheme.surface,
        elevation: isLight ? 0.6 : 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isLight ? Colors.white : scheme.surfaceContainer,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.primary, width: 1.5),
        ),
      ),
      dividerTheme: DividerThemeData(color: scheme.outlineVariant),
    );
  }
}

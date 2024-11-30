import 'package:flutter/material.dart';

class AppTheme {
  static const lightColors = AppColors(
    surface: Color(0xFFF7FAFC),
    surfaceContainer: Color(0xFFFFFFFF),
    primary: Color(0xFF6366F1),
    textPrimary: Color(0xFF2D3748),
    textSecondary: Color(0xFF4A5568),
    divider: Color(0xFFE2E8F0),
  );

  static const darkColors = AppColors(
    surface: Color(0xFF1A202C),
    surfaceContainer: Color(0xFF2D3748),
    primary: Color(0xFF818CF8),
    textPrimary: Color(0xFFF7FAFC),
    textSecondary: Color(0xFFE2E8F0),
    divider: Color(0xFF4A5568),
  );

  static ThemeData light() {
    return _buildTheme(lightColors);
  }

  static ThemeData dark() {
    return _buildTheme(darkColors);
  }

  static ThemeData _buildTheme(AppColors colors) {
    const borderRadius = 12.0;
    const contentPadding = EdgeInsets.symmetric(horizontal: 16, vertical: 12);
    const buttonPadding = EdgeInsets.symmetric(horizontal: 24, vertical: 12);

    return ThemeData(
      useMaterial3: true,
      brightness: colors == lightColors ? Brightness.light : Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: colors.primary,
        surface: colors.surface,
        surfaceContainer: colors.surfaceContainer,
        primary: colors.primary,
      ),
      scaffoldBackgroundColor: colors.surface,
      cardTheme: CardTheme(
        color: colors.surfaceContainer,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
      textTheme: TextTheme(
        headlineLarge: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: colors.textPrimary,
        ),
        headlineMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: colors.textPrimary,
        ),
        headlineSmall: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: colors.textPrimary,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: colors.textPrimary,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: colors.textPrimary,
        ),
        labelMedium: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: colors.textSecondary,
        ),
      ),
      dividerTheme: DividerThemeData(
        color: colors.divider,
        thickness: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surfaceContainer,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: BorderSide(color: colors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: BorderSide(color: colors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: BorderSide(color: colors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: const BorderSide(color: Colors.red),
        ),
        contentPadding: contentPadding,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.primary,
          foregroundColor: colors.surfaceContainer,
          padding: buttonPadding,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
        ),
      ),
    );
  }
}

@immutable
class AppColors {
  final Color surface;
  final Color surfaceContainer;
  final Color primary;
  final Color textPrimary;
  final Color textSecondary;
  final Color divider;

  const AppColors({
    required this.surface,
    required this.surfaceContainer,
    required this.primary,
    required this.textPrimary,
    required this.textSecondary,
    required this.divider,
  });
}

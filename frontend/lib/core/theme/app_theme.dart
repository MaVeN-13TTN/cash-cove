import 'package:flutter/material.dart';

class AppTheme {
  static const lightColors = AppColors(
    surface: Color(0xFFF7FAFC),
    surfaceContainer: Color(0xFFFFFFFF),
    primary: Color(0xFF6366F1),
    textPrimary: Color(0xFF2D3748),
    textSecondary: Color(0xFF4A5568),
    divider: Color(0xFFE2E8F0),
    error: Color(0xFFDC2626),
    success: Color(0xFF059669),
    warning: Color(0xFFF59E0B),
    info: Color(0xFF3B82F6),
  );

  static const darkColors = AppColors(
    surface: Color(0xFF1A202C),
    surfaceContainer: Color(0xFF2D3748),
    primary: Color(0xFF818CF8),
    textPrimary: Color(0xFFF7FAFC),
    textSecondary: Color(0xFFE2E8F0),
    divider: Color(0xFF4A5568),
    error: Color(0xFFFCA5A5),
    success: Color(0xFF34D399),
    warning: Color(0xFFFBD38D),
    info: Color(0xFF93C5FD),
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
        error: colors.error,
        brightness: colors == lightColors ? Brightness.light : Brightness.dark,
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
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
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
        contentPadding: contentPadding,
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
          borderSide: BorderSide(color: colors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: BorderSide(color: colors.error, width: 2),
        ),
        labelStyle: TextStyle(color: colors.textSecondary),
        hintStyle: TextStyle(color: colors.textSecondary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: buttonPadding,
          backgroundColor: colors.primary,
          foregroundColor: colors.surfaceContainer,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          elevation: 0,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          padding: buttonPadding,
          foregroundColor: colors.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: colors.surfaceContainer,
        selectedItemColor: colors.primary,
        unselectedItemColor: colors.textSecondary,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colors.surfaceContainer,
        shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(borderRadius)),
        ),
      ),
      dialogTheme: DialogTheme(
        backgroundColor: colors.surfaceContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
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
  final Color error;
  final Color success;
  final Color warning;
  final Color info;

  const AppColors({
    required this.surface,
    required this.surfaceContainer,
    required this.primary,
    required this.textPrimary,
    required this.textSecondary,
    required this.divider,
    required this.error,
    required this.success,
    required this.warning,
    required this.info,
  });
}
